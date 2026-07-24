const mockPublish = jest.fn()

jest.mock("aws-sdk", () => ({
  SNS: jest.fn(() => ({
    publish: mockPublish
  }))
}))

const { handler } = require("../index")

beforeEach(() => {
  mockPublish.mockReset()
})

test("confirma el procesamiento cuando SNS publica la alerta", async () => {
  mockPublish.mockReturnValue({
    promise: () => Promise.resolve({})
  })

  const respuesta = await handler({
    Records: [{ body: JSON.stringify({ dni: "12345678" }) }]
  })

  expect(respuesta.statusCode).toBe(200)
})

test("falla el procesamiento para que SQS reintente si SNS no publica", async () => {
  mockPublish.mockReturnValue({
    promise: () => Promise.reject(new Error("SNS no disponible"))
  })

  await expect(handler({
    Records: [{ body: JSON.stringify({ dni: "12345678" }) }]
  })).rejects.toThrow("No se pudo enviar la alerta")
})
