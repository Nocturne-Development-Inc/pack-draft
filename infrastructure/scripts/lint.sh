#!/usr/bin/env bash
# Check Terraform formatting and run tflint when installed.

set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

require_terraform
cd_env

echo "==> terraform fmt -check"
terraform fmt -check -recursive "${INFRA_ROOT}"

if command -v tflint >/dev/null 2>&1; then
  echo "==> tflint --init"
  tflint --chdir="${INFRA_ROOT}" --init
  echo "==> tflint"
  tflint --chdir="$(pwd)" --config="${INFRA_ROOT}/.tflint.hcl"
else
  echo "tflint not found; skipped. Install with: brew install tflint"
fi

echo "infra lint: ok"
