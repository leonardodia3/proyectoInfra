const API_URL = window.location.hostname === "localhost"
  ? "http://localhost:3000"
  : `http://${window.location.hostname}:3000`

// Evita que se escriban letras en cualquier campo de DNI del panel
document.querySelectorAll('input[name="dni"]').forEach(input => {
  input.addEventListener("input", () => {
    input.value = input.value.replace(/[^0-9]/g, "").slice(0, 8)
  })
})

function mostrarFeedback(elementId, mensaje, ok) {
  const el = document.getElementById(elementId)
  el.textContent = mensaje
  el.className = "feedback " + (ok ? "ok" : "error")
}

// Registrar alumno
document.getElementById("form-registrar").addEventListener("submit", async (e) => {
  e.preventDefault()
  const form = e.target
  const body = {
    dni: form.dni.value,
    name: form.name.value,
    email: form.email.value,
    classroom: form.classroom.value
  }

  try {
    const res = await fetch(`${API_URL}/students`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body)
    })
    const data = await res.json()
    mostrarFeedback("feedback-registrar", data.message, res.ok)
    if (res.ok) {
      form.reset()
      cargarAlumnos()
    }
  } catch (err) {
    mostrarFeedback("feedback-registrar", "No se pudo conectar con el backend", false)
  }
})

// Marcar asistencia (RFID o manual, según el botón presionado)
document.getElementById("form-asistencia").addEventListener("submit", async (e) => {
  e.preventDefault()
  const method = e.submitter.dataset.method
  const dni = e.target.dni.value
  const ruta = method === "manual" ? "/attendance/manual" : "/attendance"

  try {
    const res = await fetch(`${API_URL}${ruta}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ dni })
    })
    const data = await res.json()
    mostrarFeedback("feedback-asistencia", data.message, res.ok)
  } catch (err) {
    mostrarFeedback("feedback-asistencia", "No se pudo conectar con el backend", false)
  }
})

// Consultar historial
document.getElementById("form-historial").addEventListener("submit", async (e) => {
  e.preventDefault()
  const dni = e.target.dni.value
  const lista = document.getElementById("lista-historial")
  lista.innerHTML = ""

  try {
    const res = await fetch(`${API_URL}/attendance/history/${dni}`)
    const data = await res.json()

    if (!res.ok) {
      lista.innerHTML = `<li>${data.message}</li>`
      return
    }

    if (data.length === 0) {
      lista.innerHTML = "<li>Sin registros de asistencia</li>"
      return
    }

    data.forEach(item => {
      const li = document.createElement("li")
      li.innerHTML = `<span>${new Date(item.timestamp).toLocaleString()}</span><span>${item.method}</span>`
      lista.appendChild(li)
    })
  } catch (err) {
    lista.innerHTML = "<li>No se pudo conectar con el backend</li>"
  }
})

// Listar alumnos
async function cargarAlumnos() {
  const tbody = document.getElementById("tabla-alumnos")
  tbody.innerHTML = "<tr><td colspan='5'>Cargando...</td></tr>"

  try {
    const res = await fetch(`${API_URL}/students`)
    const alumnos = await res.json()

    if (alumnos.length === 0) {
      tbody.innerHTML = "<tr><td colspan='5'>No hay alumnos registrados todavía</td></tr>"
      return
    }

    tbody.innerHTML = alumnos.map(a => {
      const dni = a.pk.replace("STUDENT#", "")
      return `
      <tr>
        <td>${dni}</td>
        <td>${a.name}</td>
        <td>${a.email}</td>
        <td>${a.classroom}</td>
        <td><button class="secondary btn-eliminar" data-dni="${dni}">Eliminar</button></td>
      </tr>
    `
    }).join("")

    document.querySelectorAll(".btn-eliminar").forEach(btn => {
      btn.addEventListener("click", () => eliminarAlumno(btn.dataset.dni))
    })
  } catch (err) {
    tbody.innerHTML = "<tr><td colspan='5'>No se pudo conectar con el backend</td></tr>"
  }
}

async function eliminarAlumno(dni) {
  const confirmado = confirm(`¿Seguro que quieres eliminar al alumno con DNI ${dni}? Su historial de asistencia se conservará.`)
  if (!confirmado) return

  try {
    const res = await fetch(`${API_URL}/students/${dni}`, { method: "DELETE" })
    const data = await res.json()

    if (!res.ok) {
      alert(data.message)
      return
    }

    cargarAlumnos()
  } catch (err) {
    alert("No se pudo conectar con el backend")
  }
}

document.getElementById("btn-refrescar").addEventListener("click", cargarAlumnos)

cargarAlumnos()
