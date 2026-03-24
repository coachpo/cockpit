# Cockpit user function matrix

This file inventories the user-facing functions that are actually exposed in the current Cockpit repo.
It separates the product into three surfaces so the current UI, management API, and `/v1` runtime do not get mixed together.

Primary anchors:

- Frontend UI sections and actions: `frontend/src/App.tsx`
- Frontend management client behavior: `frontend/src/lib/management-api.ts`
- Frontend tests that lock current exposure: `frontend/src/App.test.tsx`, `frontend/src/lib/management-api.test.ts`
- Mounted management routes: `backend/internal/api/server_management.go`
- Mounted `/v1` routes: `backend/internal/api/server_routes.go`
- Management API contract snapshot: `backend/api/openapi.yaml`

## At a glance

| Function group | User goal | UI | Mgmt API | API consumer | Notes |
|---|---|---|---|---|---|
| Codex Keys | Configure Codex providers and headers | Yes | `GET/PUT /api/codex-api-key` | No | UI replaces the full list; backend also supports `PATCH` and `DELETE` |
| API Keys | Configure downstream API keys | Yes | `GET/PUT /api/api-keys` | No | UI replaces the full list; backend also supports `PATCH` and `DELETE` |
| Runtime Settings | Control retries, routing, websocket auth, quota failover | Yes | `GET/PUT/PATCH` on `/ws-auth`, `/request-retry`, `/max-retry-interval`, `/routing/strategy`, `/quota-exceeded/switch-project` | No | UI uses `PUT`; backend also exposes `PATCH` aliases |
| Auth File Inventory | View managed auth files and their status | Yes | `GET /api/auth-files` | No | Current list is managed stored auths, not every runtime credential |
| Auth File Download | Export auth JSON | Yes | `GET /api/auth-files/download` | No | Exposed directly in the current UI |
| Auth File Priority | Change routing priority for an auth file | Yes | `PATCH /api/auth-files/fields` | No | UI exposes priority editing only, not full metadata editing |
| Auth File Enable/Disable | Toggle whether an auth file is active | Yes | `PATCH /api/auth-files/status` | No | Exposed directly in the current UI |
| Auth File Usage Probing | Query current usage/limits for probe-capable auth files | Yes | `POST /api/api-call` | No | UI supports per-file and batch usage refresh |
| Auth File Upload/Delete | Create or remove auth files | No | `POST/DELETE /api/auth-files` | No | Backend-only today; no upload/delete controls in the SPA |
| OAuth Start/Status | Launch Codex OAuth and poll until connected | Yes | `GET /api/codex-auth-url`, `GET /api/get-auth-status` | No | Current UI opens a popup and polls status |
| OAuth Callback Ingestion | Receive provider callback payload | Indirect | `POST /api/oauth-callback` | No | Not called by the UI directly; backend-only control path |
| Model Discovery | List available runtime models | No | No | `GET /v1/models` | There is no current model catalog UI |
| Chat Completions | Run OpenAI-compatible chat completions | No | No | `POST /v1/chat/completions` | Also accepts Responses-style payloads and rewrites them |
| Legacy Completions | Run legacy completions-compatible requests | No | No | `POST /v1/completions` | Compatibility layer over chat completions execution |
| Responses API | Run OpenAI Responses requests | No | No | `POST /v1/responses`, `POST /v1/responses/compact` | `compact` is non-streaming only |
| Responses Websocket | Stream Responses events over websocket | No | No | `GET /v1/responses` | Live route is `/v1/responses`, not `/v1/responses/ws` |
| Websocket Relay | Connect a provider relay session | No | No | `GET /v1/ws` | Separate websocket relay surface from Responses websocket |

## [UI] Current frontend exposure

The current WebUI is a single-page management console with four sections only, defined by `NAV_ITEMS` in `frontend/src/App.tsx`:

- `Codex Keys`
- `API Keys`
- `Runtime Settings`
- `Auth Files`

### [UI] Codex Keys

Exposed in `frontend/src/App.tsx` under `#codex-keys`.

