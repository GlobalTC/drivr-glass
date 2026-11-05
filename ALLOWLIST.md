# Allowlist export — drivr-glass companion

- Export date: 2026-11-05 (America/Denver)
- Version: 2026.11.05-1
- Source: owner live Worker tree (not a git repo); built by **allowlist copy**, never copy+delete.
- Everything not listed here was never copied (secrets `*.local`, `.cf-account-id`, `.wrangler/`, `node_modules/`, `*-backup*`, `merge-2026-10-27/`, `preview/`, `redirect/` + `wrangler.screenr-redirect.jsonc` (owner-only legacy redirect), `scripts/local-check.mjs` + `scripts/tap-check.mjs` (owner-box tooling paths, preview fixtures), `.mode-on`).

| Path | Origin |
|---|---|
| `.gitignore` | keeps *.local |
| `ALLOWLIST.md` | this file |
| `LICENSE` | new MIT |
| `README.md` | rewritten for importers |
| `VERSION` | new |
| `constitution-rules.json` | verbatim (roles only) |
| `docs/plain-fetch-readability.md` | rewritten portable (no owner names/host/id) |
| `package-lock.json` | regenerated 2026-11-05 (npm install, deps: typescript, wrangler) |
| `package.json` | rewritten (no owner absolute wrangler path, no puppeteer) |
| `scripts/clear-glass.sh` | rewritten: GLASS_URL.local instead of owner pinned-endpoint helper |
| `scripts/glass-config.sh` | new: shared config loader |
| `scripts/heartbeat.sh` | rewritten: GLASS_URL.local, no hardcoded TZ |
| `scripts/smoke.sh` | rewritten: GLASS_URL.local; adds bare-404 + snapshot checks |
| `src/constitution.ts` | verbatim |
| `src/index.ts` | verbatim |
| `src/page.ts` | BOT_NAMES owner fleet list → {"drivr":1} |
| `src/sanitize.ts` | owner-private term regex → PRIVATE_TERMS_RE placeholder |
| `src/snapshot.ts` | verbatim |
| `src/trace-hub.ts` | verbatim |
| `src/ui-ver.ts` | verbatim |
| `tsconfig.json` | verbatim |
| `worker-configuration.d.ts` | verbatim (generated types; no ids) |
| `wrangler.jsonc` | scrubbed (no account_id, placeholder GLASS_SESSION_ID, relative $schema) |
