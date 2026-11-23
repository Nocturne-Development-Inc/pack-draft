# Terraform modules

Shared modules for staging and production. ADR-002 starts with three:

| Module | Owns |
| --- | --- |
| `network` | VPC, subnets, security groups, NAT (production) |
| `database` | RDS for PostgreSQL, subnet group, parameter group |
| `app` | ECS cluster, Express Mode API service, worker, ECR, IAM roles |

Add a module when two environments need the same resource shape. Keep environment-specific values in `environments/<name>/`.

## Tooling (macOS and Windows)

Module `.tf` files are the same on every OS. Install Terraform (and optional tflint) on your machine, then plan/apply from an environment root.

- **macOS:** Homebrew or tfenv — see [infrastructure/README.md](../README.md).
- **Windows:** Chocolatey, Scoop, or a manual zip on `PATH` — see [infrastructure/README.md](../README.md).

Run fmt/lint/plan from the **repo root** (`pnpm infra:*`) on either platform. Shell helpers under `infrastructure/scripts/` are bash; on Windows use Git Bash, WSL, or run `terraform` directly in `environments/<name>/`.
