jest.mock("aws-sdk", () => {
  const mockDb = {
    get: jest.fn().mockReturnValue({ promise: () => Promise.resolve({ Item: undefined }) }),
    put: jest.fn().mockReturnValue({ promise: () => Promise.resolve({}) })
  }
  const mockSns = {
    publish: jest.fn().mockReturnValue({ promise: () => Promise.resolve({}) })
  }
  return {
    DynamoDB: { DocumentClient: jest.fn(() => mockDb) },
    SNS: jest.fn(() => mockSns)
  }
})

const { handler } = require("../index")

test("registra un alumno correctamente vía el handler completo", async () => {
  const event = {
    body: JSON.stringify({
      dni: "12345678",
      name: "Juan Pérez",
      email: "juan@correo.com",
      classroom: "5to C"
    })
  }

  const respuesta = await handler(event)

  expect(respuesta.statusCode).toBe(200)
  expect(JSON.parse(respuesta.body).message).toBe("Alumno registrado")
})