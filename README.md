# proyectoInfra - Sistema de Control de Asistencia Escolar con RFID

Sistema de asistencia escolar con dos modos de ejecucion:

- **Local con Docker**: DynamoDB Local, backend Express, frontend web, Prometheus y Grafana.
- **AWS con Terraform**: frontend estatico en S3 + CloudFront, API Gateway, Cognito, Lambda, DynamoDB, SQS, SNS, KMS, CloudWatch, WAF, IAM y firma de codigo.

El flujo de negocio queda separado asi:

1. El director registra alumnos con DNI, nombre, correo del tutor, salon y RFID.
2. El ESP32 envia lecturas RFID al endpoint `/attendance` usando API Key.
3. Lambda `attendance` busca el alumno por RFID y registra la asistencia en DynamoDB.
4. Si la lectura llega despues de la hora limite, se encola una tardanza en SQS.
5. Lambda `notifyAlert` consume la cola y publica la alerta por SNS.
6. Director o vigilante registran asistencia manual por DNI en `/attendance/manual`.
7. El historial se consulta por DNI en `/attendance/history/{dni}`.

## Probar en local

```bash
cd local-deploy
docker compose up -d --build dynamodb-local backend frontend prometheus grafana
docker compose exec -T backend npm run seed
```

Abre:

- Panel web: `http://localhost:8080`
- API local: `http://localhost:3000`
- Metricas backend: `http://localhost:3000/metrics`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001`

Para apagar:

```bash
cd local-deploy
docker compose down
```

## Revisar antes de desplegar

```bash
bash scripts/check-local.sh
```

Ese comando ejecuta:

- Tests unitarios de cada Lambda.
- Tests de integracion del flujo de negocio.
- Chequeo de sintaxis JavaScript.
- `terraform fmt -check`.
- `terraform validate`.
- Checkov.

El workflow `.github/workflows/sonarqube.yml` muestra gates separados de tests, Terraform, **Checkov** y **SonarQube/SonarCloud**. En GitHub debes configurar el secret `SONAR_TOKEN`.

## Preparar despliegue AWS

No ejecutes `apply` sin revisar el plan. Primero configura credenciales AWS y un correo real para SNS:

```bash
export TF_VAR_alert_email="tu-correo@dominio.com"
bash scripts/terraform-plan.sh
```

Si el plan es correcto, el despliegue se haria manualmente con:

```bash
terraform -chdir=terraform apply tfplan
```

Despues del `apply`:

1. Confirma el correo de SNS que llega a `TF_VAR_alert_email`.
2. Crea un usuario Cognito para el panel.
3. Obtén el valor real de la API Key del ESP32.
4. Abre `terraform -chdir=terraform output -raw frontend_url`.

Comandos utiles:

```bash
USER_POOL_ID="$(terraform -chdir=terraform output -raw cognito_user_pool_id)"
CLIENT_ID="$(terraform -chdir=terraform output -raw cognito_client_id)"
API_KEY_ID="$(terraform -chdir=terraform output -raw esp32_api_key_id)"

aws cognito-idp admin-create-user \
  --user-pool-id "$USER_POOL_ID" \
  --username director@colegio.com \
  --user-attributes Name=email,Value=director@colegio.com Name=email_verified,Value=true

aws cognito-idp admin-set-user-password \
  --user-pool-id "$USER_POOL_ID" \
  --username director@colegio.com \
  --password "CambiaEstaClave123" \
  --permanent

aws apigateway get-api-key \
  --api-key "$API_KEY_ID" \
  --include-value \
  --query value \
  --output text
```

Para probar una API ya desplegada desde terminal:

```bash
export API_URL="$(terraform -chdir=terraform output -raw api_url)"
export COGNITO_ID_TOKEN="$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id "$CLIENT_ID" \
  --auth-parameters USERNAME=director@colegio.com,PASSWORD=CambiaEstaClave123 \
  --query AuthenticationResult.IdToken \
  --output text)"
export ESP32_API_KEY="valor-real-de-la-api-key"

bash scripts/smoke-deployed.sh
```

## Diagrama

El diagrama actualizado en codigo Eraser.io esta en [`docs/diagram-eraser.io`](docs/diagram-eraser.io).
La guia exacta para subir el proyecto a GitHub, credenciales de prueba y comandos Windows/Linux esta en [`docs/github-upload-and-usage.md`](docs/github-upload-and-usage.md).

## Servicios AWS

| Servicio | Uso |
|---|---|
| S3 + CloudFront | Publica el panel web estatico |
| API Gateway | Expone endpoints REST |
| Cognito | Autenticacion del director/vigilante |
| Lambda | Logica de negocio |
| DynamoDB | Alumnos y asistencias |
| SQS | Cola asincrona de tardanzas |
| SNS | Alertas por correo |
| KMS | Cifrado de DynamoDB, SQS, SNS, logs y S3 |
| CloudWatch + X-Ray | Logs, metricas, trazas y alarmas |
| WAF | Proteccion regional de API Gateway |
| IAM | Permisos de minimo privilegio |

## Estructura

| Ruta | Contenido |
|---|---|
| `terraform/` | Infraestructura AWS como codigo |
| `lambdas/` | Funciones Lambda y tests unitarios |
| `local-deploy/` | Entorno Docker local |
| `tests/integration/` | Tests de integracion |
| `scripts/` | Checks, plan Terraform y smoke test desplegado |
| `docs/` | Guia de presentacion y diagrama |
