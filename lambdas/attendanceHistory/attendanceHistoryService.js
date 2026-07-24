
async function consultarHistorial(dni, db, options = {}) {
  const tableName = options.tableName || process.env.TABLE_NAME || "attendance"

  if (!dni) {
    return { error: "DNI es obligatorio" }
  }

  const data = await db.query({
    TableName: tableName,
    KeyConditionExpression: "pk = :pk AND begins_with(sk, :sk)",
    ExpressionAttributeValues: {
      ":pk": `STUDENT#${dni}`,
      ":sk": "ATTENDANCE#"
    }
  }).promise()

  return { historial: data.Items }
}

module.exports = { consultarHistorial }
