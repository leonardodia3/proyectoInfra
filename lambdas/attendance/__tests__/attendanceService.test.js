const { registrarAsistencia } = require("../attendanceService")

test("rechaza asistencia RFID sin RFID", async () => {
  const resultado = await registrarAsistencia({ dni: "" }, {})
  expect(resultado.error).toBe("RFID es obligatorio")
})

test("rechaza DNI en el endpoint RFID aunque el alumno exista", async () => {
  const dbFalso = {
    get: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Item: { pk: "STUDENT#12345678", sk: "PROFILE" } })
    })
  }

  const resultado = await registrarAsistencia({ dni: "12345678" }, dbFalso)
  expect(resultado.error).toBe("RFID es obligatorio")
  expect(dbFalso.get).not.toHaveBeenCalled()
})

test("rechaza asistencia RFID de un alumno no registrado", async () => {
  const dbFalso = {
    scan: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Items: [] })
    })
  }

  const resultado = await registrarAsistencia({ rfid: "RFID_NO_EXISTE" }, dbFalso)
  expect(resultado.error).toBe("El alumno no está registrado")
  expect(dbFalso.scan).toHaveBeenCalled()
})

test("registra asistencia por RFID resolviendo el DNI del perfil", async () => {
  const dbFalso = {
    scan: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({
        Items: [{ pk: "STUDENT#12345678", sk: "PROFILE", name: "Juan", rfid: "RFID12345678" }]
      })
    }),
    put: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }

  const resultado = await registrarAsistencia({ rfid: "RFID12345678" }, dbFalso)

  expect(resultado.success).toBe(true)
  expect(dbFalso.put).toHaveBeenCalledWith(expect.objectContaining({
    Item: expect.objectContaining({
      pk: "STUDENT#12345678",
      method: "RFID"
    })
  }))
})

test("registra asistencia por RFID usando el indice configurado", async () => {
  const dbFalso = {
    query: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({
        Items: [{ pk: "STUDENT#12345678", sk: "PROFILE", name: "Juan", rfid: "RFID12345678" }]
      })
    }),
    put: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }

  const resultado = await registrarAsistencia(
    { rfid: "RFID12345678" },
    dbFalso,
    undefined,
    { rfidIndexName: "rfid-index" }
  )

  expect(resultado.success).toBe(true)
  expect(dbFalso.query).toHaveBeenCalledWith(expect.objectContaining({
    IndexName: "rfid-index",
    KeyConditionExpression: "rfid = :rfid"
  }))
  expect(dbFalso.put).toHaveBeenCalledWith(expect.objectContaining({
    Item: expect.objectContaining({ pk: "STUDENT#12345678" })
  }))
})

test("encola alerta cuando una asistencia RFID llega tarde", async () => {
  const dbFalso = {
    scan: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({
        Items: [{
          pk: "STUDENT#12345678",
          sk: "PROFILE",
          name: "Juan Perez",
          email: "juan@correo.com",
          rfid: "RFID12345678"
        }]
      })
    }),
    put: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }
  const sqsFalso = {
    sendMessage: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }

  const resultado = await registrarAsistencia(
    { rfid: "RFID12345678", timestamp: "2026-07-22T14:30:00.000Z" },
    dbFalso,
    sqsFalso,
    {
      deadline: "08:00",
      queueUrl: "local-tardanza-queue",
      timeZone: "America/Lima"
    }
  )

  expect(resultado.success).toBe(true)
  expect(resultado.tardanza).toBe(true)
  expect(sqsFalso.sendMessage).toHaveBeenCalledWith(expect.objectContaining({
    QueueUrl: "local-tardanza-queue"
  }))

  const mensaje = JSON.parse(sqsFalso.sendMessage.mock.calls[0][0].MessageBody)
  expect(mensaje).toMatchObject({
    dni: "12345678",
    name: "Juan Perez",
    email: "juan@correo.com",
    method: "RFID"
  })
})
