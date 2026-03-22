# deploy

Parent: `../AGENTS.md`

## OVERVIEW
Root-owned local deployment seam. This folder wires the published backend/frontend images behind nginx for a compose-based stack.

## WHERE TO LOOK
- `docker-compose.yml`: three-container stack; bootstraps backend config into `/data/config.yaml`, runs backend + frontend + nginx.
- `env.example`: deployment env template for `DEPLOY`, `MANAGEMENT_PASSWORD`, and optional Nacos bootstrap.
- `nginx.conf`: reverse proxy for `/v0/management`, `/v1/`, `/api/provider/`, `/codex/callback`, and `/`.

## LOCAL CONVENTIONS
- Keep this folder root-owned. Service-local runtime behavior still belongs in `backend/` or `frontend/`.
- `env.example` is the source of truth for compose-time env names; do not hardcode secrets into `docker-compose.yml`.
- The backend container copies `../backend/config.example.yaml` into `/data/config.yaml` only on first boot; keep that bootstrap path aligned with backend config docs.
- Preserve websocket proxy settings for `/v1/` and `/api/provider/` when editing nginx routes.

## ANTI-PATTERNS
- Do not duplicate backend/frontend build or test commands here.
- Do not point nginx directly at unpublished local source trees; this folder is for image-backed deployment topology.
