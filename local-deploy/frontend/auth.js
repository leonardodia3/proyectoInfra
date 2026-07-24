const AttendanceAuth = (() => {
  function actualizarEstadoAuth() {
    const estado = document.getElementById("auth-status")
    const apiKeyInput = document.getElementById("input-api-key")
    const sesion = AttendanceApi.estado()

    if (!estado || !apiKeyInput) return

    estado.textContent = sesion.idToken ? "sesión activa" : "sin sesión"
    estado.className = "status-pill " + (sesion.idToken ? "ok" : "")
    apiKeyInput.value = sesion.esp32ApiKey
  }

  function configurarDniNumerico() {
    document.querySelectorAll('input[name="dni"]').forEach(input => {
      input.addEventListener("input", () => {
        input.value = input.value.replace(/[^0-9]/g, "").slice(0, 8)
      })
    })
  }

  function configurarAuth(cargarAlumnos, mostrarFeedback) {
    actualizarEstadoAuth()

    document.getElementById("form-login").addEventListener("submit", async (e) => {
      e.preventDefault()
      if (!AttendanceApi.estado().isAws) return

      const form = e.target
      if (!form.username.value || !form.password.value) {
        mostrarFeedback("feedback-login", "Ingresa usuario y contraseña de Cognito", false)
        return
      }

      try {
        const resultado = await AttendanceApi.iniciarSesion(
          form.username.value,
          form.password.value,
          form.apiKey.value.trim()
        )

        if (resultado.error) {
          mostrarFeedback("feedback-login", resultado.error, false)
          return
        }

        actualizarEstadoAuth()
        mostrarFeedback("feedback-login", "Sesión iniciada", true)
        cargarAlumnos()
      } catch (err) {
        mostrarFeedback("feedback-login", "No se pudo conectar con Cognito", false)
      }
    })

    document.getElementById("btn-logout").addEventListener("click", () => {
      AttendanceApi.cerrarSesion()
      actualizarEstadoAuth()
      mostrarFeedback("feedback-login", "Sesión cerrada", true)
    })

    document.getElementById("input-api-key").addEventListener("change", (e) => {
      AttendanceApi.guardarApiKey(e.target.value.trim())
    })
  }

  return { configurarAuth, configurarDniNumerico }
})()
