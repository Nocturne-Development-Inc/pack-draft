#!/usr/bin/env bash
# Apply a saved plan (default: tfplan) or run an interactive apply.

set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

load_env
require_terraform
cd_env

PLAN_FILE="${PLAN_FILE:-tfplan}"

echo "==> terraform init"
terraform init -input=false

if [[ -f "${PLAN_FILE}" ]]; then
  echo "==> terraform apply ${PLAN_FILE}"
  terraform apply -input=false "${PLAN_FILE}"
else
  echo "No ${PLAN_FILE} found; running interactive apply."
  terraform apply
fi
