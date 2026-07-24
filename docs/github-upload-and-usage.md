# Guia para subir y usar el proyecto

Esta guia deja claro que se debe subir a GitHub, que no se debe subir, como autenticarte desde Windows y como probar el sistema en local o preparar un despliegue AWS sin publicar secretos.

## Estado actual del repositorio

- Rama local: `main`.
- Remote configurado: `origin https://github.com/leonardodia3/proyectoInfra.git`.
- El workflow de calidad esta en `.github/workflows/sonarqube.yml` y ejecuta tests, Terraform, Checkov y SonarQube Cloud.
- El diagrama Eraser.io actualizado esta en `docs/diagram-eraser.io`.
- Grafana esta incluido solo para el entorno local Docker. En AWS la observabilidad del codigo actual se hace con CloudWatch, alarmas y X-Ray.

## Que si debes subir

Sube estos archivos y carpetas:

- `.github/workflows/sonarqube.yml`: pipeline de GitHub Actions con Checkov y SonarQube.
- `.gitignore`: evita subir dependencias, estados Terraform, planes, secretos y evidencia local.
- `README.md`: guia principal del proyecto.
- `docs/`: diagrama Eraser.io, guia de presentacion y esta guia.
- `terraform/`: infraestructura AWS como codigo, incluyendo `terraform/.terraform.lock.hcl`.
- `lambdas/`: codigo de Lambdas, `package.json`, `package-lock.json` y tests unitarios.
- `local-deploy/`: entorno Docker local, backend, frontend, Prometheus y Grafana.
- `scripts/`: scripts de checks, plan Terraform y smoke test de AWS.
- `tests/integration/`: test de integracion del flujo de negocio.
- `package.json` y `package-lock.json` de la raiz.
- `sonar-project.properties`: configuracion del analisis SonarQube Cloud.
- `.vscode/settings.json` puede quedarse si quieres que SonarLint abra conectado al proyecto `leonardodia3_proyectoInfra`; no contiene secretos.

## Que no debes subir

No subas esto:

- `node_modules/` en cualquier carpeta.
- `coverage/` en cualquier carpeta.
- `build/` y archivos `.zip` generados por empaquetado local.
- `terraform/.terraform/`.
- `*.tfstate` y `*.tfstate.*`.
- `tfplan`, `*.tfplan` o cualquier plan Terraform.
- `.env`, `.env.*` o archivos con variables locales.
- `.omo/` y `local-deploy/.omo/`; son evidencia local del trabajo, no parte del proyecto.
- Credenciales AWS, tokens de GitHub, `SONAR_TOKEN`, API Keys reales, claves privadas, certificados o passwords reales.

## Comandos para subir desde Linux o Git Bash

Ejecuta desde la raiz del repo:

```bash
cd /home/rodrigo/Escritorio/Codigos/proyectoInfra

git status --short --ignored
git add .github .gitignore README.md docs terraform lambdas local-deploy scripts tests sonar-project.properties package.json package-lock.json .vscode

git status --short
git diff --cached --name-only
git diff --cached --name-status | grep -E '^[AMR]' | grep -E '(^|[[:space:]]|/)(node_modules|coverage|\.terraform|\.omo)/|(^|[[:space:]]|/)\.env($|\.)|(\.tfstate|\.tfplan|\.pem|\.key|\.crt|\.p12|\.pfx)$' || true

git commit -m "Prepare IaC attendance project for local and AWS deployment"
git branch -M main
git remote -v
git push -u origin main
```

Si el remote no existiera, agregalo asi:

```bash
git remote add origin https://github.com/leonardodia3/proyectoInfra.git
```

Si el remote apunta a otro lugar, corrigelo asi:

```bash
git remote set-url origin https://github.com/leonardodia3/proyectoInfra.git
```

## Comandos para subir desde Windows PowerShell

Abre PowerShell o Windows Terminal en la carpeta del proyecto:

```powershell
cd C:\Users\TU_USUARIO\Desktop\Codigos\proyectoInfra

git config --global user.name "Tu Nombre"
git config --global user.email "tu-correo@dominio.com"

git status --short --ignored
git add .github .gitignore README.md docs terraform lambdas local-deploy scripts tests sonar-project.properties package.json package-lock.json .vscode

git status --short
git diff --cached --name-only
git diff --cached --name-status | Select-String -Pattern '^[AMR]' | Select-String -Pattern '(^|\s|/)(node_modules|coverage|\.terraform|\.omo)/|(^|\s|/)\.env($|\.)|(\.tfstate|\.tfplan|\.pem|\.key|\.crt|\.p12|\.pfx)$'

git commit -m "Prepare IaC attendance project for local and AWS deployment"
git branch -M main
git remote -v
git push -u origin main
```

