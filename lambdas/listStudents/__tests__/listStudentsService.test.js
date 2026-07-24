const { listarAlumnos } = require("../listStudentsService")

test("devuelve la lista de alumnos cuando hay registros", async () => {
  const dbFalso = {
    scan: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({
        Items: [
          {
            pk: "STUDENT#12345678",
            sk: "PROFILE",
            name: "Juan",
            email: "juan@correo.com",
            classroom: "5to C",
            rfid: "RFID12345678"
          },
          {
            pk: "STUDENT#87654321",
            sk: "PROFILE",
            name: "Ana",
            email: "ana@correo.com",
            classroom: "4to B",
            rfid: "RFID87654321"
          }
        ]
      })
    })
  }

  const resultado = await listarAlumnos(dbFalso)
  expect(resultado.alumnos).toEqual([
    {
      dni: "12345678",
      name: "Juan",
      email: "juan@correo.com",
      classroom: "5to C",
      rfid: "RFID12345678"
    },
    {
      dni: "87654321",
      name: "Ana",
      email: "ana@correo.com",
      classroom: "4to B",
      rfid: "RFID87654321"
    }
  ])
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
