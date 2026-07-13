const { notificarAlumno } = require("../notificationService")

test("notifica al alumno registrado", async () => {
  const snsFalso = {
    publish: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }

  const resultado = await notificarAlumno(
    { dni: "12345678", email: "a@a.com", name: "Juan" },
    snsFalso
  )

  expect(resultado.success).toBe(true)
  expect(snsFalso.publish).toHaveBeenCalled()
})

test("maneja el error si sns.publish falla", async () => {
  const snsFalso = {
    publish: jest.fn().mockReturnValue({
      promise: () => Promise.reject(new Error("SNS no disponible"))
    })
  }

  const resultado = await notificarAlumno(
    { dni: "12345678", email: "a@a.com", name: "Juan" },
    snsFalso
  )

  expect(resultado.error).toBe("No se pudo enviar la notificación")
})