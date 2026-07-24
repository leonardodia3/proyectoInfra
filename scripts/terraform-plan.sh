#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

: "${TF_VAR_alert_email:?Exporta TF_VAR_alert_email con un correo real antes de planificar.}"

bash "$ROOT_DIR/scripts/install-lambda-deps.sh"

terraform -chdir="$ROOT_DIR/terraform" fmt -check -recursive
terraform -chdir="$ROOT_DIR/terraform" init
terraform -chdir="$ROOT_DIR/terraform" validate
terraform -chdir="$ROOT_DIR/terraform" plan -out=tfplan
