const mockGet = jest.fn()
const mockPut = jest.fn()

jest.mock("aws-sdk", () => ({
  DynamoDB: {
    DocumentClient: jest.fn(() => ({
      get: mockGet,
      put: mockPut
    }))
  }
}))

const { handler } = require("../index")

beforeEach(() => {
  mockGet.mockReset()
  mockPut.mockReset()
})

test("responde 400 cuando el body manual no es JSON valido", async () => {
  const respuesta = await handler({ body: "{no-json" })

  expect(respuesta.statusCode).toBe(400)
  expect(JSON.parse(respuesta.body).message).toBe("JSON inválido")
})

test("devuelve JSON y CORS al registrar asistencia manual", async () => {
  mockGet.mockReturnValue({
    promise: () => Promise.resolve({ Item: { pk: "STUDENT#12345678", sk: "PROFILE" } })
  })
  mockPut.mockReturnValue({ promise: () => Promise.resolve({}) })

  const respuesta = await handler({ body: JSON.stringify({ dni: "12345678" }) })

  expect(respuesta.statusCode).toBe(200)
  expect(JSON.parse(respuesta.body).message).toBe("Asistencia manual registrada")
  expect(respuesta.headers["Access-Control-Allow-Origin"]).toBe("*")
})
