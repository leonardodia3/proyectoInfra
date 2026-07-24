function esDniValido(dni) {
  return dni.length === 8
}

function esDniSoloNumeros(dni) {
  return /^\d+$/.test(dni)
}

function esCorreoValido(email) {
  return /^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$/.test(email)
}

function normalizarTexto(valor) {
  return typeof valor === "string" ? valor.trim() : valor
}

function valorPreferido(...valores) {
  for (const valor of valores) {
    const normalizado = normalizarTexto(valor)
    if (normalizado) {
      return normalizado
    }
  }

  return ""
}

function normalizarAlumno(body) {
  const dni = valorPreferido(body.dni)

  return {
    dni,
    email: valorPreferido(body.email, body.correo),
    name: valorPreferido(body.name, body.nombre),
    classroom: valorPreferido(body.classroom, body.seccion, body.salon),
    rfid: valorPreferido(body.rfid)
  }
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

    return resultado.Items ? resultado.Items[0] : undefined
  }

  const resultado = await db.scan({
    TableName: tableName,
    FilterExpression: "sk = :profile AND rfid = :rfid",
    ExpressionAttributeValues: {
      ":profile": "PROFILE",
      ":rfid": rfid
    }
  }).promise()

  return resultado.Items ? resultado.Items[0] : undefined
}

async function registrarAlumno(body, db, options = {}) {
  const tableName = options.tableName || process.env.TABLE_NAME || "attendance"
  const alumno = normalizarAlumno(body)

  if (!alumno.dni) {
    return { error: "DNI es obligatorio" }
  }

  if (!esDniValido(alumno.dni)) {
    return { error: "DNI no es válido" }
  }

  if (!esDniSoloNumeros(alumno.dni)) {
    return { error: "El DNI debe contener solo números" }
  }

  if (!alumno.email) {
    return { error: "El correo es obligatorio" }
  }

  if (!esCorreoValido(alumno.email)) {
    return { error: "El correo no es válido" }
  }

  if (!alumno.name) {
    return { error: "El nombre es obligatorio" }
  }

  if (!alumno.classroom) {
    return { error: "El salón es obligatorio" }
  }

  if (!alumno.rfid) {
    return { error: "RFID es obligatorio" }
  }

  const existente = await db.get({
    TableName: tableName,
    Key: {
      pk: `STUDENT#${alumno.dni}`,
      sk: "PROFILE"
    }
  }).promise()

  if (existente.Item) {
    return { error: "El DNI ya está registrado" }
  }

  const rfidExistente = await buscarAlumnoPorRfid(alumno.rfid, db, tableName, options)
  if (rfidExistente && extraerDniDesdePerfil(rfidExistente) !== alumno.dni) {
    return { error: "El RFID ya está registrado" }
  }

  await db.put({
    TableName: tableName,
    Item: {
      pk: `STUDENT#${alumno.dni}`,
      sk: "PROFILE",
      name: alumno.name,
      email: alumno.email,
      classroom: alumno.classroom,
      rfid: alumno.rfid
    }
  }).promise()

  return { success: true, alumno }
}

async function eliminarAlumno(dni, db, options = {}) {
  const tableName = options.tableName || process.env.TABLE_NAME || "attendance"

  if (!dni) {
    return { error: "DNI es obligatorio" }
  }

  const alumno = await db.get({
    TableName: tableName,
    Key: { pk: `STUDENT#${dni}`, sk: "PROFILE" }
  }).promise()

  if (!alumno.Item) {
    return { error: "El alumno no existe" }
  }

  await db.delete({
    TableName: tableName,
    Key: { pk: `STUDENT#${dni}`, sk: "PROFILE" }
  }).promise()

  return { success: true }
}

module.exports = { registrarAlumno, eliminarAlumno }
