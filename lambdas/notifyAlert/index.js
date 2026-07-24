const AWS = require("aws-sdk")
const sns = new AWS.SNS()
const { procesarAlertaTardanza } = require("./notifyAlertService")

exports.handler = async (event) => {
  for (const record of event.Records) {
    const resultado = await procesarAlertaTardanza(record, sns)

    if (resultado.error) {
      throw new Error(resultado.error)
    }
  }

  return { statusCode: 200 }
}
