#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
RUNTIME_DIR="$ROOT_DIR/.sisyphus/local-start"
BACKEND_BIN="$RUNTIME_DIR/cockpit"
BACKEND_CONFIG="$RUNTIME_DIR/config.yaml"
RUNTIME_ENV_FILE="$RUNTIME_DIR/.env"
BACKEND_AUTH_DIR="$RUNTIME_DIR/auth"
BACKEND_LOG="$RUNTIME_DIR/backend.log"
FRONTEND_LOG="$RUNTIME_DIR/frontend.log"

BACKEND_HOST="${BACKEND_HOST:-127.0.0.1}"
BACKEND_PORT="${BACKEND_PORT:-38317}"
FRONTEND_HOST="${FRONTEND_HOST:-127.0.0.1}"
FRONTEND_PORT="${FRONTEND_PORT:-35173}"
LOCAL_MANAGEMENT_PASSWORD="${LOCAL_MANAGEMENT_PASSWORD:-local-dev-management}"

BACKEND_PUBLIC_HOST=""
FRONTEND_PUBLIC_HOST=""
BACKEND_URL=""
FRONTEND_URL=""

backend_pid=""
frontend_pid=""
backend_started=0
frontend_started=0
cleanup_done=0

PNPM_CMD=()
PNPM_DISPLAY_COMMAND=""

log() {
  printf '[start.sh] %s\n' "$*"
}

fail() {
  log "$*"
  exit 1
}

require_command() {
  local command_name=$1

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '%s is required but was not found.\n' "$command_name" >&2
    exit 1
  fi
}

resolve_pnpm_cmd() {
  if command -v pnpm >/dev/null 2>&1; then
    PNPM_CMD=(pnpm)
    PNPM_DISPLAY_COMMAND='pnpm'
    return
  fi

  if command -v corepack >/dev/null 2>&1; then
    PNPM_CMD=(corepack pnpm)
    PNPM_DISPLAY_COMMAND='corepack pnpm'
    return
  fi

  printf 'pnpm (or corepack) is required but was not found.\n' >&2
  exit 1
}

check_node_version() {
  local raw_version
  local normalized
  local major

  raw_version="$(node --version 2>/dev/null || true)"
  normalized="${raw_version#v}"
  major="${normalized%%.*}"

  if [[ -z "$major" || ! "$major" =~ ^[0-9]+$ ]]; then
    printf 'Unable to determine Node.js version from %s\n' "$raw_version" >&2
    exit 1
  fi

  if (( major < 24 )); then
    printf 'Node.js 24 or newer is required. Found %s\n' "$raw_version" >&2
    exit 1
  fi
}

check_go_version() {
  local raw_version
  local normalized
  local major
  local remainder
  local minor

  raw_version="$(go env GOVERSION 2>/dev/null || true)"
  if [[ -z "$raw_version" ]]; then
    raw_version="$(go version | awk '{print $3}')"
  fi

  normalized="${raw_version#go}"
  major="${normalized%%.*}"
  remainder="${normalized#*.}"
  minor="${remainder%%.*}"

  if [[ -z "$major" || -z "$minor" || ! "$major" =~ ^[0-9]+$ || ! "$minor" =~ ^[0-9]+$ ]]; then
    printf 'Unable to determine Go version from %s\n' "$raw_version" >&2
    exit 1
  fi

  if (( major < 1 || (major == 1 && minor < 26) )); then
    printf 'Go 1.26 or newer is required. Found %s\n' "$raw_version" >&2
    exit 1
  fi
}

warn_if_backend_is_exposed() {
  case "$BACKEND_HOST" in
    127.0.0.1|localhost)
      ;;
    *)
      printf 'Warning: BACKEND_HOST=%s exposes management routes beyond localhost while MANAGEMENT_PASSWORD is enabled.\n' "$BACKEND_HOST" >&2
      ;;
  esac
}

