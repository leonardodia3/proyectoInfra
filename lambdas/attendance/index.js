const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const sqs = new AWS.SQS()
const { registrarAsistencia } = require("./attendanceService")

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
  const entrada = parsearBody(event)
  if (entrada.error) {
    return responder(400, { message: entrada.error })
  }

  const resultado = await registrarAsistencia(entrada.body, db, sqs)

  if (resultado.error) {
    return responder(400, { message: resultado.error })
  }

  return responder(200, {
    message: resultado.tardanza
      ? "Asistencia registrada con tardanza"
      : "Asistencia registrada",
    tardanza: resultado.tardanza
  })
}
