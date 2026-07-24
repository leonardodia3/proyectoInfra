async function procesarAlertaTardanza(record, sns) {
  let body

  try {
    body = JSON.parse(record.body)
  } catch (error) {
    return { error: "Mensaje SQS inválido" }
  }

  if (!body.dni) {
    return { error: "DNI es obligatorio en el mensaje" }
  }

  try {
    await sns.publish({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Message: `Alerta de tardanza para el alumno con DNI: ${body.dni}`,
      Subject: "Alerta de tardanza"
    }).promise()

    return { success: true }
  } catch (error) {
    return { error: "No se pudo enviar la alerta" }
  }
}

module.exports = { procesarAlertaTardanza }
