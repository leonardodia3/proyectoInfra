const DEFAULT_DEADLINE = "08:00"
const DEFAULT_TIME_ZONE = "America/Lima"

function obtenerFechaLectura(body) {
  if (!body.timestamp) {
    return new Date()
  }

  const fecha = new Date(body.timestamp)
  if (Number.isNaN(fecha.getTime())) {
    return undefined
  }

  return fecha
}

function minutosDesdeMedianoche(fecha, timeZone) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
    hour12: false
  }).formatToParts(fecha)

  const hour = Number(parts.find((part) => part.type === "hour").value)
  const minute = Number(parts.find((part) => part.type === "minute").value)

  return hour * 60 + minute
}

function minutosLimite(deadline) {
  const match = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(deadline)
  if (!match) {
    return undefined
  }

  return Number(match[1]) * 60 + Number(match[2])
}

function esTardanza(fecha, deadline, timeZone) {
  const limite = minutosLimite(deadline)
  if (limite === undefined) {
    return false
  }

  return minutosDesdeMedianoche(fecha, timeZone) > limite
}

function extraerDniDesdePerfil(alumno) {
  if (!alumno || !alumno.pk || !alumno.pk.startsWith("STUDENT#")) {
    return undefined
  }

  return alumno.pk.replace("STUDENT#", "")
}

async function buscarAlumnoPorRfid(rfid, db, tableName, options) {
  const rfidIndexName = options.rfidIndexName || process.env.RFID_INDEX_NAME

  if (rfidIndexName) {
    const resultado = await db.query({
      TableName: tableName,
      IndexName: rfidIndexName,
      KeyConditionExpression: "rfid = :rfid",
      FilterExpression: "sk = :profile",
      ExpressionAttributeValues: {
        ":rfid": rfid,
        ":profile": "PROFILE"
      },
      Limit: 1
    }).promise()
    const alumno = resultado.Items ? resultado.Items[0] : undefined

    return { alumno, dni: extraerDniDesdePerfil(alumno) }
  }

  const resultado = await db.scan({
    TableName: tableName,
    FilterExpression: "sk = :profile AND rfid = :rfid",
    ExpressionAttributeValues: {
      ":profile": "PROFILE",
      ":rfid": rfid
    }
  }).promise()
  const alumno = resultado.Items ? resultado.Items[0] : undefined

  return { alumno, dni: extraerDniDesdePerfil(alumno) }
}

async function buscarAlumno(body, db, tableName, options) {
  if (!body.rfid) {
    return { error: "RFID es obligatorio" }
  }

  return buscarAlumnoPorRfid(body.rfid, db, tableName, options)
}

async function publicarAlertaTardanza(dni, alumno, fecha, sqs, options) {
  const queueUrl = options.queueUrl || process.env.TARDANZA_QUEUE_URL
  if (!sqs || !queueUrl) {
    return
  }

  await sqs.sendMessage({
    QueueUrl: queueUrl,
    MessageBody: JSON.stringify({
      dni,
      name: alumno.name,
      email: alumno.email,
      classroom: alumno.classroom,
      method: "RFID",
      timestamp: fecha.toISOString()
    })
  }).promise()
}

async function registrarAsistencia(body, db, sqs, options = {}) {
  const tableName = options.tableName || process.env.TABLE_NAME || "attendance"

  const fecha = obtenerFechaLectura(body)
  if (!fecha) {
    return { error: "La fecha de lectura no es válida" }
  }

  const busqueda = await buscarAlumno(body, db, tableName, options)
  if (busqueda.error) {
    return { error: busqueda.error }
  }

  if (!busqueda.alumno || !busqueda.dni) {
    return { error: "El alumno no está registrado" }
  }

  const deadline = options.deadline || process.env.ATTENDANCE_DEADLINE || DEFAULT_DEADLINE
  const timeZone = options.timeZone || process.env.ATTENDANCE_TIME_ZONE || DEFAULT_TIME_ZONE
  const tardanza = esTardanza(fecha, deadline, timeZone)

  await db.put({
    TableName: tableName,
    Item: {
      pk: `STUDENT#${busqueda.dni}`,
      sk: `ATTENDANCE#${fecha.getTime()}`,
      timestamp: fecha.toISOString(),
      method: "RFID",
      status: tardanza ? "TARDE" : "ASISTIO"
    }
  }).promise()

  if (tardanza) {
    await publicarAlertaTardanza(busqueda.dni, busqueda.alumno, fecha, sqs, options)
  }

  return { success: true, tardanza }
}

module.exports = { registrarAsistencia, esTardanza }
