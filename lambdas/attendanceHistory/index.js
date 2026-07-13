const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const { consultarHistorial } = require("./attendanceHistoryService")

exports.handler = async (event) => {
  const dni = event.pathParameters ? event.pathParameters.id : undefined

  const resultado = await consultarHistorial(dni, db)

  if (resultado.error) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: resultado.error })
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify(resultado.historial)
  }
}