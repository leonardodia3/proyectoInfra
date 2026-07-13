const { listarAlumnos } = require("../listStudentsService")

test("devuelve la lista de alumnos cuando hay registros", async () => {
  const dbFalso = {
    scan: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({
        Items: [
          { pk: "STUDENT#12345678", sk: "PROFILE", name: "Juan" },
          { pk: "STUDENT#87654321", sk: "PROFILE", name: "Ana" }
        ]
      })
    })
  }

  const resultado = await listarAlumnos(dbFalso)
  expect(resultado.alumnos.length).toBe(2)
})

test("devuelve una lista vacía cuando no hay alumnos", async () => {
  const dbFalso = {
    scan: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Items: [] })
    })
  }

  const resultado = await listarAlumnos(dbFalso)
  expect(resultado.alumnos.length).toBe(0)
})