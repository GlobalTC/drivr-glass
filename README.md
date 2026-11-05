# Drivr cabin glass — companion Worker (`drivr-glass`)

Optional, self-hosted **cabin glass** for the Drivr Grok Bot template: a driving-safe web page that mirrors Drivr captures (notes, to-dos, ideas) and live bot activity in large type, plus a plain-text `/snapshot` the in-car assistant can read. Cloudflare Worker + one SQLite Durable Object (`TraceHub`). Version: see `VERSION`. License: MIT.

**The glass is optional.** Drivr captures work without it. If you skip this, Drivr runs capture-only.

You deploy **your own** copy to **your own** Cloudflare account. Nothing here points at anyone else's Worker.

## What you'll end up with

- Open URL (what the car displays): `https://drivr-glass.<your-subdomain>.workers.dev/s/<GLASS_SESSION_ID>`
- Snapshot URL (what the in-car assistant reads): `…/s/<GLASS_SESSION_ID>/snapshot`
- Bare host `https://drivr-glass.<your-subdomain>.workers.dev/` returns **404** and never redirects, so it can't leak your session id. Never share or speak the bare host as the open line.

Examples below use `https://drivr-glass.example.workers.dev/s/REPLACE_ME_GLASS_SESSION_ID`.

## Prerequisites

- A free Cloudflare account with a `workers.dev` subdomain.
- Node.js 20+ and npm.

## Setup

### 1. Install

```bash
cd drivr-glass
npm install
```

### 2. Generate your ids (never reuse anyone else's)

```bash
umask 077
openssl rand -hex 10 > GLASS_SESSION_ID.local      # path id (obscurity, not the secret)
openssl rand -base64 32 | tr -d '\n' > PUSH_TOKEN.local   # the push secret
chmod 600 GLASS_SESSION_ID.local PUSH_TOKEN.local
```

Both files are gitignored (`*.local`). **Never paste the token into chat, memory, a skill, a trace, or a log.** Keep it in a mode-600 `.local` file (or a password vault) only.

### 3. Configure `wrangler.jsonc`

- Replace `REPLACE_ME_GLASS_SESSION_ID` in `vars.GLASS_SESSION_ID` with the contents of `GLASS_SESSION_ID.local`.
- Account: run `npx wrangler login` (recommended), or add `"account_id": "<your account id>"` locally. Don't commit your account id if you publish your fork.
- Optional: change `"name"` if you want a different Worker name (the host becomes `<name>.<subdomain>.workers.dev`).

### 4. Deploy, then set the secret

```bash
npx wrangler deploy
npx wrangler secret put PUSH_TOKEN < PUSH_TOKEN.local
```

`wrangler deploy` prints your host. Write the full open URL (host + `/s/<id>`) to `GLASS_URL.local`:

```bash
echo "https://drivr-glass.<your-subdomain>.workers.dev/s/$(cat GLASS_SESSION_ID.local)" > GLASS_URL.local
chmod 600 GLASS_URL.local
```

### 5. Smoke test

```bash
./scripts/smoke.sh        # bare host 404, /health ok, open + /snapshot 200, push arrives over SSE
./scripts/clear-glass.sh  # wipe the smoke card
```

Then open the open URL on your phone or car browser and confirm the empty glass loads.

### 6. Tell Drivr

Give Drivr the **open URL only** (not the token). Drivr saves it in memory as `Drivr glass URL: <open URL>` and the token path as `Drivr glass token file: <absolute path to PUSH_TOKEN.local>`. The `drivr-getting-started` skill walks through this.

## Routes

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/` | **404** (no redirect; does not disclose session id) |
| `GET` | `/s/<id>` | Driving-safe HTML (canonical open URL) |
| `GET` | `/s/<id>/events` | SSE stream (`text/event-stream`) |
| `GET` | `/s/<id>/list` | JSON snapshot of recent traces |
| `GET` | `/s/<id>/snapshot` | Plain text (default) or JSON (`?format=json`) for in-car assistants |
| `POST` | `/s/<id>/push` (or `/push`) | Authenticated push (Bearer required) |
| `POST` | `/s/<id>/clear` (or `/clear`) | Authenticated wipe of all traces + empty SSE snapshot |
| `GET` | `/health` | Plain `ok` |

Bare `/events`, `/list`, `/snapshot` → 404. Wrong `/s/<id>` → 404.

## Push contract

`POST <open URL>/push` with `Authorization: Bearer <token>` and JSON:

```json
{"bot":"Drivr","summary":"Need to call the dentist Tuesday about the cleaning.","kind":"todo","status":"open"}
```

| Field | Required | Limits |
|-------|----------|--------|
| `bot` | yes | ≤ 40 — card key (one card per bot, updated in place) |
| `summary` | yes | ≤ 280 — brief narrative, not a title slug |
| `detail` | no | ≤ 4000 — expanded body / in-car context |
| `result` | no | ≤ 4000 — preferred expanded body |
| `from` | no | ≤ 40 — creating bot when `bot` is a specialist label |
| `status` | no | ≤ 24 — `open`, `done`, `working`, … |
| `kind` | no | ≤ 24 — capture: `note` \| `todo` \| `idea` \| `capture`; research: `research`; omit for fleet activity |
| `ts` | no | ISO-8601; omit → server now |

Mark done: re-push the same `summary` + `kind` with `"status":"done"`. Success: `201 {"ok":true,"trace":{…}}`. Errors: `401` unauthorized, `400` validation / sanitize reject.

**Privacy:** the server sanitizes on ingest — it rejects or strips emails, token-like strings, `/home/...` paths and medical wording. Add your own private terms in `src/sanitize.ts` (`PRIVATE_TERMS_RE`). Never push secrets or health details.

**Named bots:** `src/page.ts` `BOT_NAMES` lists bot names (lowercase) that render as named fleet cards. It ships with `drivr` only; add your own bots.

Example:

```bash
TOKEN="$(cat PUSH_TOKEN.local)"
curl -sS -X POST "$(cat GLASS_URL.local)/push" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"bot":"Drivr","summary":"What if we drip-irrigate the tomatoes this spring?","kind":"idea","status":"open"}'
```

## SSE events

`EventSource` on `/s/<id>/events`: `snapshot` (`{traces: Trace[]}`, up to ~50 newest first), `trace` (one new trace), `: keepalive` comments ~every 25s.

## Storage

Durable Object `TraceHub` (SQLite), instance `fleet`. Keeps the last ~50 traces. Each new Drivr session clears it; durable history lives in your Drivr store, not on the glass.

## Rotating your id or token

New id: generate a new `GLASS_SESSION_ID.local`, update `vars.GLASS_SESSION_ID`, `npx wrangler deploy`, rewrite `GLASS_URL.local`, update Drivr's memory line. The old `/s/<old-id>` then 404s. New token: regenerate `PUSH_TOKEN.local`, `npx wrangler secret put PUSH_TOKEN < PUSH_TOKEN.local`.

## Local checks

```bash
npx wrangler types   # regenerates worker-configuration.d.ts if you change bindings
npx tsc --noEmit
```
