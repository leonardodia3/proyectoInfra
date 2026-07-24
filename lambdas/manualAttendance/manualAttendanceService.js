async function registrarAsistenciaManual(body, db, options = {}) {
  const tableName = options.tableName || process.env.TABLE_NAME || "attendance"

  if (!body.dni) {
    return { error: "DNI es obligatorio" }
  }

  const alumno = await db.get({
    TableName: tableName,
    Key: {
      pk: `STUDENT#${body.dni}`,
      sk: "PROFILE"
    }
  }).promise()

  if (!alumno.Item) {
    return { error: "El alumno no está registrado" }
  }

  await db.put({
    TableName: tableName,
    Item: {
      pk: `STUDENT#${body.dni}`,
      sk: `ATTENDANCE#${Date.now()}`,
      timestamp: new Date().toISOString(),
      method: "MANUAL"
    }
  }).promise()

  return { success: true }
}

module.exports = { registrarAsistenciaManual }
