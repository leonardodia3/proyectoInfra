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
  (
    cd "$ROOT_DIR/lambdas/$lambda"
    npm ci --omit=dev
  )
done
