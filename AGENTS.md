# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-25T00:00:00+02:00
**Commit:** 20dac8ee
**Branch:** main

## OVERVIEW
Cockpit is a monorepo that directly tracks the Go backend under `backend/` and the React frontend under `frontend/`. Root-owned files cover cross-service startup helpers, shared CI/container automation, and local-only scratch state that is gitignored.

## HIERARCHY RULE
Read the nearest `AGENTS.md` first. Root routes work into the two service trees; child files add local rules instead of repeating the whole repo map.

## STRUCTURE
```text
./
|- backend/             # directly tracked Go backend; canonical backend docs live here
|- frontend/            # directly tracked React + Vite management WebUI
|- .github/workflows/   # active monorepo CI, release, Docker, and cleanup automation
|- README.md            # monorepo quick start and ownership guide
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
| Frontend source layout and app-shell rules | `frontend/src/AGENTS.md` | `main.tsx` owns mount/bootstrap; `App.tsx` is the composition hotspot |
| Shared image publishing | `.github/workflows/docker-images.yml` | builds both tracked services from their own Dockerfiles |
| Package cleanup automation | `.github/workflows/cleanup.yml` | prunes workflow runs and untagged GHCR images |
| Local full-stack startup | `start.sh` | requires Docker, Go, Node 24+, and pnpm or Corepack, seeds Nacos `proxy-config` and `auth-credentials`, builds backend, starts the Vite dev server, and writes runtime logs/cache under `.sisyphus/local-start` |

## ROOT CONVENTIONS
- Do not add application source code at the root; service code belongs in `backend/` or `frontend/`.
- Root workflows orchestrate both services. GitHub only executes workflows under the repository-root `.github/workflows/` directory.
- Treat `authjson/`, `.sisyphus/`, and `test-output` as local-only state. If `docs/` is used locally, keep it as scratch space rather than canonical checked-in documentation.
- Treat editor and agent-tool directories like `.vscode/`, `.idea/`, `.codex/`, `.claude/`, `.gemini/`, `.serena/`, `.agent/`, `.agents/`, and `.opencode/` as workstation-local noise, not repo content.
- Verify root paths and commands against the current repo state before relying on them; this file is a routing layer, not a second copy of child docs.
- Prefer updating submodule-local docs over expanding the root file with service-specific detail.
- Do not duplicate backend/frontend build, test, or architecture rules here; keep those in the child `AGENTS.md` files.

## COMMANDS
```bash
git status --short
go -C backend test ./...
pnpm --dir frontend lint
pnpm --dir frontend build
./start.sh
```

## NOTES
- The root README is the quick start for humans; AGENTS files are the high-signal routing layer for agentic work.
- Root docker publishing builds the directly tracked service trees through their own Dockerfiles.
- `start.sh` keeps local runtime logs and Nacos cache under `.sisyphus/local-start/`, publishes the `proxy-config` and `auth-credentials` Nacos documents for local bootstrap, and should not be treated as checked-in source.
