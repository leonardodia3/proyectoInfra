const { registrarAlumno } = require("../studentService")

test("rechaza DNI vacio", async () => {
  const resultado = await registrarAlumno({ dni: "", email: "a@a.com" }, {})
  expect(resultado.error).toBe("DNI es obligatorio")
})
test("rechaza DNI con formato incorrecto", async () => {
  const resultado = await registrarAlumno({ dni: "123", email: "a@a.com" }, {})
  expect(resultado.error).toBe("DNI no es válido")
})
test("rechaza correo vacío", async () => {
  const resultado = await registrarAlumno({ dni: "12345678", email: "" }, {})
  expect(resultado.error).toBe("El correo es obligatorio")
})
test("rechaza correo con formato inválido", async () => {
  const resultado = await registrarAlumno({ dni: "12345678", email: "correoinvalido" }, {})
  expect(resultado.error).toBe("El correo no es válido")
})
test("rechaza DNI duplicado", async () => {
  const dbFalso = {
    get: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Item: { pk: "STUDENT#12345678" } })
    })
  }

  const resultado = await registrarAlumno({ dni: "12345678", email: "a@a.com" }, dbFalso)
  expect(resultado.error).toBe("El DNI ya está registrado")
})
test("registra correctamente con datos válidos", async () => {
  const dbFalso = {
    get: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Item: undefined })
    }),
    put: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }

  const resultado = await registrarAlumno(
    { dni: "12345678", email: "a@a.com", name: "Juan", classroom: "5to C" },
    dbFalso
  )

  expect(resultado.success).toBe(true)
})