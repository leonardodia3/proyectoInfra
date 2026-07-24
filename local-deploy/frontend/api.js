const AttendanceApi = (() => {
  const config = window.APP_CONFIG || { mode: "local" }
  const isAws = config.mode === "aws"
  const apiUrl = config.apiBaseUrl || (
    window.location.hostname === "localhost"
      ? "http://localhost:3000"
      : `http://${window.location.hostname}:3000`
  )

  let idToken = sessionStorage.getItem("attendance_id_token") || ""
  let esp32ApiKey = sessionStorage.getItem("attendance_esp32_api_key") || ""

  async function leerRespuesta(res) {
    const texto = await res.text()
    if (!texto) return {}

    try {
      return JSON.parse(texto)
    } catch (err) {
      return { message: texto }
    }
  }

  function guardarApiKey(apiKey) {
    esp32ApiKey = apiKey
    sessionStorage.setItem("attendance_esp32_api_key", esp32ApiKey)
  }

  function headersJson(opciones = {}) {
    const headers = { "Content-Type": "application/json" }

    if (isAws && opciones.protegido && idToken) {
      headers.Authorization = idToken
    }

    if (isAws && opciones.rfid && esp32ApiKey) {
      headers["x-api-key"] = esp32ApiKey
    }

    return headers
  }

  async function iniciarSesion(username, password, apiKey) {
    guardarApiKey(apiKey)

    const res = await fetch(`https://cognito-idp.${config.cognitoRegion}.amazonaws.com/`, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-amz-json-1.1",
        "X-Amz-Target": "AWSCognitoIdentityProviderService.InitiateAuth"
      },
      body: JSON.stringify({
        AuthFlow: "USER_PASSWORD_AUTH",
        ClientId: config.cognitoClientId,
        AuthParameters: {
          USERNAME: username,
          PASSWORD: password
        }
      })
    })
    const data = await leerRespuesta(res)

    if (!res.ok || !data.AuthenticationResult) {
      return {
        error: data.ChallengeName === "NEW_PASSWORD_REQUIRED"
          ? "Configura una contraseña permanente para ese usuario Cognito"
          : data.message || data.__type || "No se pudo iniciar sesión"
      }
    }

    idToken = data.AuthenticationResult.IdToken
    sessionStorage.setItem("attendance_id_token", idToken)
    return { success: true }
  }

  function cerrarSesion() {
    idToken = ""
    sessionStorage.removeItem("attendance_id_token")
  }

  function estado() {
    return { apiUrl, esp32ApiKey, idToken, isAws }
  }

  return {
    cerrarSesion,
    estado,
    guardarApiKey,
    headersJson,
    iniciarSesion,
    leerRespuesta,
    tieneApiKey: () => !isAws || Boolean(esp32ApiKey),
    tieneSesion: () => !isAws || Boolean(idToken)
  }
})()
