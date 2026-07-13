async function notificarAlumno(body, sns) {
  try {
    await sns.publish({
      TopicArn: process.env.SNS_TOPIC_ARN,
      Message: `Alumno registrado: ${body.name} (DNI: ${body.dni})`,
      Subject: "Nuevo alumno registrado"
    }).promise()

    return { success: true }
  } catch (error) {
    return { error: "No se pudo enviar la notificación" }
  }
}

module.exports = { notificarAlumno }