Current UI supports:

- Load the current Codex key array from `GET /api/codex-api-key`
- Replace the full Codex key array with `PUT /api/codex-api-key`
- Edit JSON directly in the page
- View redacted example payloads for `opencode` and `codex_cli_rs`

Proof: `loadDashboard()`, `saveCodexKeys()`, and the section render in `frontend/src/App.tsx`.

### [UI] API Keys

Exposed in `frontend/src/App.tsx` under `#api-keys`.

Current UI supports:

- Load API keys from `GET /api/api-keys`
- Replace the full API key list with `PUT /api/api-keys`
- Edit keys as one-per-line text

Proof: `loadDashboard()` and `saveApiKeys()` in `frontend/src/App.tsx`.

### [UI] Runtime Settings

Exposed in `frontend/src/App.tsx` under `#runtime`.

Current UI supports:

- Toggle websocket auth with `GET` and `PUT /api/ws-auth`
- Set retry count with `GET` and `PUT /api/request-retry`
- Set max retry interval with `GET` and `PUT /api/max-retry-interval`
- Set routing strategy with `GET` and `PUT /api/routing/strategy`
- Toggle switch-project-on-quota-exceeded with `GET` and `PUT /api/quota-exceeded/switch-project`

Proof: `loadDashboard()`, `saveRuntimeSettings()`, and the mounted routes in `backend/internal/api/server_management.go`.

### [UI] Auth Files

Exposed in `frontend/src/App.tsx` under `#auth-files`.

Current UI supports:

- List auth files with `GET /api/auth-files`
- Download a file with `GET /api/auth-files/download?name=...`
- Start Codex OAuth with `GET /api/codex-auth-url?is_webui=true`
- Poll OAuth status with `GET /api/get-auth-status?state=...`
- Toggle disabled state with `PATCH /api/auth-files/status`
- Edit auth file priority with `PATCH /api/auth-files/fields`
- Query usage for one file or all probe-capable files through `POST /api/api-call`

Proof: `downloadAuthFile()`, `startOAuth()`, `saveAuthFileDetails()`, `toggleAuthFileDisabled()`, `queryAuthFileUsage()`, and `queryAllAuthFileUsage()` in `frontend/src/App.tsx` plus usage-probe helpers in `frontend/src/lib/auth-file-usage.ts`.

## [Mgmt API only] Exposed by backend management API, not surfaced in the current UI

The backend mounts more management operations than the frontend currently renders. See `backend/internal/api/server_management.go` and `backend/api/openapi.yaml`.

### [Mgmt API only] Auth file create and delete

Available in the backend, not exposed in the current UI:

- `POST /api/auth-files` to upload or create an auth JSON file
- `DELETE /api/auth-files` to delete one or more auth files

The current frontend `Auth Files` section lists, downloads, toggles, edits priority, and probes usage, but it does not render upload or delete controls in `frontend/src/App.tsx`.

### [Mgmt API only] Direct item-level mutation variants not used by the UI

Available in the backend, but the current UI does not use them:

- `PATCH /api/api-keys`
- `DELETE /api/api-keys`
- `PATCH /api/codex-api-key`
- `DELETE /api/codex-api-key`

The current UI only replaces full lists with `PUT`.

### [Mgmt API only] PATCH aliases for runtime settings

Mounted in the backend and documented in OpenAPI, but not used by the current UI:

- `PATCH /api/ws-auth`
- `PATCH /api/request-retry`
- `PATCH /api/max-retry-interval`
- `PATCH /api/routing/strategy`
- `PATCH /api/quota-exceeded/switch-project`

The current UI uses `PUT` for these writes.

### [Mgmt API only] OAuth callback ingestion

Available in the backend, not a direct UI action:

- `POST /api/oauth-callback`

The frontend starts OAuth and polls status. It does not call the callback endpoint itself.

## [API consumer only] `/v1` surface for downstream clients

The user-facing API for client integrations is mounted in `backend/internal/api/server_routes.go` under `/v1`, with auth enforced by `AuthMiddleware` in `backend/internal/api/server.go`.

