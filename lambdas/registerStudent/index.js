const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const { registrarAlumno } = require("./studentService")

exports.handler = async (event) => {
  const body = JSON.parse(event.body)

  const resultado = await registrarAlumno(body, db)

  if (resultado.error) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: resultado.error })
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Alumno registrado" })
  }
}