probe_host() {
  local host=$1

  case "$host" in
    0.0.0.0|"")
      printf '127.0.0.1'
      ;;
    *)
      printf '%s' "$host"
      ;;
  esac
}

docker_daemon_available() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

port_is_listening() {
  local port=$1
  lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
}

port_pids() {
  local port=$1
  lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk '!seen[$0]++'
}

wait_for_port_release() {
  local port=$1
  local timeout_seconds=${2:-10}
  local deadline=$((SECONDS + timeout_seconds))

  while (( SECONDS < deadline )); do
    if ! port_is_listening "$port"; then
      return 0
    fi

    sleep 1
  done

  ! port_is_listening "$port"
}

kill_child_processes() {
  local signal=$1
  local pid=$2

  if ! command -v pkill >/dev/null 2>&1; then
    return
  fi

  pkill "-$signal" -P "$pid" 2>/dev/null || true
}

stop_process() {
  local pid=$1
  local deadline

  if [[ -z "$pid" ]] || ! kill -0 "$pid" 2>/dev/null; then
    return
  fi

  kill_child_processes TERM "$pid"
  kill "$pid" 2>/dev/null || true

  deadline=$((SECONDS + 5))
  while kill -0 "$pid" 2>/dev/null && (( SECONDS < deadline )); do
    sleep 0.1
  done

  if kill -0 "$pid" 2>/dev/null; then
    kill_child_processes KILL "$pid"
    kill -KILL "$pid" 2>/dev/null || true
  fi

  wait "$pid" 2>/dev/null || true
}

stop_docker_containers_publishing_port() {
  local port=$1
  local line
  local container_id
  local port_mappings
  local container_ids=()

  if ! docker_daemon_available; then
    return
  fi

  while IFS=$'\t' read -r container_id port_mappings; do
    [[ -z "$container_id" ]] && continue

    if [[ "$port_mappings" == *":${port}->"* || "$port_mappings" == "${port}->"* ]]; then
      container_ids+=("$container_id")
    fi
  done < <(docker ps --format '{{.ID}}\t{{.Ports}}' 2>/dev/null || true)

  if [[ "${#container_ids[@]}" -eq 0 ]]; then
    return
  fi

  printf 'Stopping Docker containers publishing port %s: %s\n' "$port" "${container_ids[*]}"
  docker stop "${container_ids[@]}" >/dev/null || true
}

kill_port_listeners() {
  local port=$1
  local pid
  local command_line

  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    command_line="$(ps -p "$pid" -o command= 2>/dev/null || true)"

    if [[ "$command_line" == *"com.docker"* || "$command_line" == *"vpnkit"* || "$command_line" == *"docker-proxy"* ]]; then
      continue
    fi

    printf 'Stopping process %s on port %s\n' "$pid" "$port"
    stop_process "$pid"
  done < <(port_pids "$port")

  if ! wait_for_port_release "$port" 10; then
    printf 'Port %s is still in use after cleanup.\n' "$port" >&2
    exit 1
  fi
}

stop_existing_stack() {
  for port in "$BACKEND_PORT" "$FRONTEND_PORT"; do
    stop_docker_containers_publishing_port "$port"
  done

  for port in "$BACKEND_PORT" "$FRONTEND_PORT"; do
    kill_port_listeners "$port"
  done
}

check_required_files() {
  if [[ ! -f "$BACKEND_DIR/go.mod" ]]; then
    printf 'Expected backend Go module at %s\n' "$BACKEND_DIR/go.mod" >&2
    exit 1
  fi

  if [[ ! -f "$FRONTEND_DIR/package.json" ]]; then
    printf 'Expected frontend package file at %s\n' "$FRONTEND_DIR/package.json" >&2
    exit 1
  fi

  if [[ ! -f "$FRONTEND_DIR/pnpm-lock.yaml" ]]; then
    printf 'Expected frontend lockfile at %s\n' "$FRONTEND_DIR/pnpm-lock.yaml" >&2
    exit 1
  fi

  if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    printf 'Frontend dependencies are missing. Run: (cd "%s" && %s install --frozen-lockfile)\n' "$FRONTEND_DIR" "$PNPM_DISPLAY_COMMAND" >&2
    exit 1
  fi
}

