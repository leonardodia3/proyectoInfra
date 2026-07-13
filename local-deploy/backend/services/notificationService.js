// En AWS real esto usa Amazon SNS. En local, simulamos el envío
// imprimiendo el mensaje en la consola del backend, para no necesitar
// credenciales ni conexión a internet mientras pruebas localmente.
async function notificarAlumno(body, sns) {
  try {
    await sns.publish({
      TopicArn: process.env.SNS_TOPIC_ARN || "local-topic",
      Message: `Alumno registrado: ${body.name} (DNI: ${body.dni})`,
      Subject: "Nuevo alumno registrado"
    }).promise()

    return { success: true }
  } catch (error) {
    return { error: "No se pudo enviar la notificación" }
  }
}

module.exports = { notificarAlumno }
