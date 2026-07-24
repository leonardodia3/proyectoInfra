function extraerDniDesdePk(pk) {
  if (typeof pk !== "string" || !pk.startsWith("STUDENT#")) {
    return ""
  }

  return pk.replace("STUDENT#", "")
}

function normalizarAlumno(alumno) {
  return {
    dni: alumno.dni || extraerDniDesdePk(alumno.pk),
    rfid: alumno.rfid || "",
    name: alumno.name || "",
    email: alumno.email || "",
    classroom: alumno.classroom || ""
  }
}

async function listarAlumnos(db, options = {}) {
  const tableName = options.tableName || process.env.TABLE_NAME || "attendance"

  const data = await db.scan({
    TableName: tableName,
    FilterExpression: "sk = :sk",
    ExpressionAttributeValues: {
      ":sk": "PROFILE"
    }
  }).promise()

  return { alumnos: (data.Items || []).map(normalizarAlumno) }
}

module.exports = { listarAlumnos, normalizarAlumno }
