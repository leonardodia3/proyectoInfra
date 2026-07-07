const { handler } = require("./index")

// Sobrescribimos temporalmente el db falso solo para esta prueba manual
const eventoFalso = {
  body: JSON.stringify({
    dni: "12345678",
    name: "Juan Pérez",
    email: "juan@correo.com",
    classroom: "5to C"
  })
}

handler(eventoFalso)
  .then(respuesta => console.log("Respuesta:", respuesta))
  .catch(error => console.log("Error:", error))
