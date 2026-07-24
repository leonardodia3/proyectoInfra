jest.mock("aws-sdk", () => {
  const mockDb = {
    query: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Items: [] })
    })
  }

  return {
    DynamoDB: { DocumentClient: jest.fn(() => mockDb) }
  }
})

const { handler } = require("../index")

test("consulta historial usando el parámetro dni de API Gateway", async () => {
  const respuesta = await handler({
    pathParameters: { dni: "12345678" }
  })

  expect(respuesta.statusCode).toBe(200)
  expect(JSON.parse(respuesta.body)).toEqual([])
})
