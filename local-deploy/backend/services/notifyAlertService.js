async function procesarAlertaTardanza(record, sns) {
  const body = JSON.parse(record.body)

  if (!body.dni) {
    return { error: "DNI es obligatorio en el mensaje" }
  }

  try {
    await sns.publish({
      TopicArn: process.env.SNS_TOPIC_ARN || "local-topic",
      Message: `Alerta de tardanza: ${body.name || "Alumno"} (DNI: ${body.dni}) registró ingreso por ${body.method || "RFID"} a las ${body.timestamp}`,
      Subject: "Alerta de tardanza"
    }).promise()

    return { success: true }
  } catch (error) {
    return { error: "No se pudo enviar la alerta" }
  }
}

module.exports = { procesarAlertaTardanza }
