# Removal Notes From `USER_FUNCTIONS.md`

Source: `/home/qing/projects/cockpit/USER_FUNCTIONS.md`

Purpose: scratch notes to log what should be removed or replaced from the current codebase based on the requested direction.

## Confirmed Direction

- Remove the function for configuring Codex providers and headers from backend to frontend.
- Do this with no backward compatibility layer.
- Redesign the full Management API structure.
- Keep `/v1/*` unchanged because it is the consumer API surface.
- API merging vs splitting is optional and can be decided during redesign.
- Change OAuth callback ingestion flow to: ingestion -> frontend -> backend.

## Removal Target 1: Codex Provider/Header Configuration

Current documented surface:

- UI area: `Codex Keys`
- Frontend behavior: `frontend/src/App.tsx`
- Frontend client: `frontend/src/lib/management-api.ts`
- Frontend tests: `frontend/src/App.test.tsx`, `frontend/src/lib/management-api.test.ts`
- Backend route wiring: `backend/internal/api/server_management.go`
- Contract snapshot: `backend/api/openapi.yaml`

Current documented endpoints:

- `GET /v0/management/codex-api-key`
- `PUT /v0/management/codex-api-key`
- Backend-only variants also documented today:
- `PATCH /v0/management/codex-api-key`
- `DELETE /v0/management/codex-api-key`

Logging note:

- Assume the whole current `codex-api-key` management surface is removable, not just hidden in UI.
- Remove related frontend entry points, backend route exposure, OpenAPI entries, and tests that preserve this behavior.
- No compatibility shim is planned.

## Removal/Replacement Target 2: Current Mgmt API Structure

Scope rule:

- Everything under current `/v0/management/*` can be redesigned.
- `/v1/*` must stay out of scope.

Current documented Mgmt API areas that are candidates to be retired and replaced:

- `codex-api-key`
- `api-keys`
- `ws-auth`
- `request-retry`
- `max-retry-interval`
- `routing/strategy`
- `quota-exceeded/switch-project`
- `auth-files`
- `auth-files/download`
- `auth-files/fields`
- `auth-files/status`
- `api-call`
- `codex-auth-url`
- `get-auth-status`
- `oauth-callback`

Logging note:

- Treat the current Management API path structure as disposable.
- Prefer recording removals by old route group and then mapping them to the new design later.
- Current `PATCH` aliases and item-level mutation variants should not be preserved automatically just because they already exist.
- Redesign OAuth callback handling so the callback reaches the frontend first, and the frontend then forwards the request to the backend.

## Explicitly Out Of Scope

- `GET /v1/models`
- `POST /v1/chat/completions`
- `POST /v1/completions`
- `GET /v1/responses`
- `POST /v1/responses`
- `POST /v1/responses/compact`
- `GET /v1/ws`

Logging note:

- Do not mix consumer API cleanup into this task.
- `/v1/*` is excluded from the Management API redesign.

## Optional Design Decision: Merge Or Split

Open note for later decision:

- Merge option: consolidate scattered config endpoints into a smaller resource-oriented Mgmt API.
- Split option: separate runtime settings, auth file operations, OAuth flows, and key management into clearer modules.
- Either option is acceptable if it removes the current fragmented `/v0/management` structure.

## Suggested Removal Log Format

- Remove current Codex provider/header configuration surface end-to-end.
- Retire current `/v0/management` route layout without backward compatibility.
- Keep `/v1/*` unchanged.
- Decide later whether the replacement Mgmt API should merge resources or split by domain.
