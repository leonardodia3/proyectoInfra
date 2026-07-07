function esDniValido(dni) {
  return dni.length === 8
}

function esCorreoValido(email) {
  return email.includes("@")
}

async function registrarAlumno(body, db) {
  if (!body.dni) {
    return { error: "DNI es obligatorio" }
  }

  if (!esDniValido(body.dni)) {
    return { error: "DNI no es válido" }
  }

  if (!body.email) {
    return { error: "El correo es obligatorio" }
  }

  if (!esCorreoValido(body.email)) {
    return { error: "El correo no es válido" }
  }

  const existente = await db.get({
    TableName: "attendance",
    Key: {
      pk: `STUDENT#${body.dni}`,
      sk: "PROFILE"
    }
  }).promise()

  if (existente.Item) {
    return { error: "El DNI ya está registrado" }
  }

  await db.put({
    TableName: "attendance",
    Item: {
      pk: `STUDENT#${body.dni}`,
      sk: "PROFILE",
      name: body.name,
      email: body.email,
      classroom: body.classroom
    }
  }).promise()

  return { success: true }
}

module.exports = { registrarAlumno }