const estadoInicial = AttendanceApi.estado()

document.body.dataset.mode = estadoInicial.isAws ? "aws" : "local"
document.getElementById("env-badge").textContent = estadoInicial.isAws ? "desplegado AWS" : "entorno local"

function mostrarFeedback(elementId, mensaje, ok) {
  const el = document.getElementById(elementId)
  el.textContent = mensaje
  el.className = "feedback " + (ok ? "ok" : "error")
}

function requiereSesion(feedbackId) {
  if (AttendanceApi.tieneSesion()) return true

  mostrarFeedback(feedbackId, "Inicia sesión con Cognito para usar esta acción desplegada", false)
  return false
}

function requiereApiKey(feedbackId) {
  if (AttendanceApi.tieneApiKey()) return true

  mostrarFeedback(feedbackId, "Ingresa la API Key del ESP32 para simular RFID en AWS", false)
  return false
}

function agregarCelda(row, texto) {
  const cell = document.createElement("td")
  cell.textContent = texto
  row.appendChild(cell)
}

function mostrarMensajeLista(lista, mensaje) {
  const item = document.createElement("li")
  item.textContent = mensaje
  lista.replaceChildren(item)
}

function mostrarMensajeTabla(tbody, mensaje) {
  const row = document.createElement("tr")
  const cell = document.createElement("td")
  row.className = "table-message-row"
  cell.className = "table-message"
  cell.colSpan = 6
  cell.textContent = mensaje
  row.appendChild(cell)
  tbody.replaceChildren(row)
}

async function pedirJson(path, opciones = {}) {
  const res = await fetch(`${AttendanceApi.estado().apiUrl}${path}`, {
    method: opciones.method || "GET",
    headers: AttendanceApi.headersJson(opciones),
    body: opciones.body ? JSON.stringify(opciones.body) : undefined
  })
  const data = await AttendanceApi.leerRespuesta(res)
  return { data, ok: res.ok }
}

function configurarRegistro() {
  document.getElementById("form-registrar").addEventListener("submit", async (e) => {
    e.preventDefault()
    if (!requiereSesion("feedback-registrar")) return

    const form = e.target
    const body = {
      dni: form.dni.value,
      name: form.name.value,
      email: form.email.value,
      classroom: form.classroom.value,
      rfid: form.rfid.value.trim()
    }

    try {
      const { data, ok } = await pedirJson("/students", { method: "POST", protegido: true, body })
      mostrarFeedback("feedback-registrar", data.message, ok)
      if (ok) {
        form.reset()
        cargarAlumnos()
      }
    } catch (err) {
      mostrarFeedback("feedback-registrar", "No se pudo conectar con el backend", false)
    }
  })
}

function configurarAsistencia() {
  document.getElementById("form-asistencia").addEventListener("submit", async (e) => {
    e.preventDefault()
    const method = e.submitter.dataset.method
    const form = e.target
    const dni = form.dni.value
    const rfid = form.rfid.value.trim()

    if (method === "manual" && !dni) {
      mostrarFeedback("feedback-asistencia", "Ingresa el DNI para registrar asistencia manual", false)
      return
    }

    if (method === "rfid" && !rfid) {
      mostrarFeedback("feedback-asistencia", "Ingresa el RFID para registrar asistencia automática", false)
      return
    }

    if (method === "manual" && !requiereSesion("feedback-asistencia")) return
    if (method === "rfid" && !requiereApiKey("feedback-asistencia")) return

    try {
      const path = method === "manual" ? "/attendance/manual" : "/attendance"
      const body = method === "manual" ? { dni } : { rfid }
      const { data, ok } = await pedirJson(path, {
        method: "POST",
        protegido: method === "manual",
        rfid: method === "rfid",
        body
      })
      const detalle = data.tardanza ? " Se envió alerta simulada al tutor." : ""
      mostrarFeedback("feedback-asistencia", `${data.message}${detalle}`, ok)
    } catch (err) {
      mostrarFeedback("feedback-asistencia", "No se pudo conectar con el backend", false)
    }
  })
}

