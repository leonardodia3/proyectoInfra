const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const { registrarAsistenciaManual } = require("./manualAttendanceService")

exports.handler = async (event) => {
  const body = JSON.parse(event.body)

  const resultado = await registrarAsistenciaManual(body, db)

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