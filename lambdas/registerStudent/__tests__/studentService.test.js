const { registrarAlumno, eliminarAlumno } = require("../studentService")

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

  const resultado = await registrarAlumno({ dni: "12345678", email: "a@a.com", name: "Juan", classroom: "5to C" }, dbFalso)
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

test("rechaza DNI con letras", async () => {
  const resultado = await registrarAlumno({ dni: "abcdefgh", email: "a@a.com" }, {})
  expect(resultado.error).toBe("El DNI debe contener solo números")
})

test("rechaza nombre vacío", async () => {
  const resultado = await registrarAlumno({ dni: "12345678", email: "a@a.com", name: "" }, {})
  expect(resultado.error).toBe("El nombre es obligatorio")
})

test("rechaza salón vacío", async () => {
  const resultado = await registrarAlumno({ dni: "12345678", email: "a@a.com", name: "Juan", classroom: "" }, {})
  expect(resultado.error).toBe("El salón es obligatorio")
})

test("rechaza correo con dominio incompleto", async () => {
  const resultado = await registrarAlumno({ dni: "12345678", email: "leonardo@gmail.c" }, {})
  expect(resultado.error).toBe("El correo no es válido")
})

test("rechaza eliminar sin DNI", async () => {
  const resultado = await eliminarAlumno("", {})
  expect(resultado.error).toBe("DNI es obligatorio")
})

test("rechaza eliminar un alumno que no existe", async () => {
  const dbFalso = {
    get: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Item: undefined })
    })
  }
  const resultado = await eliminarAlumno("12345678", dbFalso)
  expect(resultado.error).toBe("El alumno no existe")
})

test("elimina correctamente el perfil de un alumno existente", async () => {
  const dbFalso = {
    get: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Item: { pk: "STUDENT#12345678", sk: "PROFILE" } })
    }),
    delete: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }
  const resultado = await eliminarAlumno("12345678", dbFalso)
  expect(resultado.success).toBe(true)
})