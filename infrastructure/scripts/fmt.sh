#!/usr/bin/env bash
# Format all Terraform files under infrastructure/.

set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

require_terraform
terraform fmt -recursive "${INFRA_ROOT}"
echo "terraform fmt: ok"
