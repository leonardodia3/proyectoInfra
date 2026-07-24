const test = require("node:test")
const assert = require("node:assert/strict")

const { registrarAlumno } = require("../../local-deploy/backend/services/studentService")
const { registrarAsistencia } = require("../../local-deploy/backend/services/attendanceService")
const { registrarAsistenciaManual } = require("../../local-deploy/backend/services/manualAttendanceService")
const { consultarHistorial } = require("../../local-deploy/backend/services/attendanceHistoryService")
const { listarAlumnos } = require("../../local-deploy/backend/services/listStudentsService")
const { procesarAlertaTardanza } = require("../../local-deploy/backend/services/notifyAlertService")

class DynamoEnMemoria {
  constructor() {
    this.items = new Map()
  }

  key(pk, sk) {
    return `${pk}|${sk}`
  }

  get(params) {
    return {
      promise: async () => ({
        Item: this.items.get(this.key(params.Key.pk, params.Key.sk))
      })
    }
  }

  put(params) {
    return {
      promise: async () => {
        this.items.set(this.key(params.Item.pk, params.Item.sk), { ...params.Item })
        return {}
      }
    }
  }

  delete(params) {
    return {
      promise: async () => {
        this.items.delete(this.key(params.Key.pk, params.Key.sk))
        return {}
      }
    }
  }

  scan(params) {
    return {
      promise: async () => {
        const items = Array.from(this.items.values())

        if (params.FilterExpression === "sk = :sk") {
          return { Items: items.filter((item) => item.sk === params.ExpressionAttributeValues[":sk"]) }
        }

        if (params.FilterExpression === "sk = :profile AND rfid = :rfid") {
          return {
            Items: items.filter((item) =>
              item.sk === params.ExpressionAttributeValues[":profile"] &&
              item.rfid === params.ExpressionAttributeValues[":rfid"]
            )
          }
        }

        return { Items: items }
      }
    }
  }

  query(params) {
    return {
      promise: async () => {
        const items = Array.from(this.items.values())

        if (params.IndexName) {
          const rfid = params.ExpressionAttributeValues[":rfid"]
          const profile = params.ExpressionAttributeValues[":profile"]
          return { Items: items.filter((item) => item.rfid === rfid && item.sk === profile).slice(0, params.Limit) }
        }

        const pk = params.ExpressionAttributeValues[":pk"]
        const skPrefix = params.ExpressionAttributeValues[":sk"]
        return { Items: items.filter((item) => item.pk === pk && item.sk.startsWith(skPrefix)) }
      }
    }
  }
}

class SnsEnMemoria {
  constructor() {
    this.messages = []
  }

  publish(params) {
    return {
      promise: async () => {
        this.messages.push(params)
        return {}
      }
    }
  }
}

class SqsConNotificador {
  constructor(sns) {
    this.sns = sns
    this.messages = []
  }

  sendMessage(params) {
    return {
      promise: async () => {
        this.messages.push(params)
        const resultado = await procesarAlertaTardanza({ body: params.MessageBody }, this.sns)

        if (resultado.error) {
          throw new Error(resultado.error)
        }

        return {}
      }
    }
  }
}

test("flujo completo: registro, RFID tardio, alerta, historial y asistencia manual", async () => {
  const db = new DynamoEnMemoria()
  const sns = new SnsEnMemoria()
  const sqs = new SqsConNotificador(sns)

  const alumno = await registrarAlumno(
    {
      dni: "12345678",
      nombre: "Alumno Integracion",
      correo: "familia@example.com",
      seccion: "5to C",
      rfid: "RFID12345678"
    },
    db,
    { tableName: "attendance" }
  )

  assert.equal(alumno.success, true)

  const duplicado = await registrarAlumno(
    {
      dni: "87654321",
      nombre: "Alumno Duplicado",
      correo: "duplicado@example.com",
      seccion: "5to C",
      rfid: "RFID12345678"
    },
    db,
    { tableName: "attendance" }
  )

  assert.equal(duplicado.error, "El RFID ya está registrado")

  const asistenciaRfid = await registrarAsistencia(
    { rfid: "RFID12345678", timestamp: "2026-07-22T14:30:00.000Z" },
    db,
    sqs,
    {
      deadline: "08:00",
      queueUrl: "local-tardanza-queue",
      tableName: "attendance",
      timeZone: "America/Lima"
    }
  )

  assert.equal(asistenciaRfid.success, true)
  assert.equal(asistenciaRfid.tardanza, true)
  assert.equal(sqs.messages.length, 1)
  assert.match(sns.messages[0].Message, /Alerta de tardanza/)

  const asistenciaManual = await registrarAsistenciaManual({ dni: "12345678" }, db, { tableName: "attendance" })
  assert.equal(asistenciaManual.success, true)

  const historial = await consultarHistorial("12345678", db, { tableName: "attendance" })
  assert.equal(historial.historial.length, 2)
  assert.ok(historial.historial.some((item) => item.method === "RFID" && item.status === "TARDE"))
  assert.ok(historial.historial.some((item) => item.method === "MANUAL"))

  const alumnos = await listarAlumnos(db, { tableName: "attendance" })
  assert.equal(alumnos.alumnos.length, 1)
  assert.equal(alumnos.alumnos[0].rfid, "RFID12345678")
})

test("flujo RFID desconocido no registra asistencia ni alerta", async () => {
  const db = new DynamoEnMemoria()
  const sns = new SnsEnMemoria()
  const sqs = new SqsConNotificador(sns)

  const resultado = await registrarAsistencia({ rfid: "RFID_NO_EXISTE" }, db, sqs, { tableName: "attendance" })

  assert.equal(resultado.error, "El alumno no está registrado")
  assert.equal(sqs.messages.length, 0)
  assert.equal(sns.messages.length, 0)
})

test("flujo RFID rechaza DNI y reserva asistencia manual para su endpoint", async () => {
  const db = new DynamoEnMemoria()
  const sns = new SnsEnMemoria()
  const sqs = new SqsConNotificador(sns)

  await registrarAlumno(
    {
      dni: "12345678",
      nombre: "Alumno Manual",
      correo: "manual@example.com",
      seccion: "5to C",
      rfid: "RFID_MANUAL"
    },
    db,
    { tableName: "attendance" }
  )

  const asistenciaRfid = await registrarAsistencia({ dni: "12345678" }, db, sqs, { tableName: "attendance" })
  assert.equal(asistenciaRfid.error, "RFID es obligatorio")

  const asistenciaManual = await registrarAsistenciaManual({ dni: "12345678" }, db, { tableName: "attendance" })
  assert.equal(asistenciaManual.success, true)

  const historial = await consultarHistorial("12345678", db, { tableName: "attendance" })
  assert.equal(historial.historial.length, 1)
  assert.equal(historial.historial[0].method, "MANUAL")
  assert.equal(sqs.messages.length, 0)
  assert.equal(sns.messages.length, 0)
})
