function esDniValido(dni) {
  return dni.length === 8
}

function esDniSoloNumeros(dni) {
  return /^\d+$/.test(dni)
}

function esCorreoValido(email) {
  return /^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$/.test(email)
}

async function registrarAlumno(body, db) {
  if (!body.dni) {
    return { error: "DNI es obligatorio" }
  }

  if (!esDniValido(body.dni)) {
    return { error: "DNI no es válido" }
  }

  if (!esDniSoloNumeros(body.dni)) {
    return { error: "El DNI debe contener solo números" }
  }

  if (!body.email) {
    return { error: "El correo es obligatorio" }
  }

  if (!esCorreoValido(body.email)) {
    return { error: "El correo no es válido" }
  }

  if (!body.name) {
    return { error: "El nombre es obligatorio" }
  }

  if (!body.classroom) {
    return { error: "El salón es obligatorio" }
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

async function eliminarAlumno(dni, db) {
  if (!dni) {
    return { error: "DNI es obligatorio" }
  }

  const alumno = await db.get({
    TableName: "attendance",
    Key: { pk: `STUDENT#${dni}`, sk: "PROFILE" }
  }).promise()

  if (!alumno.Item) {
    return { error: "El alumno no existe" }
  }

  await db.delete({
    TableName: "attendance",
    Key: { pk: `STUDENT#${dni}`, sk: "PROFILE" }
  }).promise()

  return { success: true }
}

module.exports = { registrarAlumno, eliminarAlumno }