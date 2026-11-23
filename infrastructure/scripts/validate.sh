#!/usr/bin/env bash
# Init providers (no backend) and validate the selected environment.

set -euo pipefail
# shellcheck source=_lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib.sh"

load_env
require_terraform
cd_env

echo "==> terraform init -backend=false"
terraform init -backend=false -input=false

echo "==> terraform validate"
terraform validate

echo "infra validate: ok"
