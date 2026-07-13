const AWS = require("aws-sdk")
const db = new AWS.DynamoDB.DocumentClient()
const { listarAlumnos } = require("./listStudentsService")

exports.handler = async () => {
  const resultado = await listarAlumnos(db)

  return {
    statusCode: 200,
    body: JSON.stringify(resultado.alumnos)
  }
}