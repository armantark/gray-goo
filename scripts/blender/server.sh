#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
export DISABLE_TELEMETRY=true
export BLENDER_MCP_SAFE_MODE=1
exec "$project_root/tooling/blender-mcp/.venv/bin/blender-mcp"
