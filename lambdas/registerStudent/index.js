const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const sns = new AWS.SNS()
const { registrarAlumno } = require("./studentService")
const { notificarAlumno } = require("./notificationService")

exports.handler = async (event) => {
  const body = JSON.parse(event.body)

  const resultado = await registrarAlumno(body, db)

  if (resultado.error) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: resultado.error })
    }
  }

  await notificarAlumno(body, sns)

  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Alumno registrado" })
  }
}