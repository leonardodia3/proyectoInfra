const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const sns = new AWS.SNS()
const { registrarAlumno, eliminarAlumno } = require("./studentService")
const { notificarAlumno } = require("./notificationService")

exports.handler = async (event) => {
  if (event.httpMethod === "DELETE") {
    const dni = event.pathParameters ? event.pathParameters.dni : undefined
    const resultado = await eliminarAlumno(dni, db)

    if (resultado.error) {
      return { statusCode: 400, body: JSON.stringify({ message: resultado.error }) }
    }
    return { statusCode: 200, body: JSON.stringify({ message: "Alumno eliminado" }) }
  }

  const body = JSON.parse(event.body)
  const resultado = await registrarAlumno(body, db)

  if (resultado.error) {
    return { statusCode: 400, body: JSON.stringify({ message: resultado.error }) }
  }

  await notificarAlumno(body, sns)
  return { statusCode: 200, body: JSON.stringify({ message: "Alumno registrado" }) }
}