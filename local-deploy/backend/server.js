const express = require("express")
const cors = require("cors")
const AWS = require("aws-sdk")

const { registrarAlumno } = require("./services/studentService")
const { notificarAlumno } = require("./services/notificationService")
const { registrarAsistencia } = require("./services/attendanceService")
const { registrarAsistenciaManual } = require("./services/manualAttendanceService")
const { listarAlumnos } = require("./services/listStudentsService")
const { consultarHistorial } = require("./services/attendanceHistoryService")

const app = express()
app.use(cors())
app.use(express.json())

// Cliente de DynamoDB apuntando al contenedor local (no a AWS real)
const db = new AWS.DynamoDB.DocumentClient({
  region: "us-east-1",
  endpoint: process.env.DYNAMODB_ENDPOINT || "http://localhost:8000",
  accessKeyId: "local",
  secretAccessKey: "local"
})

// Cliente de SNS simulado: no se conecta a AWS, solo registra en consola
const sns = {
  publish: (params) => ({
    promise: async () => {
      console.log("📧 [SNS simulado] " + params.Subject + ": " + params.Message)
      return {}
    }
  })
}

// POST /students -> registrar alumno
app.post("/students", async (req, res) => {
  const resultado = await registrarAlumno(req.body, db)

  if (resultado.error) {
    return res.status(400).json({ message: resultado.error })
  }

  await notificarAlumno(req.body, sns)
  res.status(200).json({ message: "Alumno registrado" })
})

// GET /students -> listar alumnos
app.get("/students", async (req, res) => {
  const resultado = await listarAlumnos(db)
  res.status(200).json(resultado.alumnos)
})

// POST /attendance -> asistencia por RFID
app.post("/attendance", async (req, res) => {
  const resultado = await registrarAsistencia(req.body, db)

  if (resultado.error) {
    return res.status(400).json({ message: resultado.error })
  }

  res.status(200).json({ message: "Asistencia registrada" })
})

// POST /attendance/manual -> asistencia manual
app.post("/attendance/manual", async (req, res) => {
  const resultado = await registrarAsistenciaManual(req.body, db)

  if (resultado.error) {
    return res.status(400).json({ message: resultado.error })
  }

  res.status(200).json({ message: "Asistencia manual registrada" })
})

// GET /attendance/history/:dni -> historial de un alumno
app.get("/attendance/history/:dni", async (req, res) => {
  const resultado = await consultarHistorial(req.params.dni, db)

  if (resultado.error) {
    return res.status(400).json({ message: resultado.error })
  }

  res.status(200).json(resultado.historial)
})

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" })
})

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`Backend escuchando en el puerto ${PORT}`)
})
