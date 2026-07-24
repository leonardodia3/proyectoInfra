const mockPut = jest.fn()
const mockScan = jest.fn()
const mockSendMessage = jest.fn()

jest.mock("aws-sdk", () => ({
  DynamoDB: {
    DocumentClient: jest.fn(() => ({
      scan: mockScan,
      put: mockPut
    }))
  },
  SQS: jest.fn(() => ({
    sendMessage: mockSendMessage
  }))
}))

const { handler } = require("../index")

beforeEach(() => {
  mockPut.mockReset()
  mockScan.mockReset()
  mockSendMessage.mockReset()
})

test("responde 400 cuando el body RFID no es JSON valido", async () => {
  const respuesta = await handler({ body: "{no-json" })

  expect(respuesta.statusCode).toBe(400)
  expect(JSON.parse(respuesta.body).message).toBe("JSON inválido")
})

test("responde con CORS al registrar asistencia RFID", async () => {
  mockScan.mockReturnValue({
    promise: () => Promise.resolve({
      Items: [{
        pk: "STUDENT#12345678",
        sk: "PROFILE",
        name: "Juan Perez",
        email: "juan@correo.com",
        rfid: "RFID12345678"
      }]
    })
  })
  mockPut.mockReturnValue({ promise: () => Promise.resolve({}) })

  const respuesta = await handler({
    body: JSON.stringify({ rfid: "RFID12345678", timestamp: "2026-07-22T12:30:00.000Z" })
  })

  expect(respuesta.statusCode).toBe(200)
  expect(respuesta.headers["Access-Control-Allow-Headers"]).toContain("X-Api-Key")
})
