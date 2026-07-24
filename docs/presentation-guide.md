# Guia de presentacion del proyecto

## Estado actual

El proyecto esta listo para presentarse en modo local y queda preparado para un despliegue AWS revisado con Terraform. La demo local no despliega recursos en AWS.

Incluye:

- Entorno local con Docker: DynamoDB Local, backend, frontend, Prometheus y Grafana.
- Infraestructura como codigo en Terraform para AWS: S3, CloudFront, API Gateway, Lambda, DynamoDB, Cognito, SQS, SNS, KMS, CloudWatch, WAF, IAM y firma de codigo.
- Checkov como control de seguridad IaC.
- SonarQube/SonarCloud como control de calidad.
- Pruebas unitarias por Lambda y pruebas de integracion del flujo de negocio.

## Flujo de negocio

1. El director registra un alumno con DNI, nombre, correo del tutor, salon y RFID.
2. El sistema valida que el DNI y el RFID no esten duplicados.
3. El alumno pasa su tarjeta RFID por el lector ESP32.
4. API Gateway recibe la lectura RFID. En AWS, el endpoint RFID usa API Key del dispositivo.
5. Lambda `attendance` busca el alumno por RFID en DynamoDB.
6. La asistencia queda guardada como `ASISTIO` o `TARDE`, segun la hora limite configurada.
7. Si la asistencia es tardia, Lambda encola un mensaje en SQS.
8. Lambda `notifyAlert` consume SQS y publica una alerta en SNS para notificar al tutor.
9. El director o vigilante puede registrar asistencia manual por DNI.
10. El historial permite ver las asistencias por alumno.

Este flujo tiene sentido para el diagrama porque separa:

- Entrada automatica: ESP32/RFID.
- Operacion humana: director/vigilante.
- Persistencia: DynamoDB.
- Alertas asincronas: SQS + SNS.
- Seguridad: API Key para dispositivo, Cognito para usuarios, KMS/IAM/WAF para AWS.
- Observabilidad: CloudWatch/X-Ray en AWS, Prometheus/Grafana en local.

## Grafana

Grafana no falta. Ya esta incluido en `local-deploy/docker-compose.yml` y se provisiona automaticamente con:

- Datasource Prometheus.
- Dashboard `Sistema de Asistencia - Backend`.
- Metricas de peticiones, errores, latencia p95, asistencias por metodo y memoria.

Para presentarlo:

```bash
cd local-deploy
docker compose up -d --build dynamodb-local backend frontend prometheus grafana
docker compose exec -T backend npm run seed
```

Luego abre:

- Frontend: `http://localhost:8080`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001`

Para que Grafana muestre datos, registra alumnos y asistencias desde el frontend o ejecuta llamadas `curl`.

En el panel local la asistencia automatica usa el campo RFID. La asistencia manual usa el DNI. Esta separacion es importante para que la demo coincida con el flujo del ESP32.

## Quality gates

El workflow `.github/workflows/sonarqube.yml` muestra pasos separados para:

- Unit, integration and Terraform validation.
- Checkov IaC security scan.
- SonarQube Cloud analysis.

Localmente se corre:

```bash
bash scripts/check-local.sh
```

Ese comando ejecuta:

- Pruebas unitarias por Lambda.
- Pruebas de integracion.
- Chequeo de sintaxis JavaScript.
- `terraform fmt -check`.
- `terraform validate`.
- Checkov.

## Despliegue AWS

Para revisar el despliegue sin aplicarlo:

```bash
export TF_VAR_alert_email="tu-correo@dominio.com"
bash scripts/terraform-plan.sh
```

El plan crea el frontend en S3 + CloudFront y genera `config.js` con API Gateway y Cognito. Despues de aplicar manualmente se debe confirmar el correo SNS, crear un usuario Cognito y obtener el valor real de la API Key del ESP32.

## Que quedaria fuera de alcance

Para una produccion mas completa todavia se podria agregar:

- Dominio propio con Route 53 y certificado ACM.
- Grafana conectado a CloudWatch si se quiere un tablero unico de produccion.
- Gestion de usuarios Cognito con un proceso administrativo formal.
