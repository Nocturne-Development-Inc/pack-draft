#!/usr/bin/env bash
# Shared helpers for infrastructure scripts. Source this file; do not run it.

set -euo pipefail

INFRA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${INFRA_ROOT}/.env"

load_env() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Missing ${ENV_FILE}." >&2
    echo "Copy infrastructure/.env.example to infrastructure/.env and fill it in." >&2
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
}

require_terraform() {
  if ! command -v terraform >/dev/null 2>&1; then
    echo "terraform not found on PATH. Install Terraform ${REQUIRED_TF_VERSION:-1.17.2}+ (see infrastructure/README.md)." >&2
    exit 1
  fi

  local version
  version="$(terraform version -json 2>/dev/null | sed -n 's/.*"terraform_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  if [[ -z "${version}" ]]; then
    version="$(terraform version | head -n1 | awk '{print $2}' | sed 's/^v//')"
  fi

  REQUIRED_TF_VERSION="$(tr -d '[:space:]' < "${INFRA_ROOT}/.terraform-version")"
  if [[ "$(printf '%s\n' "${REQUIRED_TF_VERSION}" "${version}" | sort -V | head -n1)" != "${REQUIRED_TF_VERSION}" ]]; then
    echo "Terraform ${version} is older than required ${REQUIRED_TF_VERSION}." >&2
    exit 1
  fi
}

env_dir() {
  local name="${TF_ENV:-staging}"
  local dir="${INFRA_ROOT}/environments/${name}"
  if [[ ! -d "${dir}" ]]; then
    echo "Unknown TF_ENV=${name}. Expected a folder under infrastructure/environments/." >&2
    exit 1
  fi
  printf '%s' "${dir}"
}

cd_env() {
  cd "$(env_dir)"
}