prepare_runtime_dir() {
  mkdir -p "$RUNTIME_DIR" "$BACKEND_AUTH_DIR"
  rm -f "$RUNTIME_ENV_FILE"
  : >"$BACKEND_LOG"
  : >"$FRONTEND_LOG"
}

write_backend_config() {
  cat >"$BACKEND_CONFIG" <<EOF
host: "${BACKEND_HOST}"
port: ${BACKEND_PORT}
auth-dir: "${BACKEND_AUTH_DIR}"
request-log: true
remote-management:
  allow-remote: false
EOF
}

print_recent_log() {
  local label=$1
  local log_file=$2

  if [[ -f "$log_file" ]]; then
    printf 'Recent %s log output:\n' "$label" >&2
    tail -n 40 "$log_file" >&2 || true
  fi
}

backend_running() {
  local host=$1
  local port=$2
  local resolved_host

  resolved_host="$(probe_host "$host")"

  curl --silent --show-error --fail --max-time 2 \
    "http://${resolved_host}:${port}/" 2>/dev/null | grep -F 'Cockpit Server' >/dev/null 2>&1
}

wait_for_backend_ready() {
  local deadline=$((SECONDS + 60))

  while (( SECONDS < deadline )); do
    if backend_running "$BACKEND_HOST" "$BACKEND_PORT"; then
      return 0
    fi

    if [[ "$backend_started" -eq 1 ]] && ! kill -0 "$backend_pid" 2>/dev/null; then
      return 1
    fi

    sleep 1
  done

  return 1
}

frontend_running() {
  local host=$1
  local port=$2
  local resolved_host

  resolved_host="$(probe_host "$host")"

  curl --silent --show-error --fail --max-time 2 \
    "http://${resolved_host}:${port}/" >/dev/null 2>&1
}

wait_for_frontend_ready() {
  local deadline=$((SECONDS + 60))

  while (( SECONDS < deadline )); do
    if frontend_running "$FRONTEND_HOST" "$FRONTEND_PORT"; then
      return 0
    fi

    if [[ "$frontend_started" -eq 1 ]] && ! kill -0 "$frontend_pid" 2>/dev/null; then
      return 1
    fi

    sleep 1
  done

  return 1
}

frontend_proxy_running() {
  curl --silent --show-error --fail --max-time 2 \
    -H "X-Management-Key: ${LOCAL_MANAGEMENT_PASSWORD}" \
    "${FRONTEND_URL}/v0/management/request-log" 2>/dev/null | grep -F 'request-log' >/dev/null 2>&1
}

wait_for_frontend_proxy_ready() {
  local deadline=$((SECONDS + 60))

  while (( SECONDS < deadline )); do
    if frontend_proxy_running; then
      return 0
    fi

    if [[ "$frontend_started" -eq 1 ]] && ! kill -0 "$frontend_pid" 2>/dev/null; then
      return 1
    fi

    if [[ "$backend_started" -eq 1 ]] && ! kill -0 "$backend_pid" 2>/dev/null; then
      return 1
    fi

    sleep 1
  done

  return 1
}

cleanup() {
  local exit_code=$?
  trap - EXIT INT TERM

  if [[ "$cleanup_done" -eq 1 ]]; then
    exit "$exit_code"
  fi
  cleanup_done=1

  printf 'Shutting down local services\n'

  if [[ "$frontend_started" -eq 1 ]]; then
    stop_process "$frontend_pid"
  fi

  if [[ "$backend_started" -eq 1 ]]; then
    stop_process "$backend_pid"
  fi

  stop_existing_stack

  exit "$exit_code"
}

