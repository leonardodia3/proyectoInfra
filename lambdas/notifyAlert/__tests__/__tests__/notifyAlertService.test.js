const { procesarAlertaTardanza } = require("../notifyAlertService")

test("rechaza mensaje sin DNI", async () => {
  const record = { body: JSON.stringify({}) }
  const resultado = await procesarAlertaTardanza(record, {})
  expect(resultado.error).toBe("DNI es obligatorio en el mensaje")
})

test("envía la alerta correctamente cuando el mensaje es válido", async () => {
  const snsFalso = {
    publish: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({})
    })
  }

  const record = { body: JSON.stringify({ dni: "12345678" }) }
  const resultado = await procesarAlertaTardanza(record, snsFalso)
  expect(resultado.success).toBe(true)
})

test("maneja el error si sns.publish falla", async () => {
  const snsFalso = {
    publish: jest.fn().mockReturnValue({
      promise: () => Promise.reject(new Error("SNS no disponible"))
    })
  }

  const record = { body: JSON.stringify({ dni: "12345678" }) }
  const resultado = await procesarAlertaTardanza(record, snsFalso)
  expect(resultado.error).toBe("No se pudo enviar la alerta")
})