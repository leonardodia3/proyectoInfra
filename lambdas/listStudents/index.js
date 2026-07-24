const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const { listarAlumnos } = require("./listStudentsService")

const responseHeaders = {
  "Access-Control-Allow-Origin": process.env.CORS_ALLOWED_ORIGIN || "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Api-Key",
  "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS"
}

exports.handler = async () => {
  const resultado = await listarAlumnos(db)

  return {
    statusCode: 200,
    headers: responseHeaders,
    body: JSON.stringify(resultado.alumnos)
  }
}
