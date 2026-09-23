#!/usr/bin/env bash
# Opens Blender with the isolated MCP profile; the add-on starts its socket
# server on localhost:9876 when it registers, which server.sh connects to.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
profile="$project_root/.tooling/blender-mcp"
export BLENDER_USER_CONFIG="$profile/config"
export BLENDER_USER_SCRIPTS="$profile/scripts"
nohup /Applications/Blender.app/Contents/MacOS/Blender \
  "$project_root/assets/source/cartoon_asset_library.blend" \
  --python "$project_root/scripts/blender/start_session.py" \
  > "$profile/blender-session.log" 2>&1 &
for _ in $(seq 60); do
  if nc -z localhost 9876 2>/dev/null; then
    echo "BLENDER_MCP_LISTENING localhost:9876"
    exit 0
  fi
  sleep 1
done
echo "Blender did not open port 9876; see $profile/blender-session.log" >&2
exit 1