Si el remote no existiera:

```powershell
git remote add origin https://github.com/leonardodia3/proyectoInfra.git
```

Si el remote apunta a otro repositorio:

```powershell
git remote set-url origin https://github.com/leonardodia3/proyectoInfra.git
```

Si por error agregaste algo que no debe subirse y aparece con estado `A` o `M`:

```powershell
git restore --staged -- ":(glob)**/node_modules/**" ":(glob)**/coverage/**" ":(glob)**/.terraform/**" ":(glob)**/.omo/**" ":(glob)**/*.tfstate*" ":(glob)**/*.tfplan" ":(glob)**/.env" ":(glob)**/.env.*" build
```

Si aparece con estado `D` dentro de `node_modules/`, normalmente esta bien: significa que Git va a dejar de versionar dependencias que no debieron estar en el repositorio.

## Credenciales para GitHub

Para hacer `git push` por HTTPS, no uses tu password de GitHub. Usa una de estas opciones:

- Recomendado en Windows: instala Git for Windows actualizado. Ya incluye Git Credential Manager; al hacer `git push` abre login en navegador y guarda la sesion en Windows Credential Manager.
- Alternativa: crea un Personal Access Token. Para este repo usa un token fine-grained limitado a `leonardodia3/proyectoInfra`, con `Contents: Read and write`. Si usas token classic, GitHub indica usar scope `repo` para operaciones Git por linea de comandos.
- Alternativa SSH: agrega una llave SSH publica a GitHub y cambia el remote a `git@github.com:leonardodia3/proyectoInfra.git`.

Comandos SSH en Windows PowerShell:

```powershell
ssh-keygen -t ed25519 -C "tu-correo@dominio.com"
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
git remote set-url origin git@github.com:leonardodia3/proyectoInfra.git
git push -u origin main
```

## Secret de SonarQube Cloud

En GitHub crea este secret:

```text
SONAR_TOKEN=token-real-de-sonarqube
```

Ruta en GitHub:

```text
Repositorio -> Settings -> Secrets and variables -> Actions -> New repository secret
```

No subas el token al repo. El workflow lo lee como `${{ secrets.SONAR_TOKEN }}`.

## Probar en local con Docker

Linux, Git Bash o PowerShell:

```bash
cd local-deploy
docker compose up -d --build dynamodb-local backend frontend prometheus grafana
docker compose exec -T backend npm run seed
```

URLs locales:

- Frontend: `http://localhost:8080`
- Backend API: `http://localhost:3000`
- Metricas backend: `http://localhost:3000/metrics`
- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:3001`

Credenciales locales:

- Frontend local: no usa login Cognito.
- Grafana local: usuario `admin`, password `admin`.
- DynamoDB Local: usa credenciales falsas `local/local` dentro del contenedor; no son credenciales reales.

Alumnos de prueba cargados por `npm run seed`:

| Nombre | DNI | RFID | Salon | Correo |
|---|---|---|---|---|
| Juan Perez | `12345678` | `RFID12345678` | `5to C` | `juan@correo.com` |
| Ana Torres | `87654321` | `RFID87654321` | `4to B` | `ana@correo.com` |
| Luis Ramirez | `11223344` | `RFID11223344` | `5to C` | `luis@correo.com` |

Pruebas rapidas con `curl`:

```bash
curl http://localhost:3000/health
curl http://localhost:3000/students
curl -X POST http://localhost:3000/attendance -H "Content-Type: application/json" -d '{"rfid":"RFID12345678"}'
curl -X POST http://localhost:3000/attendance/manual -H "Content-Type: application/json" -d '{"dni":"87654321"}'
curl http://localhost:3000/attendance/history/12345678
```

Equivalente PowerShell:

```powershell
Invoke-RestMethod http://localhost:3000/health
Invoke-RestMethod http://localhost:3000/students
Invoke-RestMethod -Method Post -Uri http://localhost:3000/attendance -ContentType "application/json" -Body '{"rfid":"RFID12345678"}'
Invoke-RestMethod -Method Post -Uri http://localhost:3000/attendance/manual -ContentType "application/json" -Body '{"dni":"87654321"}'
Invoke-RestMethod http://localhost:3000/attendance/history/12345678
```

Para apagar:

```bash
cd local-deploy
docker compose down
```

## Checks antes del commit

En Linux, WSL o Git Bash:

```bash
bash scripts/check-local.sh
```

Si todavia no tienes Checkov instalado y quieres revisar primero los tests sin Checkov:

```bash
SKIP_CHECKOV=true bash scripts/check-local.sh
```

Checkov directo:

```bash
checkov -d terraform --framework terraform --quiet --compact
```

## Preparar despliegue AWS sin desplegar

Requisitos en tu maquina:

- AWS CLI configurado con una cuenta que pueda crear los recursos del proyecto.
- Terraform instalado.
- Git Bash o WSL en Windows para ejecutar los scripts `.sh`.
- Un correo real para `TF_VAR_alert_email`; SNS enviara la confirmacion ahi despues del `apply`.

Linux o Git Bash:

```bash
export TF_VAR_alert_email="tu-correo@dominio.com"
bash scripts/terraform-plan.sh
```

Windows PowerShell:

```powershell
$env:TF_VAR_alert_email="tu-correo@dominio.com"
bash scripts/terraform-plan.sh
```

Eso solo prepara y revisa el plan. El despliegue real seria:

```bash
terraform -chdir=terraform apply tfplan
```

No ejecutes `apply` hasta revisar el plan y confirmar costos/permisos.

## Credenciales para AWS desplegado

No hay usuario por defecto en Cognito. Despues de aplicar Terraform, crea uno:

Linux o Git Bash:

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

Windows PowerShell:

```powershell
$USER_POOL_ID = terraform -chdir=terraform output -raw cognito_user_pool_id
$CLIENT_ID = terraform -chdir=terraform output -raw cognito_client_id
$API_KEY_ID = terraform -chdir=terraform output -raw esp32_api_key_id

aws cognito-idp admin-create-user --user-pool-id $USER_POOL_ID --username director@colegio.com --user-attributes Name=email,Value=director@colegio.com Name=email_verified,Value=true
aws cognito-idp admin-set-user-password --user-pool-id $USER_POOL_ID --username director@colegio.com --password "CambiaEstaClave123" --permanent
aws apigateway get-api-key --api-key $API_KEY_ID --include-value --query value --output text
```

Para presentacion puedes usar:

- Usuario Cognito de prueba: `director@colegio.com`
- Password de prueba: `CambiaEstaClave123`
- API Key ESP32: la devuelve `aws apigateway get-api-key`; no se escribe en GitHub.

Cambia ese password si el entorno sera real.

## Usar el frontend desplegado

Despues del `apply`:

```bash
terraform -chdir=terraform output -raw frontend_url
```

Entra al URL. El panel desplegado usa Cognito para login. Para simular el ESP32 desde el navegador o terminal, usa la API Key recuperada con AWS CLI. En un ESP32 real, la API Key debe guardarse en el firmware/configuracion del dispositivo, nunca en GitHub.

Smoke test de AWS ya desplegado:

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

## Diagrama Eraser.io

El codigo completo y actualizado esta en:

```text
docs/diagram-eraser.io
```

Para verlo desde Windows PowerShell:

```powershell
Get-Content .\docs\diagram-eraser.io
```

Para verlo desde Linux o Git Bash:

```bash
cat docs/diagram-eraser.io
```

Ese diagrama representa el codigo actual: local con Docker, frontend AWS en S3/CloudFront, API Gateway, Cognito, API Key para ESP32, Lambdas, DynamoDB, SQS, SNS, KMS, CloudWatch, WAF, Prometheus y Grafana local.

## Fuentes GitHub usadas para esta guia

- GitHub Docs: `git remote add`, `git remote set-url` y verificacion con `git remote -v`: https://docs.github.com/en/get-started/git-basics/managing-remote-repositories
- GitHub Docs: `git push origin main`: https://docs.github.com/en/get-started/using-git/pushing-commits-to-a-remote-repository
- GitHub Docs: uso de Personal Access Token en lugar de password para HTTPS: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
- GitHub Docs: Git Credential Manager en Windows: https://docs.github.com/en/get-started/git-basics/caching-your-github-credentials-in-git
- GitHub Docs: agregar llave SSH a GitHub: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account