Current `/v1` routes:

- `GET /v1/models`
- `POST /v1/chat/completions`
- `POST /v1/completions`
- `GET /v1/responses`
- `POST /v1/responses`
- `POST /v1/responses/compact`

These are for API consumers, not for the management UI.

Key runtime behaviors:

- `/v1/chat/completions` intentionally accepts some Responses-format payloads and rewrites them before execution (`backend/sdk/api/handlers/openai/openai_handlers.go`)
- `/v1/responses/compact` is non-streaming only (`backend/sdk/api/handlers/openai/openai_responses_handlers.go`)
- `GET /v1/responses` is the currently mounted websocket-style Responses route (`backend/internal/api/server_routes.go`)
- `GET /v1/ws` is a separate websocket relay endpoint attached from `sdk/cliproxy/service.go` through `internal/wsrelay` (`backend/internal/wsrelay/manager.go`)

## Caveats that should stay explicit

### Same-origin management client, no built-in browser auth header injection

The current frontend management client is same-origin and does not inject auth on its own.

Proof:

- `frontend/src/lib/management-api.ts` builds relative URLs from `MANAGEMENT_BASE_PATH`
- `frontend/src/lib/management-api.test.ts` asserts requests go to `/api/...`
- the same test asserts no `Authorization` header is sent

This means the frontend expects same-origin routing or proxying, not a browser-managed management token flow from this code.

### Current trimmed `/api` surface is mounted without request-access middleware

The current backend route wiring mounts `/api` directly in `backend/internal/api/server_management.go`, and the local management handler rules explicitly note that the trimmed management surface is mounted without request-access middleware.

That is different from the `/v1` surface, which is wrapped with `AuthMiddleware` in `backend/internal/api/server_routes.go`.

### No model catalog UI

The current frontend does not render or request a standalone model catalog.

Proof:

- UI sections in `frontend/src/App.tsx` contain only Codex Keys, API Keys, Runtime Settings, and Auth Files
- `frontend/src/App.test.tsx` asserts no request to `/api/model-definitions/codex`
- the same test asserts no `#model-catalog` section is rendered

### Auth file upload and delete exist only in the backend right now

The backend exposes upload and delete for auth files, but the frontend does not surface either action.

Proof:

- backend routes in `backend/internal/api/server_management.go`
- OpenAPI entries in `backend/api/openapi.yaml`
- no matching upload or delete UI actions in `frontend/src/App.tsx`

### Websocket route drift

The current mounted websocket-style Responses route is `GET /v1/responses` in `backend/internal/api/server_routes.go`.

Some backend websocket tests and AGENTS comments still reference `/v1/responses/ws`. Treat `/v1/responses/ws` as stale documentation or test-only shape, not the current mounted route for users.

### Frontend README auth statement is stale

`frontend/README.md` still says the frontend sends the management key as `X-Management-Key`.

That statement does not match the current client implementation in `frontend/src/lib/management-api.ts`, which only builds same-origin requests and does not inject management auth headers itself. The checked-in tests verify same-origin behavior and absence of `Authorization`, so docs should describe the current client as same-origin and header-neutral unless another layer adds headers outside this codebase.

## Removed or not currently exposed

Use this section to avoid over-claiming current functionality.

- Not exposed in the current frontend:
  - model catalog UI
  - auth file upload
  - auth file delete
  - item-level patch and delete controls for API keys
  - item-level patch and delete controls for Codex keys
  - cross-origin management base URL override UI
- Not a current mounted user route to document:
  - `/v1/responses/ws` as the primary websocket path
- Not supported as a current frontend claim:
  - "frontend sends `X-Management-Key`" as an app-level behavior

## Short summary

Today the frontend exposes four management areas only: Codex Keys, API Keys, Runtime Settings, and Auth Files. The backend management API exposes a few more operations, mostly upload, delete, and patch-style variants, that the UI does not yet surface. Separately, API consumers integrate against the authenticated `/v1` routes for models, completions, chat completions, responses, and websocket-based runtime flows.
