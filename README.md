# proyectoInfra — Sistema de Control de Asistencia Escolar con RFID en AWS

## ¿Qué hace este proyecto?

Este proyecto implementa un sistema de control de asistencia escolar en la nube usando AWS. Permite registrar la asistencia de alumnos de forma automática mediante un lector RFID (ESP32) o de forma manual por parte del vigilante o director. Toda la infraestructura está definida como código usando Terraform y el análisis de calidad del código se realiza automáticamente con SonarQube Cloud a través de GitHub Actions.

## ¿Cómo funciona?

El alumno pasa su tarjeta RFID por el lector ESP32 ubicado en la entrada del colegio. El dispositivo envía una petición HTTP a la API Gateway de AWS con la API Key del alumno. La API invoca una función Lambda que registra la asistencia en DynamoDB con la hora exacta. Si el alumno llega tarde, se encola un evento en SQS y una Lambda notificadora publica una alerta en SNS, que envía un correo electrónico al padre o tutor.

El director puede registrar alumnos nuevos, listar alumnos y consultar el historial de asistencia desde una interfaz web alojada en S3 y distribuida por CloudFront. La autenticación de los usuarios del sistema se gestiona con Amazon Cognito. Todos los datos en DynamoDB están cifrados en reposo con una clave KMS propia del proyecto.

## Servicios AWS utilizados

| Servicio | Uso en el proyecto |
|---|---|
| **API Gateway** | Expone los endpoints REST del sistema |
| **Lambda** | Lógica de negocio sin servidor (5 funciones) |
| **DynamoDB** | Base de datos NoSQL para asistencias y alumnos |
| **Cognito** | Autenticación de usuarios del sistema |
| **SQS** | Cola de eventos para tardanzas |
| **SNS** | Notificaciones por correo electrónico |
| **KMS** | Cifrado en reposo de DynamoDB |
| **CloudWatch** | Monitoreo y logs |
| **IAM** | Roles y permisos de seguridad |

## Funciones Lambda

| Lambda | Método | Endpoint | Descripción |
|---|---|---|---|
| `registerStudent` | POST | `/students` | Registra un nuevo alumno en el sistema |
| `listStudents` | GET | `/students` | Lista todos los alumnos registrados |
| `attendance` | POST | `/api/asistencia/rfid/{id}` | Registra asistencia por lectura RFID |
| `manualAttendance` | POST | `/api/asistencia/manual/{id}` | Registra asistencia manualmente |
| `attendanceHistory` | GET | `/api/asistencias/alumno` | Consulta historial de asistencia de un alumno |

## Estructura del proyecto


