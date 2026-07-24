# Sistema de Asistencia — Entorno Local con Docker

Este entorno te permite correr todo el sistema (base de datos, backend y frontend) en tu computadora, sin necesidad de desplegar en AWS ni tener credenciales reales.

## Qué incluye

- **dynamodb-local**: una versión de DynamoDB que corre en tu máquina (contenedor oficial de Amazon), en memoria.
- **backend**: un servidor Express que reutiliza la misma lógica de negocio de las Lambdas (`registrarAlumno`, `registrarAsistencia`, `procesarAlertaTardanza`, etc.), expuesta como endpoints REST normales.
- **frontend**: un panel web simple (HTML/CSS/JS, sin frameworks) para registrar alumnos, marcar asistencia, ver el historial, listar alumnos y eliminar perfiles.

## Qué NO se simula (limitación conocida)

- **Cognito** (autenticación): el panel local no pide login, cualquiera puede usarlo. Es solo para probar la lógica de negocio.
- **SNS real**: las notificaciones no se envían por correo real. En su lugar, el backend las imprime en su propia consola con el prefijo `[SNS simulado]`.
- **SQS real**: no se conecta a AWS. El backend simula el envío a la cola y procesa la alerta en memoria para que puedas ver el flujo completo en local.

Estas 3 cosas sí existen y están configuradas en Terraform para cuando despliegues a AWS real. Este entorno local es para probar rapido la logica de negocio sin desplegar.

## Requisitos

- Tener [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo en tu computadora.

## Cómo levantar todo

Desde esta carpeta (`local-deploy`), corre:

```bash
docker compose up -d --build dynamodb-local backend frontend
```

Esto va a:

1. Descargar e iniciar DynamoDB local (puerto 8000)
2. Construir e iniciar el backend (puerto 3000)
3. Construir e iniciar el frontend (puerto 8080)

Espera a que la terminal muestre `Backend escuchando en el puerto 3000` antes de continuar.

Para una demo completa con monitoreo incluido:

```bash
docker compose up -d --build dynamodb-local backend frontend prometheus grafana
```

## Cargar datos de prueba

**En una segunda terminal** (deja la anterior corriendo), ejecuta:

```bash
docker compose exec backend npm run seed
```

Esto crea la tabla `attendance` en DynamoDB local y carga:
- 3 alumnos de prueba (Juan Pérez, Ana Torres, Luis Ramírez)
- 2 registros de asistencia de ejemplo para Juan Pérez

## Usar el sistema

Abre tu navegador en:

```
http://localhost:8080
```

Desde ahí puedes:
- Registrar un alumno nuevo con DNI, datos del tutor y RFID
- Ver la lista de alumnos (botón "Actualizar lista")
- Eliminar el perfil de un alumno desde la tabla
- Marcar asistencia por RFID simulado o manual. Para RFID se usa el identificador de tarjeta, por ejemplo `RFID12345678`.
- Registrar asistencia manual con el DNI del alumno.
- Si la hora local ya pasó la hora límite, el RFID simulado genera una alerta de tardanza en la consola del backend.
- Consultar el historial de asistencia de ese mismo DNI

## Probar la API directamente (sin el frontend)

Con curl o Postman, apuntando a `http://localhost:3000`:

```bash
# Registrar alumno
curl -X POST http://localhost:3000/students \
  -H "Content-Type: application/json" \
  -d '{"dni":"99999999","name":"Prueba Test","email":"prueba@correo.com","classroom":"1ro A","rfid":"RFID99999999"}'

# Listar alumnos
curl http://localhost:3000/students

# Marcar asistencia
curl -X POST http://localhost:3000/attendance \
  -H "Content-Type: application/json" \
  -d '{"rfid":"RFID12345678"}'

# Historial de un alumno
curl http://localhost:3000/attendance/history/12345678

# Eliminar perfil de alumno
curl -X DELETE http://localhost:3000/students/99999999
```

## Apagar todo

```bash
docker compose down
```

Como DynamoDB local corre `-inMemory`, al apagar el contenedor **se pierden los datos** (tendrás que correr el seed de nuevo la próxima vez que levantes todo). Si quieres que los datos persistan entre reinicios, dime y te muestro cómo agregar un volumen.

## Monitoreo con Prometheus y Grafana

Para levantar tambien el monitoreo local:

```bash
docker compose up -d prometheus grafana
```

El backend expone sus propias métricas en `http://localhost:3000/metrics` (formato Prometheus), incluyendo:

- **`attendance_http_requests_total`**: cuántas peticiones recibió cada endpoint, y con qué código de respuesta (para medir tasa de errores).
- **`attendance_http_request_duration_seconds`**: cuánto tarda cada endpoint en responder (para medir latencia p95).
- **`attendance_registered_total`**: cuántas asistencias se registraron, separadas por método (RFID vs manual) — una métrica propia del negocio, no solo técnica.
- Métricas por defecto de Node.js (memoria, CPU, event loop).

**Prometheus** (puerto 9090) hace scraping de ese endpoint cada 5 segundos. Accede en:
```
http://localhost:9090
```
Ahí puedes escribir consultas directas, por ejemplo `attendance_registered_total` o `rate(attendance_http_requests_total[1m])`.

**Grafana** (puerto 3001) ya viene con Prometheus conectado como fuente de datos y un dashboard pre-cargado, sin que tengas que configurar nada a mano. Accede en:
```
http://localhost:3001
```
Usuario: `admin` — Contraseña: `admin` (o entra directo sin login, el acceso anónimo de solo lectura está habilitado). Busca el dashboard llamado **"Sistema de Asistencia — Backend"**.

El dashboard muestra: peticiones por segundo por endpoint, tasa de errores, latencia p95, asistencias registradas por método, uso de memoria, y total de peticiones en 24h.

**Para ver datos en el dashboard**, usa el panel del frontend (`localhost:8080`) para registrar alumnos y marcar asistencias — cada acción queda reflejada en Grafana en segundos.

### Nota sobre el alcance de esta implementación

Esto mide tu **backend local** (que reutiliza la misma lógica que tus Lambdas). En un despliegue real a AWS, el monitoreo nativo lo da CloudWatch (que ya tienes configurado en tu Terraform: logs, X-Ray, alarmas). Grafana tambien puede conectarse directamente a CloudWatch como fuente de datos adicional si quieres un panel unificado.

## Solución de problemas comunes

- **"Cannot connect to the Docker daemon"** → Abre Docker Desktop y espera a que termine de iniciar antes de correr el comando.
- **Puerto ocupado (3000, 8000 u 8080)** → Cierra cualquier otro programa usando esos puertos, o cambia el puerto en `docker-compose.yml` (por ejemplo `"3001:3000"`).
- **El frontend no carga los alumnos** → Verifica en la consola del navegador (F12) si hay errores de conexión; confirma que el backend esté corriendo con `docker compose ps`.
