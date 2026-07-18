# Cockpit monorepo

This repository directly tracks the Cockpit backend and frontend source trees together with the shared automation that spans both services.

## Layout

- `backend/` — Cockpit v6 Go backend and embeddable SDK
- `frontend/` — React + Vite management WebUI
- `.github/workflows/` — monorepo CI, release, Docker publish, and cleanup workflows

## Clone

```bash
git clone git@github.com:coachpo/cockpit.git
```

## Where to work

- Backend implementation or API changes: start in `backend/AGENTS.md`
- Frontend UI or WebUI build changes: start in `frontend/AGENTS.md`
- Root changes should stay focused on shared automation and cross-service integration

## Service docs

- `backend/` is AGENTS-first and intentionally has no tracked README
- `frontend/` has both `AGENTS.md` and `README.md`

## Surface inventory

For a grounded list of what the current frontend exposes, what only exists on the management API, and what API consumers use under `/v1`, see [USER_FUNCTIONS.md](./USER_FUNCTIONS.md).

## Common root commands

```bash
git status --short
go -C backend test ./...
pnpm --dir frontend lint
pnpm --dir frontend build
```

## Workflow ownership

- Active monorepo automation: `.github/workflows/`
- Imported service workflow definitions remain under each service for reference; GitHub executes the adapted root workflows.

## Local-only directories

The root `.gitignore` keeps the following out of version control:

- `authjson/` — local auth material
- `docs/` — scratch docs and plans
- `.sisyphus/` — local planning state

Do not treat those directories as canonical product documentation.