function configurarHistorial() {
  document.getElementById("form-historial").addEventListener("submit", async (e) => {
    e.preventDefault()
    const dni = e.target.dni.value
    const lista = document.getElementById("lista-historial")
    lista.replaceChildren()

    if (!AttendanceApi.tieneSesion()) {
      mostrarMensajeLista(lista, "Inicia sesión con Cognito para consultar historial")
      return
    }

    try {
      const { data, ok } = await pedirJson(`/attendance/history/${dni}`, { protegido: true })
      if (!ok) {
        mostrarMensajeLista(lista, data.message)
        return
      }

      if (data.length === 0) {
        mostrarMensajeLista(lista, "Sin registros de asistencia")
        return
      }

      data.forEach(item => {
        const li = document.createElement("li")
        const fecha = document.createElement("span")
        const metodo = document.createElement("span")
        fecha.textContent = new Date(item.timestamp).toLocaleString()
        metodo.textContent = item.status ? `${item.method} - ${item.status}` : item.method
        li.append(fecha, metodo)
        lista.appendChild(li)
      })
    } catch (err) {
      mostrarMensajeLista(lista, "No se pudo conectar con el backend")
    }
  })
}

async function cargarAlumnos() {
  const tbody = document.getElementById("tabla-alumnos")
  if (!requiereSesion("feedback-login")) {
    mostrarMensajeTabla(tbody, "Inicia sesión con Cognito para listar alumnos")
    return
  }

  mostrarMensajeTabla(tbody, "Cargando...")

  try {
    const { data: alumnos, ok } = await pedirJson("/students", { protegido: true })
    if (!ok) {
      mostrarMensajeTabla(tbody, alumnos.message || "No se pudo listar alumnos")
      return
    }

    if (alumnos.length === 0) {
      mostrarMensajeTabla(tbody, "No hay alumnos registrados todavía")
      return
    }

    tbody.replaceChildren(...alumnos.map(renderizarAlumno))
    document.querySelectorAll(".btn-eliminar").forEach(btn => {
      btn.addEventListener("click", () => eliminarAlumno(btn.dataset.dni))
    })
  } catch (err) {
    mostrarMensajeTabla(tbody, "No se pudo conectar con el backend")
  }
}

function renderizarAlumno(alumno) {
  const row = document.createElement("tr")
  const actions = document.createElement("td")
  const deleteButton = document.createElement("button")
  deleteButton.className = "secondary btn-eliminar"
  deleteButton.dataset.dni = alumno.dni
  deleteButton.textContent = "Eliminar"
  actions.appendChild(deleteButton)
  agregarCelda(row, alumno.dni)
  agregarCelda(row, alumno.rfid || "")
  agregarCelda(row, alumno.name)
  agregarCelda(row, alumno.email)
  agregarCelda(row, alumno.classroom)
  row.appendChild(actions)
  return row
}

async function eliminarAlumno(dni) {
  const confirmado = confirm(`¿Seguro que quieres eliminar al alumno con DNI ${dni}? Su historial de asistencia se conservará.`)
  if (!confirmado || !requiereSesion("feedback-login")) return

  try {
    const { data, ok } = await pedirJson(`/students/${dni}`, { method: "DELETE", protegido: true })
    if (!ok) {
      alert(data.message)
      return
    }

    cargarAlumnos()
  } catch (err) {
    alert("No se pudo conectar con el backend")
  }
}

AttendanceAuth.configurarDniNumerico()
AttendanceAuth.configurarAuth(cargarAlumnos, mostrarFeedback)
configurarRegistro()
configurarAsistencia()
configurarHistorial()
document.getElementById("btn-refrescar").addEventListener("click", cargarAlumnos)
cargarAlumnos()
