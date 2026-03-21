# cockpit meta-repo

## OVERVIEW
This repository is the umbrella repo for the Cockpit frontend and backend submodules. Root-owned files should stay limited to submodule wiring and shared automation such as GitHub Actions.

## WHERE TO LOOK
- `backend/` — Go backend submodule.
- `frontend/` — pnpm + Vite + React management WebUI submodule.
- `.github/workflows/` — root-level automation for submodules, container publishing, and cleanup.

## LOCAL CONVENTIONS
- Do not add application source code at the root; keep it in `backend/` or `frontend/`.
- Root workflows may reference submodule paths, but service-specific CI should live in the service repo.
- Keep `.gitmodules` aligned with the published frontend/backend repositories and pin both submodules to `main`.
