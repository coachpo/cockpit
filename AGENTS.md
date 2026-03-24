# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-24T02:32:07+02:00
**Commit:** 169f6c0a
**Branch:** main

## OVERVIEW
Cockpit is a meta-repo that pins the published `backend/` and `frontend/` repositories as submodules. Root-owned files stay limited to submodule wiring, cross-service startup and deployment helpers, shared container automation, and local-only scratch state that is gitignored.

## HIERARCHY RULE
Read the nearest `AGENTS.md` first. Root routes work into submodules; child files add local rules instead of repeating the whole repo map.

## STRUCTURE
```text
./
|- backend/             # Go backend submodule; canonical backend docs live here
|- frontend/            # React + Vite management WebUI submodule
|- deploy/              # local deployment stack: docker compose, nginx, env template
|- .github/workflows/   # root-only docker publishing and cleanup automation
|- .gitmodules          # published submodule URLs, paths, and branch pins
|- README.md            # meta-repo quick start and ownership guide
|- start.sh             # local full-stack launcher for backend + frontend dev
|- authjson/            # gitignored local auth material; never commit contents
|- docs/                # optional scratch docs/plans when used locally; not canonical product docs
`- .sisyphus/           # gitignored local planning state
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Backend runtime, SDK, or API work | `backend/AGENTS.md` | backend is AGENTS-first; there is no tracked backend README |
| Frontend UI or management-console work | `frontend/AGENTS.md` | frontend root covers setup, build, and high-level app shape |
| Frontend source layout and app-shell rules | `frontend/src/AGENTS.md` | `App.tsx` is the canonical source entrypoint |
| Local compose/nginx deployment wiring | `deploy/AGENTS.md` | owns `docker-compose.yml`, `nginx.conf`, and deploy env bootstrap |
| Shared image publishing | `.github/workflows/docker-images.yml` | builds both submodules from their own Dockerfiles |
| Package cleanup automation | `.github/workflows/cleanup.yml` | prunes workflow runs and untagged GHCR images |
| Local full-stack startup | `start.sh` | seeds local Nacos directly, builds backend, starts Vite dev server, and writes runtime logs/cache under `.sisyphus/local-start` |
| Submodule URL or branch drift | `.gitmodules` | both submodules stay pinned to `main` |

## ROOT CONVENTIONS
- Do not add application source code at the root; service code belongs in `backend/` or `frontend/`.
- Root workflows may orchestrate both services, but service-specific CI belongs in each submodule's own `.github/workflows/` directory.
- Keep `.gitmodules` aligned with `coachpo/cockpit-backend` and `coachpo/cockpit-frontend`, both on `main`.
- Treat `authjson/`, `.sisyphus/`, `test-output`, and `deploy/.env` as local-only state. If `docs/` is used locally, keep it as scratch space rather than canonical checked-in documentation.
- Treat editor and agent-tool directories like `.vscode/`, `.idea/`, `.codex/`, `.claude/`, `.gemini/`, `.serena/`, `.agent/`, `.agents/`, and `.opencode/` as workstation-local noise, not repo content.
- Verify root paths and commands against the current repo state before relying on them; this file is a routing layer, not a second copy of child docs.
- Prefer updating submodule-local docs over expanding the root file with service-specific detail.
- Do not duplicate backend/frontend build, test, or architecture rules here; keep those in the child `AGENTS.md` files.

## COMMANDS
```bash
git submodule sync --recursive
git submodule update --init --recursive
git -C backend status --short
git -C frontend status --short
./start.sh
```

## NOTES
- The root README is the quick start for humans; AGENTS files are the high-signal routing layer for agentic work.
- Root docker publishing passes through submodule Dockerfiles instead of owning service build logic itself.
- `deploy/` is the root-owned deployment seam; service-local runtime behavior still belongs in each submodule.
- `start.sh` keeps local runtime logs and Nacos cache under `.sisyphus/local-start/`; do not treat that output as checked-in source.
