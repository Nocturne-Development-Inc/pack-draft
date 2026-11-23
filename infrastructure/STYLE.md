# Terraform style guide

Rules for code under `infrastructure/`. Run `pnpm infra:fmt` before opening a PR. `pnpm infra:lint` must pass.

## Layout

| Path | Role |
| --- | --- |
| `environments/<name>/` | Root module for one AWS account / environment |
| `modules/<name>/` | Shared building blocks called from environments |
| `scripts/` | Lint, format, validate, plan, apply |

In each environment root, keep files small and named by concern:

- `versions.tf` — required Terraform and provider versions
- `providers.tf` — provider blocks and `default_tags`
- `backend.tf` — remote state only
- `variables.tf` — input variables
- `outputs.tf` — outputs
- `main.tf` — composition (module calls and locals)
- `*.tf` — one file per domain when `main.tf` grows (`network.tf`, `database.tf`, `app.tf`)

Do not put resources in `modules/` that only one environment will ever use. Put those in the environment root.

## Formatting

- Indent with two spaces. Never tabs.
- Always run `terraform fmt -recursive`.
- One argument or attribute per line when a block has more than one.
- Put a blank line between top-level blocks. No blank line between a block type and its first argument.

```hcl
resource "aws_security_group" "api" {
  name   = "${local.name_prefix}-api"
  vpc_id = module.network.vpc_id

  tags = {
    Name = "${local.name_prefix}-api"
  }
}
```

## Naming

- Use `snake_case` for every Terraform identifier: resources, data sources, modules, variables, locals, outputs.
- Resource names describe the role, not the type: `aws_s3_bucket.terraform_state`, not `aws_s3_bucket.s3_bucket`.
- AWS `Name` tags and physical names use `${var.project_name}-${var.environment}-…` via `local.name_prefix`.
- Module sources are relative paths: `source = "../../modules/network"`.

## Variables and outputs

- Every variable and output has `type` and `description`.
- Prefer explicit types (`string`, `number`, `bool`, `list(string)`, `map(string)`, objects) over `any`.
- Defaults are fine for non-secret, environment-safe values. Secrets never get defaults in `.tf` files.
- Pass secrets with `TF_VAR_*` from `.env` or a secrets manager. Do not commit them in `*.tfvars`.
- Validate enums with a `validation` block when the set is small (`staging` / `production`).
- Mark sensitive outputs with `sensitive = true`.

## Modules

- One concern per module. A module that creates a VPC and an RDS instance is two modules.
- Expose only the outputs callers need. Prefer IDs and ARNs over whole resource objects.
- Pin module versions when the source is a registry or git tag. Relative path modules move with the repo.
- Do not reach into another module’s resources with a remote state data source when you can pass an output.

## Providers and tags

- Set `required_version` and `required_providers` in every root module.
- Configure the AWS provider once per root. Put shared tags in `default_tags`.
- Always include `Project`, `Environment`, and `ManagedBy = "terraform"`.
- Do not hard-code account IDs in modules. Pass them as variables or read them with `data "aws_caller_identity"`.

## State and environments

- Staging and production are separate roots under `environments/`, in separate AWS accounts (ADR-002).
- Never share a state file across environments.
- Remote state uses S3 with encryption and DynamoDB locking once the bootstrap exists.
- Plan before apply. Prefer `pnpm infra:plan` then `pnpm infra:apply` with the saved `tfplan`.

## What not to do

- No counted `count` indexes in resource names when `for_each` with a stable key works.
- No inline IAM policy JSON when `aws_iam_policy_document` can build it.
- No hard-coded Availability Zone names when `data "aws_availability_zones"` works.
- No `terraform destroy` against production without an explicit, human-confirmed reason.
