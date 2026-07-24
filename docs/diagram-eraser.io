title Sistema de Control de Asistencia RFID

Usuario Web [icon: user, label: "Director / vigilante"]
Panel Web Desplegado [icon: monitor, label: "Panel web en navegador"]
ESP32 RFID [icon: cpu, label: "ESP32 + lector RFID"]
Tutor [icon: mail, label: "Tutor / apoderado"]

Local Docker [icon: docker, color: blue] {
  Frontend Local [icon: monitor, label: "Frontend Nginx :8080"]
  Backend Local [icon: nodejs, label: "Backend Express :3000"]
  DynamoDB Local [icon: database, label: "DynamoDB Local :8000"]
  Prometheus [icon: activity, label: "Prometheus :9090"]
  Grafana [icon: bar-chart, label: "Grafana :3001"]
}

AWS us-east-1 [icon: aws, color: orange] {
  CloudFront [icon: aws-cloudfront, label: "CloudFront frontend_url"]
  S3 Frontend [icon: aws-s3, label: "S3 privado panel web"]
  WAF API [icon: shield, label: "WAF regional"]
  API Gateway [icon: aws-api-gateway, label: "REST API prod"]
  Cognito [icon: aws-cognito, label: "Usuarios del panel"]
  API Key ESP32 [icon: key, label: "Usage Plan + API Key"]

  Lambdas [color: orange] {
    Register Student [icon: aws-lambda, label: "registerStudent"]
    List Students [icon: aws-lambda, label: "listStudents"]
    Attendance RFID [icon: aws-lambda, label: "attendance"]
    Manual Attendance [icon: aws-lambda, label: "manualAttendance"]
    Attendance History [icon: aws-lambda, label: "attendanceHistory"]
    Notify Alert [icon: aws-lambda, label: "notifyAlert"]
  }

  DynamoDB [icon: aws-dynamodb, label: "Tabla attendance + GSI rfid-index"]
  SQS Tardanza [icon: aws-sqs, label: "tardanza-queue + DLQ"]
  SNS Alertas [icon: aws-sns, label: "attendance-alerts"]
  KMS [icon: aws-kms, label: "CMK cifrado"]
  CloudWatch [icon: aws-cloudwatch, label: "Logs, metricas, alarmas, X-Ray"]
}

Usuario Web > Frontend Local: abre demo local
Frontend Local > Backend Local: REST sin Cognito
Backend Local > DynamoDB Local: alumnos y asistencias
Backend Local > Prometheus: expone /metrics
Prometheus > Grafana: datasource y dashboard

Usuario Web > CloudFront: HTTPS panel desplegado
CloudFront > S3 Frontend: sirve index.html, style.css, app.js, config.js
S3 Frontend > Panel Web Desplegado: carga archivos en navegador
Panel Web Desplegado > Cognito: login USER_PASSWORD_AUTH

Panel Web Desplegado > API Gateway: llamadas HTTPS con Authorization Cognito
API Gateway > Cognito: autoriza /students, /attendance/manual, /attendance/history/{dni}
WAF API > API Gateway: protege trafico API

API Gateway > Register Student: POST /students
API Gateway > List Students: GET /students
API Gateway > Manual Attendance: POST /attendance/manual
API Gateway > Attendance History: GET /attendance/history/{dni}

ESP32 RFID > API Gateway: POST /attendance con x-api-key
API Gateway > API Key ESP32: valida API Key
API Gateway > Attendance RFID: invoca Lambda RFID

Register Student > DynamoDB: valida DNI/RFID unico y guarda perfil
List Students > DynamoDB: lista perfiles
Manual Attendance > DynamoDB: guarda asistencia manual por DNI
Attendance History > DynamoDB: consulta historial por DNI
Attendance RFID > DynamoDB: busca alumno por RFID y guarda asistencia
Attendance RFID > SQS Tardanza: encola tardanza si llega tarde
SQS Tardanza > Notify Alert: evento asincrono
Notify Alert > SNS Alertas: publica alerta
SNS Alertas > Tutor: correo de tardanza

DynamoDB > KMS: cifrado en reposo
SQS Tardanza > KMS: cifrado en reposo
SNS Alertas > KMS: cifrado en reposo
S3 Frontend > KMS: cifrado en reposo
API Gateway > CloudWatch: access logs y metricas
Lambdas > CloudWatch: logs y trazas
SQS Tardanza > CloudWatch: alarma DLQ
