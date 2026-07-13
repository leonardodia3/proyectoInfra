const { consultarHistorial } = require("../attendanceHistoryService")

test("rechaza consulta sin DNI", async () => {
  const resultado = await consultarHistorial("", {})
  expect(resultado.error).toBe("DNI es obligatorio")
})

test("devuelve el historial de asistencias de un alumno", async () => {
  const dbFalso = {
    query: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({
        Items: [
          { pk: "STUDENT#12345678", sk: "ATTENDANCE#1000", method: "RFID" },
          { pk: "STUDENT#12345678", sk: "ATTENDANCE#2000", method: "MANUAL" }
        ]
      })
    })
  }

  const resultado = await consultarHistorial("12345678", dbFalso)
  expect(resultado.historial.length).toBe(2)
})

test("devuelve historial vacío si el alumno no tiene asistencias", async () => {
  const dbFalso = {
    query: jest.fn().mockReturnValue({
      promise: () => Promise.resolve({ Items: [] })
    })
  }

  const resultado = await consultarHistorial("12345678", dbFalso)
  expect(resultado.historial.length).toBe(0)
})