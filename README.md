# Cockpit meta-repo

This repository pins the published Cockpit backend and frontend repositories as submodules and owns only the shared automation that spans both services.

## Layout

- `backend/` — Cockpit v6 Go backend and embeddable SDK
- `frontend/` — React + Vite management WebUI
- `.github/workflows/` — root-level Docker publish and cleanup workflows
- `.gitmodules` — submodule URLs and `main` branch pins

## Clone and sync

```bash
git clone --recursive git@github.com:coachpo/cockpit.git
git submodule sync --recursive
git submodule update --init --recursive
```

If you already cloned without submodules, run the last two commands from the repo root.

## Where to work

- Backend implementation or API changes: start in `backend/AGENTS.md`
- Frontend UI or WebUI build changes: start in `frontend/AGENTS.md`
- Root changes should stay limited to submodule wiring and shared automation

## Submodule docs

- `backend/` is AGENTS-first and intentionally has no tracked README
- `frontend/` has both `AGENTS.md` and `README.md`

## Surface inventory

For a grounded list of what the current frontend exposes, what only exists on the management API, and what API consumers use under `/v1`, see [USER_FUNCTIONS.md](./USER_FUNCTIONS.md).

## Common root commands

```bash
git submodule sync --recursive
git submodule update --init --recursive
git -C backend status --short
git -C frontend status --short
```

## Workflow ownership

- Root: `.github/workflows/docker-images.yml`, `.github/workflows/cleanup.yml`
- Backend CI: `backend/.github/workflows/ci.yml`
- Frontend CI: `frontend/.github/workflows/ci.yml`

## Local-only directories

The root `.gitignore` keeps the following out of version control:

- `authjson/` — local auth material
- `docs/` — scratch docs and plans
- `.sisyphus/` — local planning state

Do not treat those directories as canonical product documentation.
