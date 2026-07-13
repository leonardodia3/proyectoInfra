async function consultarHistorial(dni, db) {
  if (!dni) {
    return { error: "DNI es obligatorio" }
  }

  const data = await db.query({
    TableName: "attendance",
    KeyConditionExpression: "pk = :pk AND begins_with(sk, :sk)",
    ExpressionAttributeValues: {
      ":pk": `STUDENT#${dni}`,
      ":sk": "ATTENDANCE#"
    }
  }).promise()

  return { historial: data.Items }
}

module.exports = { consultarHistorial }
