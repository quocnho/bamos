---
name: typescript-node-pwa
description: >-
  Use this skill for TypeScript, Node.js, and Progressive Web App (PWA) work:
  tsconfig setup, pnpm/npm workflows, ESM modules, debugging, testing with
  vitest, and PWA specifics (manifest, service worker, offline caching,
  installability, Lighthouse audits). Activate when the user asks to build,
  debug, test, or optimize a TS/Node/PWA project (package.json, tsconfig.json,
  service-worker, manifest.webmanifest).
---

# TypeScript / Node.js / PWA Development

Modern TS/Node/PWA workflows. Node 24 LTS and pnpm are installed system-wide; projects may pin their own versions via devenv (see the `devenv-direnv` skill).

## Project setup

- Use `pnpm` when the project allows it (`.npmrc` `package-manager` or devenv `pnpm` config); fall back to `npm`/`bun` when the project is already configured for them.
- Install: `pnpm install` (creates `pnpm-lock.yaml` — commit it).
- New TS project:
  ```
  pnpm create vite@latest my-app --template vanilla-ts
  # hoặc cho library:
  pnpm init && pnpm add -D typescript @types/node tsx vitest
  ```

## tsconfig (recommended baseline)

```jsonc
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",          // hoặc "ESNext" + bundler
    "moduleResolution": "NodeNext",// "Bundler" nếu dùng Vite
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "verbatimModuleSyntax": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "types": ["node"]
  }
}
```
Never disable `strict` to silence errors; fix the types instead.

## ESM vs CJS

- With `"type": "module"` in package.json, `.ts` files compile to ESM: use `import`/`export`, `import.meta.url`.
- Relative imports in NodeNext need explicit extensions (`./utils.js` even in `.ts` source) unless using a bundler.
- Mixing CJS/ESM packages: use `import` with `esModuleInterop`; `require()` only in `.cts`/`.mts` contexts.

## Debugging

- Run with `node --watch --experimental-strip-types src/main.ts` (Node 22.6+/24) or `tsx src/main.ts` for quick iteration.
- Node built-in debugger: `node --inspect` then attach from the IDE (Chrome DevTools protocol). For breakpoints use `node --inspect-brk`.
- Logs: use `console.error` for diagnostics that must not pollute stdout (important for scripts/CLIs).
- Uncaught errors: listen to `process.on('unhandledRejection', ...)` in long-running processes.

## Testing (vitest)

- `pnpm add -D vitest`
- `vitest` (watch) / `vitest run` (CI) / `vitest run src/foo.test.ts`
- Structure: `describe` / `it` / `expect`; use `vi.fn()` for mocks, `vi.useFakeTimers()` for time.
- Coverage: `vitest run --coverage`.

## PWA essentials

- **Manifest** (`manifest.webmanifest`): `name`, `short_name`, `start_url`, `display: standalone`, `icons` (192px + 512px with `purpose: "any maskable"`), `theme_color`, `background_color`.
- **Service worker** (use Workbox when practical: `workbox-build` or `vite-plugin-pwa`):
  - Precache app shell (`precacheAndRoute`), runtime cache for assets (`registerRoute` + `StaleWhileRevalidate` for API, `CacheFirst` for static).
  - Offline fallback: cache an `offline.html` and `navigationRoute` fallback.
  - Update strategy: skip waiting + clients claim: `self.skipWaiting(); clients.claim();` and listen for `message` to reload.
- **Installability checklist** (Chrome):
  - HTTPS (or localhost), valid manifest with icons, registered service worker with fetch handler.
  - Audit with Lighthouse: `npx lighthouse <url> --only-categories=pwa` (or the extension if installed).
- **Push notifications**: VAPID keys via `web-push`; show notification on `push` event, respond to `notificationclick`.

## Common gotchas

- **Type-only imports**: with `verbatimModuleSyntax`, use `import type { Foo }`.
- **`node:` prefix**: import built-ins as `node:fs`, `node:path` — required for clarity in ESM.
- **Engines mismatch**: if `pnpm install` warns about engines, respect the project's `package.json` engines or change them deliberately.
- **Port in use**: `lsof -i :5173` or use `pnpm dev --port 5174`; in devenv use a dedicated port for each project.
- Never commit `node_modules` or `.env`; add them to `.gitignore`.
