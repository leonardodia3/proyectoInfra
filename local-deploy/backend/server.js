const express = require("express")
const cors = require("cors")
const AWS = require("aws-sdk")
const client = require("prom-client")

const { registrarAlumno, eliminarAlumno } = require("./services/studentService")
const { notificarAlumno } = require("./services/notificationService")
const { registrarAsistencia } = require("./services/attendanceService")
const { registrarAsistenciaManual } = require("./services/manualAttendanceService")
const { listarAlumnos } = require("./services/listStudentsService")
const { consultarHistorial } = require("./services/attendanceHistoryService")
const { procesarAlertaTardanza } = require("./services/notifyAlertService")

const app = express()
app.use(cors())
app.use(express.json())

app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
    return res.status(400).json({ message: "JSON inválido" })
  }

  next(err)
})

// ---- Métricas de Prometheus ----
// Métricas por defecto de Node (uso de CPU, memoria, event loop, etc.)
client.collectDefaultMetrics({ prefix: "attendance_backend_" })

// Contador de peticiones HTTP, etiquetado por ruta, método y código de respuesta
const httpRequestsTotal = new client.Counter({
  name: "attendance_http_requests_total",
  help: "Total de peticiones HTTP recibidas",
  labelNames: ["method", "route", "status_code"]
})

// Histograma de duración de peticiones, para medir latencia real por endpoint
const httpRequestDuration = new client.Histogram({
  name: "attendance_http_request_duration_seconds",
  help: "Duración de las peticiones HTTP en segundos",
  labelNames: ["method", "route", "status_code"],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5]
})

// Contador específico de negocio: asistencias registradas por método (RFID vs manual)
const attendanceRegisteredTotal = new client.Counter({
  name: "attendance_registered_total",
  help: "Total de asistencias registradas, por método",
  labelNames: ["method"]
})

app.use((req, res, next) => {
  const finDeTiempo = httpRequestDuration.startTimer()
  res.on("finish", () => {
    const ruta = req.route ? req.route.path : req.path
    const etiquetas = { method: req.method, route: ruta, status_code: res.statusCode }
    httpRequestsTotal.inc(etiquetas)
    finDeTiempo(etiquetas)
  })
  next()
})

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
      console.log("[SNS simulado] " + params.Subject + ": " + params.Message)
      return {}
    }
  })
}

const sqs = {
  sendMessage: (params) => ({
    promise: async () => {
      console.log("[SQS simulado] " + params.QueueUrl + ": " + params.MessageBody)
      const resultado = await procesarAlertaTardanza({ body: params.MessageBody }, sns)

      if (resultado.error) {
        throw new Error(resultado.error)
      }

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

  await notificarAlumno(resultado.alumno, sns)
  res.status(200).json({ message: "Alumno registrado" })
})

// GET /students -> listar alumnos
app.get("/students", async (req, res) => {
  const resultado = await listarAlumnos(db)
  res.status(200).json(resultado.alumnos)
})

// POST /attendance -> asistencia por RFID
app.post("/attendance", async (req, res) => {
  const resultado = await registrarAsistencia(req.body, db, sqs, {
    queueUrl: process.env.TARDANZA_QUEUE_URL || "local-tardanza-queue",
    deadline: process.env.ATTENDANCE_DEADLINE || "08:00",
    timeZone: process.env.ATTENDANCE_TIME_ZONE || "America/Lima"
  })

  if (resultado.error) {
    return res.status(400).json({ message: resultado.error })
  }

  attendanceRegisteredTotal.inc({ method: "RFID" })
  res.status(200).json({
    message: resultado.tardanza
      ? "Asistencia registrada con tardanza"
      : "Asistencia registrada",
    tardanza: resultado.tardanza
  })
})

// POST /attendance/manual -> asistencia manual
app.post("/attendance/manual", async (req, res) => {
  const resultado = await registrarAsistenciaManual(req.body, db)

  if (resultado.error) {
    return res.status(400).json({ message: resultado.error })
  }

  attendanceRegisteredTotal.inc({ method: "MANUAL" })
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

// DELETE /students/:dni -> eliminar perfil de alumno (deja el historial intacto)
app.delete("/students/:dni", async (req, res) => {
  const resultado = await eliminarAlumno(req.params.dni, db)

  if (resultado.error) {
    return res.status(400).json({ message: resultado.error })
  }

  res.status(200).json({ message: "Alumno eliminado" })
})

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" })
})

// Endpoint que Prometheus consulta periódicamente para recolectar las métricas
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", client.register.contentType)
  res.end(await client.register.metrics())
})

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`Backend escuchando en el puerto ${PORT}`)
})