trap cleanup EXIT INT TERM

main() {
  require_command bash
  require_command curl
  require_command go
  require_command node
  require_command lsof
  check_go_version
  check_node_version
  resolve_pnpm_cmd
  check_required_files
  warn_if_backend_is_exposed

  BACKEND_PUBLIC_HOST="$(probe_host "$BACKEND_HOST")"
  FRONTEND_PUBLIC_HOST="$(probe_host "$FRONTEND_HOST")"
  BACKEND_URL="http://${BACKEND_PUBLIC_HOST}:${BACKEND_PORT}"
  FRONTEND_URL="http://${FRONTEND_PUBLIC_HOST}:${FRONTEND_PORT}"

  printf 'Cleaning up ports %s and %s before startup\n' "$BACKEND_PORT" "$FRONTEND_PORT"
  stop_existing_stack

  prepare_runtime_dir
  write_backend_config

  printf 'Building backend binary\n'
  (
    cd "$BACKEND_DIR"
    go build -o "$BACKEND_BIN" ./cmd/cockpit
  )

  printf 'Starting backend on %s\n' "$BACKEND_URL"
  (
    cd "$RUNTIME_DIR"
    export MANAGEMENT_PASSWORD="$LOCAL_MANAGEMENT_PASSWORD"
    unset DEPLOY NACOS_ADDR NACOS_NAMESPACE NACOS_GROUP NACOS_USERNAME NACOS_PASSWORD NACOS_CACHE_DIR
    exec "$BACKEND_BIN"
  ) >"$BACKEND_LOG" 2>&1 &
  backend_pid=$!
  backend_started=1

  if ! wait_for_backend_ready; then
    printf 'Backend failed to become ready on port %s.\n' "$BACKEND_PORT" >&2
    print_recent_log 'backend' "$BACKEND_LOG"
    exit 1
  fi

  printf 'Starting frontend on %s\n' "$FRONTEND_URL"
  (
    cd "$FRONTEND_DIR"
    export COCKPIT_LOCAL_BACKEND_URL="$BACKEND_URL"
    exec "${PNPM_CMD[@]}" dev --host "$FRONTEND_HOST" --port "$FRONTEND_PORT" --strictPort
  ) >"$FRONTEND_LOG" 2>&1 &
  frontend_pid=$!
  frontend_started=1

  if ! wait_for_frontend_ready; then
    printf 'Frontend failed to become ready on port %s.\n' "$FRONTEND_PORT" >&2
    print_recent_log 'frontend' "$FRONTEND_LOG"
    exit 1
  fi

  if ! wait_for_frontend_proxy_ready; then
    printf 'Frontend could not reach the backend through the dev proxy.\n' >&2
    print_recent_log 'frontend' "$FRONTEND_LOG"
    print_recent_log 'backend' "$BACKEND_LOG"
    exit 1
  fi

  printf 'Frontend backend target: %s\n' "$BACKEND_URL"
  printf 'Management key: %s\n' "$LOCAL_MANAGEMENT_PASSWORD"
  printf 'Logs: %s | %s\n' "$BACKEND_LOG" "$FRONTEND_LOG"
  printf 'Press Ctrl+C to stop the backend and frontend.\n'

  local status=0

  while true; do
    if [[ "$backend_started" -eq 1 ]] && ! kill -0 "$backend_pid" 2>/dev/null; then
      wait "$backend_pid" || status=$?
      printf 'Backend exited. Stopping the rest of the stack...\n' >&2
      break
    fi

    if [[ "$frontend_started" -eq 1 ]] && ! kill -0 "$frontend_pid" 2>/dev/null; then
      wait "$frontend_pid" || status=$?
      printf 'Frontend exited. Stopping the rest of the stack...\n' >&2
      break
    fi

    sleep 1
  done

  exit "$status"
}

main "$@"
