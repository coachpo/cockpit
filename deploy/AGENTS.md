# deploy

Parent: `../AGENTS.md`

## OVERVIEW
Root-owned local deployment seam. This folder wires the published backend/frontend images for a compose-based stack while keeping backend and frontend independently deployable.

## WHERE TO LOOK
- `docker-compose.yml`: three-container convenience stack; publishes backend on 8080, serves frontend through nginx, and preserves backend writable runtime paths without seeding a local config file.
- `env.example`: deployment env template for compose-level port overrides plus required backend bootstrap env.
- `nginx.conf`: reverse proxy for `/api`, `/v1/`, `/api/provider/`, and `/`, while `/codex/callback` remains frontend-owned through the SPA.

## LOCAL CONVENTIONS
- Keep this folder root-owned. Service-local runtime behavior still belongs in `backend/` or `frontend/`.
- `env.example` is the source of truth for compose-time env names; do not hardcode secrets into `docker-compose.yml`.
- The backend bootstrap path here is Nacos-only. The compose stack does not seed or depend on a local YAML config file.
- Preserve websocket proxy settings for `/v1/` and `/api/provider/` when editing nginx routes.
- Treat nginx same-origin proxying here as compose-stack convenience, not a requirement for separately deployed frontend instances.

## ANTI-PATTERNS
- Do not duplicate backend/frontend build or test commands here.
- Do not point nginx directly at unpublished local source trees; this folder is for image-backed deployment topology.
