# Cockpit

English | [简体中文](README_CN.md)

Cockpit fronts Codex with an OpenAI-compatible API: a Go proxy that manages Codex OAuth, forwards requests, and relays websocket traffic, with config and auth state that hot-reload from Nacos. It ships as a Go service with an embeddable SDK, plus a React management WebUI — this monorepo tracks all of it.

## Layout

- `backend/` — Go service and embeddable SDK: OAuth flow, OpenAI-compatible surface, Nacos-backed config/auth, websocket relay
- `frontend/` — React + Vite management WebUI
- `.github/workflows/` — monorepo CI, release, Docker publish, and cleanup

## Getting around

```bash
git clone git@github.com:coachpo/cockpit.git
```

- Backend or API changes: start from `backend/AGENTS.md` — the backend is documented AGENTS-first and intentionally has no separate README
- Frontend changes: start from `frontend/AGENTS.md` or `frontend/README.md`
- What the frontend exposes, what only exists on the management API, and what `/v1` consumers use: see [USER_FUNCTIONS.md](./USER_FUNCTIONS.md)

## Everyday commands

```bash
go -C backend test ./...
pnpm --dir frontend lint
pnpm --dir frontend build
```

## Notes

- The root workflows in `.github/workflows/` are the ones GitHub executes; workflow copies inside each service are kept for reference only.
- `authjson/`, `docs/`, and `.sisyphus/` are gitignored local scratch, not product documentation.
