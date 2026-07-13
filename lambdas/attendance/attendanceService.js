async function registrarAsistencia(body, db) {
  if (!body.dni) {
    return { error: "DNI es obligatorio" }
  }

  const alumno = await db.get({
    TableName: "attendance",
    Key: {
      pk: `STUDENT#${body.dni}`,
      sk: "PROFILE"
    }
  }).promise()

  if (!alumno.Item) {
    return { error: "El alumno no está registrado" }
  }

  await db.put({
    TableName: "attendance",
    Item: {
      pk: `STUDENT#${body.dni}`,
      sk: `ATTENDANCE#${Date.now()}`,
      timestamp: new Date().toISOString(),
      method: "RFID"
    }
  }).promise()

  return { success: true }
}

module.exports = { registrarAsistencia }