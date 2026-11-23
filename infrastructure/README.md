# Infrastructure

AWS infrastructure for Pack Draft, defined in Terraform ([ADR-002](../docs/decisions/002-cloud-provider.md), [ADR-003](../docs/decisions/003-api-runtime-and-compute.md)).

```
infrastructure/
  environments/staging/   Root module (scaffold)
  modules/                Shared modules (network, database, app — next)
  scripts/                fmt, lint, validate, plan, apply
  STYLE.md                Terraform style guide
  .env.example            Copy to .env for local plan/apply
```

## Prerequisites

- Terraform **1.17.2** or newer (`.terraform-version` is read by tfenv / similar tools)
- AWS credentials for the target account
- Optional: [tflint](https://github.com/terraform-linters/tflint)
- Repo root tools (Node, pnpm, Safe Chain) if you run commands via `pnpm infra:*` — see [root README](../README.md)

### macOS

```sh
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install --cask terraform-linters/tap/tflint
terraform version   # expect 1.17.2+
tflint --version
```

Or use [tfenv](https://github.com/tfutils/tfenv) with the pin in `.terraform-version`.

### Windows

**Option A — winget / Chocolatey (PowerShell as Administrator)**

```powershell
winget install -e --id Hashicorp.Terraform
winget install -e --id TerraformLinters.tflint
terraform version
tflint --version
```

Or with Chocolatey: `choco install terraform` (tflint may need winget or a [manual zip](https://github.com/terraform-linters/tflint/releases)).

**Option B — Scoop**

```powershell
scoop bucket add hashicorp https://github.com/hashicorp/scoop-bucket.git
scoop install terraform
# tflint: use winget or a release zip from GitHub
terraform version
```

**Option C — Manual**

1. Download Terraform **1.17.2** for Windows from [HashiCorp releases](https://releases.hashicorp.com/terraform/) (AMD64 zip).
2. Unzip and put `terraform.exe` on your `PATH`.
3. Download [tflint releases](https://github.com/terraform-linters/tflint/releases) the same way if you want lint.

Configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) or set `AWS_PROFILE` / keys in `.env` (next section).

## Configure

**macOS / Linux**

```sh
cp infrastructure/.env.example infrastructure/.env
# Edit AWS_PROFILE, AWS_REGION, TF_ENV
```

**Windows (PowerShell)**

```powershell
Copy-Item infrastructure\.env.example infrastructure\.env
# Edit AWS_PROFILE, AWS_REGION, TF_ENV in your editor
```

Scripts load `infrastructure/.env` before plan and apply. `.env` is gitignored.

## Commands

From the **repo root** (bash or PowerShell — same `pnpm` commands):

| Command | What it does |
| --- | --- |
| `pnpm infra:fmt` | `terraform fmt -recursive` |
| `pnpm infra:lint` | fmt check + tflint |
| `pnpm infra:validate` | `terraform init -backend=false` + `validate` |
| `pnpm infra:plan` | init + plan → `tfplan` (the “build”) |
| `pnpm infra:apply` | apply saved `tfplan`, or interactive apply |
| `pnpm infra:check` | lint + validate |

Or call the scripts directly:

**macOS / Linux:** `./infrastructure/scripts/plan.sh`  
**Windows (Git Bash or WSL):** same paths. From PowerShell without bash, run Terraform yourself from `infrastructure\environments\staging` after loading `.env` values into the session.

`TF_ENV` (default `staging`) selects `environments/<name>/`.

VS Code / Cursor: **Tasks: Run Task** → `infra:*`.

## Current state

Staging is a provider + variables scaffold only. Next modules: network, RDS, ECS (Express Mode API + worker). State stays local until you copy `backend.tf.example` over `backend.tf` and create the S3 bucket and DynamoDB lock table.
