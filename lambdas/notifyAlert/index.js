const AWS = require("aws-sdk")
const sns = new AWS.SNS()
const { procesarAlertaTardanza } = require("./notifyAlertService")

exports.handler = async (event) => {
  for (const record of event.Records) {
    await procesarAlertaTardanza(record, sns)
  }

  return { statusCode: 200 }
}