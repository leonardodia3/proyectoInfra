async function listarAlumnos(db) {
  const data = await db.scan({
    TableName: "attendance",
    FilterExpression: "sk = :sk",
    ExpressionAttributeValues: {
      ":sk": "PROFILE"
    }
  }).promise()

  return { alumnos: data.Items }
}

module.exports = { listarAlumnos }
