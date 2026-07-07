async function notificarAlumno(body, sns) {
  await sns.publish({
    TopicArn: process.env.SNS_TOPIC_ARN,
    Message: `Alumno registrado: ${body.name} (DNI: ${body.dni})`,
    Subject: "Nuevo alumno registrado"
  }).promise()

  return { success: true }
}

module.exports = { notificarAlumno }