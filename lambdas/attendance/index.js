const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const { registrarAsistencia } = require("./attendanceService")

exports.handler = async (event) => {
  const body = JSON.parse(event.body)

  const resultado = await registrarAsistencia(body, db)

  if (resultado.error) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: resultado.error })
    }
  }

  return {
    statusCode: 200,
    body: "ok"
  }
}