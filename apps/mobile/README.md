# @pack-draft/mobile

**Expo SDK 58** / **React Native** app for iOS and Android. Blank TypeScript entry (`App.tsx` + `index.ts`); navigation and variants will follow [ADR-008](../../docs/decisions/008-mobile-app-deployments.md).

## Prerequisites

Install monorepo tooling from the **repo root** first ([root README](../../README.md)): Node 22+, pnpm via Corepack, and Aikido Safe Chain. Then `pnpm install` at the root.

### macOS

- **iOS:** Xcode from the Mac App Store, then open Xcode once to finish installing components. Simulator works with `pnpm ios`.
- **Android (optional):** [Android Studio](https://developer.android.com/studio) + an emulator, or Expo Go on a device.
- Or skip native tooling and use [Expo Go](https://expo.dev/go) on a physical device with `pnpm dev:mobile`.

### Windows

- **Android:** [Android Studio](https://developer.android.com/studio) + an emulator, or Expo Go on a device. Use `pnpm android` or `pnpm dev:mobile`.
- **iOS:** The iOS Simulator is not available on Windows. Use a Mac, a cloud Mac builder (EAS), or Expo Go on a physical iPhone.
- Enable Developer Mode if Windows asks when running emulators.

## Development

### macOS

```sh
pnpm dev:mobile    # Expo dev server
pnpm ios           # iOS simulator
pnpm android       # Android emulator (if installed)
```

### Windows (PowerShell)

```powershell
pnpm dev:mobile    # Expo dev server
pnpm android       # Android emulator (if installed)
# pnpm ios is not supported on Windows
```

From this directory: `pnpm start`, then press `i` / `a` in the Expo CLI when that platform is available.

## Scripts

Run from `apps/mobile` or with `pnpm --filter @pack-draft/mobile <script>` from the root.

| Script      | Purpose                     | macOS | Windows |
| ----------- | --------------------------- | ----- | ------- |
| `start`     | Expo dev server             | yes   | yes     |
| `ios`       | Dev server + iOS            | yes   | no      |
| `android`   | Dev server + Android        | yes   | yes     |
| `web`       | Dev server + web (optional) | yes   | yes     |
| `typecheck` | `tsc --noEmit`              | yes   | yes     |
| `lint`      | ESLint                      | yes   | yes     |
| `format`    | Prettier write              | yes   | yes     |
| `test`      | Jest (`jest-expo`)          | yes   | yes     |

**macOS / Linux:** `cp .env.example .env` when you need `EXPO_PUBLIC_API_URL`.  
**Windows:** `Copy-Item .env.example .env`.

## Adding dependencies

Use Expo’s resolver so versions match the SDK — **do not** `pnpm add` native/Expo packages directly (same on Mac and Windows):

```sh
pnpm --filter @pack-draft/mobile exec expo install <package-name>
```

Check the tree after changes:

```sh
pnpm --filter @pack-draft/mobile exec expo-doctor
```

Only one version of React, React Native, and each native module may exist across the monorepo ([Expo monorepos](https://docs.expo.dev/guides/monorepos/), [ADR-008](../../docs/decisions/008-mobile-app-deployments.md)).

## Configuration

- **`app.json`** — app name, slug (`pack-draft`), icons, platform settings. Native projects are generated (CNG); avoid hand-editing `ios/` or `android/` when they appear.
- **`AGENTS.md`** — agent-oriented Expo notes (SDK version, `expo install`, future Expo Router guidance).

## Docs version

This app targets Expo **58** (`expo` in `package.json`). Use versioned docs: [https://docs.expo.dev/versions/v58.0.0/](https://docs.expo.dev/versions/v58.0.0/).

## Related docs

- [Root README](../../README.md) — monorepo overview, Safe Chain, Mac/Windows setup
- [ADR-008](../../docs/decisions/008-mobile-app-deployments.md) — builds, variants, EAS / Expo Workflows
- [ADR-009](../../docs/decisions/009-testing-framework.md) — Jest + `jest-expo` (not wired in this scaffold yet)
