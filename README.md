# pack-draft

pnpm monorepo.

```
apps/
  api/      Fastify + Zod API (TypeScript, ESM)
  mobile/   Expo / React Native app (iOS + Android)
infrastructure/  Terraform (AWS staging scaffold)
packages/   Shared packages (empty for now)
docs/       Architecture decision records
scope/      Project scope and tracking
```

## Requirements

| Tool | Notes |
| --- | --- |
| Node 22+ | `.nvmrc` pins 24 |
| pnpm 10 | `corepack enable` picks the version from `package.json` |
| Docker | Local Postgres for the API |
| Aikido Safe Chain | Required for `pnpm` / `npm` installs (see below) |
| Terraform 1.17.2+ | Only for infrastructure work — [infrastructure/README.md](infrastructure/README.md) |

### macOS

1. Install [Node](https://nodejs.org/) (or `nvm` / `fnm`), then enable Corepack:

   ```sh
   corepack enable
   ```

2. Install [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/).
3. Mobile (optional): Xcode for the iOS simulator and/or Android Studio for an emulator, or Expo Go on a device.
4. Install Safe Chain (next section).

### Windows

1. Install [Node](https://nodejs.org/) (or [nvm-windows](https://github.com/coreybutler/nvm-windows) / fnm), then in **PowerShell**:

   ```powershell
   corepack enable
   ```

2. Install [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/). Use WSL2 when Docker asks.
3. Mobile (optional): Android Studio for an emulator, or Expo Go on a device. iOS simulators need a Mac.
4. Install Safe Chain (next section). If PowerShell blocks profiles, run as Administrator once:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
   ```

## Aikido Safe Chain

Safe Chain wraps `pnpm`, `npm`, and other package managers so malware and brand-new packages are blocked before they land on your machine. This repo expects it to be installed. Do **not** bypass age checks with `--safe-chain-skip-minimum-package-age`.

Install from a [versioned release](https://github.com/AikidoSec/safe-chain/releases) (example: **1.5.27**). Check the [npm package page](https://www.npmjs.com/package/@aikidosec/safe-chain) for newer install commands and checksums.

### macOS / Linux

```sh
curl -fsSL https://github.com/AikidoSec/safe-chain/releases/download/1.5.27/install-safe-chain.sh -o /tmp/install-safe-chain.sh
echo "600ebddcb3aaf1fd53653a8d7985df44528722c0f5ee7eb9fff86f26a1a4e5a8  /tmp/install-safe-chain.sh" | shasum -a 256 -c -
sh /tmp/install-safe-chain.sh
rm /tmp/install-safe-chain.sh
```

(`sha256sum -c -` works the same if you have GNU coreutils.)

### Windows (PowerShell)

```powershell
$installer = Join-Path $env:TEMP "install-safe-chain.ps1"
Invoke-WebRequest "https://github.com/AikidoSec/safe-chain/releases/download/1.5.27/install-safe-chain.ps1" -OutFile $installer -UseBasicParsing
$expectedHash = "9B9F329CB3E6EFC3B1BFB8B0B791F546FA52AC6CA791C8E9961C5830936D64F3"
if ((Get-FileHash $installer -Algorithm SHA256).Hash -ne $expectedHash) {
    Remove-Item $installer -ErrorAction SilentlyContinue
    throw "Checksum verification failed for install-safe-chain.ps1"
}
& $installer
Remove-Item $installer
```

### After install

1. **Restart the terminal** (required so `pnpm` / `npm` wrappers load).
2. Verify:

   ```sh
   pnpm safe-chain-verify
   ```

   You should see `OK: Safe-chain works!`

3. Optional: `safe-chain --version`

Docs: [Safe Chain](https://github.com/AikidoSec/safe-chain), [shell integration](https://github.com/AikidoSec/safe-chain/blob/main/docs/shell-integration.md), [troubleshooting](https://github.com/AikidoSec/safe-chain/blob/main/docs/troubleshooting.md).

## Getting started

From the **repo root**, after Node, Docker, and Safe Chain are installed:

**macOS / Linux**

```sh
pnpm install
pnpm db:up
pnpm db:migrate
```

**Windows (PowerShell)**

```powershell
pnpm install
pnpm db:up
pnpm db:migrate
```

| App | Quick start | Details |
| --- | --- | --- |
| API | `pnpm dev:api` | [apps/api/README.md](apps/api/README.md) |
| Mobile | `pnpm dev:mobile` | [apps/mobile/README.md](apps/mobile/README.md) |
| Infra | `pnpm infra:plan` | [infrastructure/README.md](infrastructure/README.md) |

Local Postgres defaults: `postgresql://pack:pack@localhost:5432/pack_draft` (see `docker-compose.yml`).

## Scripts (run from the repo root)

| Command | What it does |
| --- | --- |
| `pnpm dev:api` | API with file watching (`tsx watch`) |
| `pnpm dev:mobile` | Expo dev server |
| `pnpm db:up` | Start local Postgres (Docker Compose) |
| `pnpm db:down` | Stop local Postgres |
| `pnpm db:generate -- --name=<slug>` | Generate a named Drizzle SQL migration from the API schema |
| `pnpm db:migrate` | Apply pending Drizzle migrations |
| `pnpm build` | Build every package that has a `build` script |
| `pnpm typecheck` | `tsc --noEmit` in every package |
| `pnpm lint` | ESLint in every package that defines it |
| `pnpm format` | Prettier write in every package that defines it |
| `pnpm test` | Run tests in every package (Vitest API, Jest mobile) |
| `pnpm check` | lint + typecheck + test + build (CI-ready) |
| `pnpm infra:fmt` | Format Terraform under `infrastructure/` |
| `pnpm infra:lint` | Terraform fmt check + tflint |
| `pnpm infra:validate` | `terraform validate` for `TF_ENV` (default staging) |
| `pnpm infra:plan` | Terraform plan using `infrastructure/.env` |
| `pnpm infra:apply` | Apply saved `tfplan` (or interactive apply) |
| `pnpm infra:check` | infra lint + validate |

Run a script in one package with `pnpm --filter @pack-draft/api <script>`.

## Conventions

- Package names use the `@pack-draft/` scope.
- Dependency versions used by several packages live in the `catalog:` section of `pnpm-workspace.yaml`.
- Shared Zod schemas will go in `packages/` when the API and app need to share them.

## Editor (Cursor / VS Code)

Open the repo folder and install the workspace recommendations when prompted, or open **Extensions: Show Recommended Extensions**. The list lives in [`.vscode/extensions.json`](.vscode/extensions.json).

| Extension | Why |
| --- | --- |
| [HashiCorp Terraform](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform) | HCL highlighting, validate, and format for `infrastructure/` |
| [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint) | Inline lint for the API and mobile apps |
| [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | Format on save for TypeScript / JS |
| [Expo Tools](https://marketplace.visualstudio.com/items?itemName=expo.vscode-expo-tools) | Expo / React Native debugging helpers |
| [Docker](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) | Local Postgres via `docker-compose.yml` |

MDX extensions are listed as unwanted here so they do not treat `.tf` files as MDX (curly braces in Terraform look like JSX expressions to that parser).

## Cursor: Ponytail (optional)

[Ponytail](https://github.com/DietrichGebert/ponytail) steers the Cursor agent toward the smallest correct change. It is a personal install (user hooks), not checked into this repo.

**macOS / Linux**

```sh
git clone https://github.com/DietrichGebert/ponytail.git
node ponytail/scripts/cursor-hooks.js install
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/DietrichGebert/ponytail.git
node ponytail/scripts/cursor-hooks.js install
```

Leave the clone where you put it — the hooks point at that path. Open a new Cursor chat to activate.

| Message | Effect |
| --- | --- |
| `/ponytail` | Show the current level |
| `/ponytail lite` | Light touch |
| `/ponytail full` | Default |
| `/ponytail ultra` | Max minimalism |
| `/ponytail off` | Turn off for this chat |

Uninstall: `node ponytail/scripts/cursor-hooks.js uninstall`. Full agent list and options: [INSTALL.md](https://github.com/DietrichGebert/ponytail/blob/main/INSTALL.md).
