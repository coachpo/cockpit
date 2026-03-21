# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-21T23:19:20+02:00
**Commit:** 058ad56e
**Branch:** main

## OVERVIEW
Cockpit is a meta-repo that pins the published `backend/` and `frontend/` repositories as submodules. Root-owned files stay limited to submodule wiring, shared container automation, and local-only scratch state that is gitignored.

## HIERARCHY RULE
Read the nearest `AGENTS.md` first. Root routes work into submodules; child files add local rules instead of repeating the whole repo map.

## STRUCTURE
```text
./
|- backend/             # Go backend submodule; canonical backend docs live here
|- frontend/            # React + Vite management WebUI submodule
|- .github/workflows/   # root-only docker publishing and cleanup automation
|- .gitmodules          # published submodule URLs, paths, and branch pins
|- README.md            # meta-repo quick start and ownership guide
|- authjson/            # gitignored local auth material; never commit contents
|- docs/                # gitignored scratch docs/plans, not canonical product docs
`- .sisyphus/           # gitignored local planning state
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Backend runtime, SDK, or API work | `backend/AGENTS.md` | backend is AGENTS-first; there is no tracked backend README |
| Frontend UI or management-console work | `frontend/AGENTS.md` | frontend root covers setup, build, and high-level app shape |
| Frontend source layout and app-shell rules | `frontend/src/AGENTS.md` | `App.tsx` is the canonical source entrypoint |
| Shared image publishing | `.github/workflows/docker-images.yml` | builds both submodules from their own Dockerfiles |
| Package cleanup automation | `.github/workflows/cleanup.yml` | prunes workflow runs and untagged GHCR images |
| Submodule URL or branch drift | `.gitmodules` | both submodules stay pinned to `main` |

## ROOT CONVENTIONS
- Do not add application source code at the root; service code belongs in `backend/` or `frontend/`.
- Root workflows may orchestrate both services, but service-specific CI belongs in each submodule's own `.github/workflows/` directory.
- Keep `.gitmodules` aligned with `coachpo/cockpit-backend` and `coachpo/cockpit-frontend`, both on `main`.
- Treat `authjson/`, `docs/`, and `.sisyphus/` as local-only state. They are gitignored helpers, not canonical checked-in documentation.
- Prefer updating submodule-local docs over expanding the root file with service-specific detail.

## COMMANDS
```bash
git submodule sync --recursive
git submodule update --init --recursive
git -C backend status --short
git -C frontend status --short
```

## NOTES
- The root README is the quick start for humans; AGENTS files are the high-signal routing layer for agentic work.
- Root docker publishing passes through submodule Dockerfiles instead of owning service build logic itself.
