#!/usr/bin/env bash
# Build a Terraform plan for the selected environment (reads infrastructure/.env).

set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

load_env
require_terraform
cd_env

PLAN_FILE="${PLAN_FILE:-tfplan}"

echo "==> terraform init"
terraform init -input=false

echo "==> terraform plan"
terraform plan -input=false -out="${PLAN_FILE}"

echo "Wrote plan: $(pwd)/${PLAN_FILE}"
