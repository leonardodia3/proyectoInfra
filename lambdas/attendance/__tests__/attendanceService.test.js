const { registrarAsistencia } = require("../attendanceService")

test("rechaza asistencia sin DNI", async () => {
  const resultado = await registrarAsistencia({ dni: "" }, {})
  expect(resultado.error).toBe("DNI es obligatorio")
})

test("rechaza asistencia de un alumno no registrado", async () => {
  const dbFalso = {
    get: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Item: undefined })
    })
  }

  const resultado = await registrarAsistencia({ dni: "12345678" }, dbFalso)
  expect(resultado.error).toBe("El alumno no está registrado")
})

test("registra asistencia correctamente cuando el alumno existe", async () => {
  const dbFalso = {
    get: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Item: { pk: "STUDENT#12345678", sk: "PROFILE" } })
    }),
    put: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }

  const resultado = await registrarAsistencia({ dni: "12345678" }, dbFalso)
  expect(resultado.success).toBe(true)
})