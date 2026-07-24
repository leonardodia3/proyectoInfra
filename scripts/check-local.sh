#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAMBDA_DIRS=(
  attendance
  attendanceHistory
  listStudents
  manualAttendance
  notifyAlert
  registerStudent
)

for lambda in "${LAMBDA_DIRS[@]}"; do
  echo "== Unit tests: lambdas/$lambda =="
  (
    cd "$ROOT_DIR/lambdas/$lambda"
    npm ci
    npm test -- --runInBand --coverage
  )
done

echo "== Integration tests =="
bash "$ROOT_DIR/scripts/check-integration-tests.sh"

echo "== JavaScript syntax check =="
find "$ROOT_DIR/lambdas" "$ROOT_DIR/local-deploy" "$ROOT_DIR/tests" \
  -name node_modules -prune -o \
  -name "*.js" -print0 |
  xargs -0 -n1 node --check

echo "== Terraform fmt and validate =="
(
  cd "$ROOT_DIR/terraform"
  terraform fmt -check -recursive
  terraform init -backend=false
  terraform validate
)

if [[ "${SKIP_CHECKOV:-false}" == "true" ]]; then
  exit 0
fi

echo "== Checkov IaC security scan =="
if command -v checkov >/dev/null 2>&1; then
  checkov -d "$ROOT_DIR/terraform" --framework terraform --quiet --compact
elif command -v uvx >/dev/null 2>&1; then
  uvx checkov -d "$ROOT_DIR/terraform" --framework terraform --quiet --compact
elif command -v docker >/dev/null 2>&1; then
  docker run --rm -v "$ROOT_DIR:/repo" bridgecrew/checkov:latest \
    -d /repo/terraform --framework terraform --quiet --compact
else
  echo "Checkov no esta instalado y no hay Docker/uvx disponible." >&2
  exit 1
fi
