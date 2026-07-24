const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const { consultarHistorial } = require("./attendanceHistoryService")

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

exports.handler = async (event) => {
  const dni = event.pathParameters ? event.pathParameters.dni : undefined

  const resultado = await consultarHistorial(dni, db)

  if (resultado.error) {
    return responder(400, { message: resultado.error })
  }

  return responder(200, resultado.historial)
}
