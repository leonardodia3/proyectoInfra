const AWS = require("aws-sdk")

const dynamodb = new AWS.DynamoDB({
  region: "us-east-1",
  endpoint: process.env.DYNAMODB_ENDPOINT || "http://localhost:8000",
  accessKeyId: "local",
  secretAccessKey: "local"
})

const docClient = new AWS.DynamoDB.DocumentClient({
  region: "us-east-1",
  endpoint: process.env.DYNAMODB_ENDPOINT || "http://localhost:8000",
  accessKeyId: "local",
  secretAccessKey: "local"
})

async function crearTabla() {
  const tablas = await dynamodb.listTables().promise()

  if (tablas.TableNames.includes("attendance")) {
    console.log("La tabla 'attendance' ya existe, se omite la creación.")
    return
  }

  await dynamodb.createTable({
    TableName: "attendance",
    AttributeDefinitions: [
      { AttributeName: "pk", AttributeType: "S" },
      { AttributeName: "sk", AttributeType: "S" }
    ],
    KeySchema: [
      { AttributeName: "pk", KeyType: "HASH" },
      { AttributeName: "sk", KeyType: "RANGE" }
    ],
    BillingMode: "PAY_PER_REQUEST"
  }).promise()

  console.log("Tabla 'attendance' creada.")
}

async function cargarDatosDePrueba() {
  const alumnos = [
    { pk: "STUDENT#12345678", sk: "PROFILE", name: "Juan Pérez", email: "juan@correo.com", classroom: "5to C" },
    { pk: "STUDENT#87654321", sk: "PROFILE", name: "Ana Torres", email: "ana@correo.com", classroom: "4to B" },
    { pk: "STUDENT#11223344", sk: "PROFILE", name: "Luis Ramírez", email: "luis@correo.com", classroom: "5to C" }
  ]

  for (const alumno of alumnos) {
    await docClient.put({ TableName: "attendance", Item: alumno }).promise()
  }
  console.log(`${alumnos.length} alumnos de prueba cargados.`)

  // Algunas asistencias de ejemplo para Juan Pérez
  const asistencias = [
    { pk: "STUDENT#12345678", sk: "ATTENDANCE#1000", timestamp: new Date(Date.now() - 86400000).toISOString(), method: "RFID" },
    { pk: "STUDENT#12345678", sk: "ATTENDANCE#2000", timestamp: new Date().toISOString(), method: "MANUAL" }
  ]

  for (const asistencia of asistencias) {
    await docClient.put({ TableName: "attendance", Item: asistencia }).promise()
  }
  console.log(`${asistencias.length} registros de asistencia de prueba cargados.`)
}

async function main() {
  try {
    await crearTabla()
    await cargarDatosDePrueba()
    console.log("Seed completado con éxito.")
  } catch (error) {
    console.error("Error al hacer seed:", error.message)
    process.exit(1)
  }
}

main()
