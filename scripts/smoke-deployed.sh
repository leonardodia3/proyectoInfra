#!/usr/bin/env bash
set -euo pipefail

: "${API_URL:?Exporta API_URL con terraform output -raw api_url.}"
: "${COGNITO_ID_TOKEN:?Exporta COGNITO_ID_TOKEN con un token valido de Cognito.}"
: "${ESP32_API_KEY:?Exporta ESP32_API_KEY con el valor real de la API Key.}"

DNI="${DNI:-99000001}"
RFID="${RFID:-RFID99000001}"

curl_json() {
  local method="$1"
  local path="$2"
  local body="${3:-}"
  shift 3 || true

  if [[ -n "$body" ]]; then
    curl -fsS -X "$method" "$API_URL$path" \
      -H "Content-Type: application/json" \
      "$@" \
      -d "$body"
  else
    curl -fsS -X "$method" "$API_URL$path" \
      -H "Content-Type: application/json" \
      "$@"
  fi
}

curl_json DELETE "/students/$DNI" "" -H "Authorization: $COGNITO_ID_TOKEN" >/dev/null || true

curl_json POST "/students" \
  "{\"dni\":\"$DNI\",\"name\":\"Alumno Smoke\",\"email\":\"familia-smoke@example.com\",\"classroom\":\"5to C\",\"rfid\":\"$RFID\"}" \
  -H "Authorization: $COGNITO_ID_TOKEN"
printf "\n"

curl_json GET "/students" "" -H "Authorization: $COGNITO_ID_TOKEN"
printf "\n"

curl_json POST "/attendance" "{\"rfid\":\"$RFID\"}" -H "x-api-key: $ESP32_API_KEY"
printf "\n"

curl_json POST "/attendance/manual" "{\"dni\":\"$DNI\"}" -H "Authorization: $COGNITO_ID_TOKEN"
printf "\n"

curl_json GET "/attendance/history/$DNI" "" -H "Authorization: $COGNITO_ID_TOKEN"
printf "\n"
