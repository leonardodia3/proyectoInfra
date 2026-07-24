const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const sns = new AWS.SNS()
const { registrarAlumno, eliminarAlumno } = require("./studentService")
const { notificarAlumno } = require("./notificationService")

const responseHeaders = {
  "Access-Control-Allow-Origin": process.env.CORS_ALLOWED_ORIGIN || "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Api-Key",
  "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS"
}

function responder(statusCode, payload) {
  return {
    statusCode,
    headers: responseHeaders,
    body: JSON.stringify(payload)
  }
}

function parsearBody(event) {
  try {
    return { body: event.body ? JSON.parse(event.body) : {} }
  } catch (error) {
    return { error: "JSON inválido" }
  }
}

exports.handler = async (event) => {
  if (event.httpMethod === "DELETE") {
    const dni = event.pathParameters ? event.pathParameters.dni : undefined
    const resultado = await eliminarAlumno(dni, db)

    if (resultado.error) {
      return responder(400, { message: resultado.error })
    }
    return responder(200, { message: "Alumno eliminado" })
  }

  const entrada = parsearBody(event)
  if (entrada.error) {
    return responder(400, { message: entrada.error })
  }

  const body = entrada.body
  const resultado = await registrarAlumno(body, db)

  if (resultado.error) {
    return responder(400, { message: resultado.error })
  }

  await notificarAlumno(resultado.alumno, sns)
  return responder(200, { message: "Alumno registrado" })
}
