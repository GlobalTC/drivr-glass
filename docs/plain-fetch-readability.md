# Design note — plain-fetch readability (`/snapshot`)

**Trigger:** An in-car assistant that fetches the interactive glass URL as plain text sees no usable content.

## Why

- `GET /s/<id>` returns HTML chrome only. Live Capture / Research / Fleet traces are filled in by client JS from `GET /s/<id>/list` + SSE `/s/<id>/events`, so a plain fetch looks empty.
- `/list` returns raw JSON traces, but not a prose-friendly cabin summary.

## Design (shipped)

`GET /s/<GLASS_SESSION_ID>/snapshot` is a **read twin** of the same TraceHub store:

- Default `text/plain; charset=utf-8` — labeled sections: Constitution, Capture (to-dos / ideas / notes), Research, Fleet.
- `Accept: application/json` or `?format=json` → `{ui, generatedAt, constitution, capture, research, fleet, traces}`.
- Valid session id required; bare `/snapshot` → 404; wrong id → 404; `Cache-Control: no-store`.
- Public read (no Bearer), same path obscurity as `/list`.
- The interactive HTML/SSE glass is unchanged; the DRIVER MODE constitution text is served only here (from `src/constitution.ts`), not rendered on the glass page.

## Placeholder at request time

The minute the owner (or the in-car assistant on their behalf) asks for something that will end up on the glass, push a Fleet (or Research/Capture) placeholder immediately (`status: working`), then update the same bot card when work completes. Session-start clear empties the glass; after that, every new ask seeds a placeholder first.

## Capture hierarchy

Notes, to-dos and ideas each nest under one parent card per kind (most recent item on the face, others nested). Do not flatten them into separate top-level cards.

## Non-goals

- Don't break SSE / interactive expand.
- Don't require auth on public session reads.
- Don't announce the bare host.
