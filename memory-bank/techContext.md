# Technical context

The workspace is /Users/ArmanTarkhanian1/Desktop/tasty planet clone. It contains a Git repository and design documents, with no application code.

Use `/Applications/Blender.app/Contents/MacOS/Blender` directly; no PATH alias or separate CLI package is needed. On 2026-09-04, the user authorized updating the installed Blender 3.1.0 x86_64 build to Blender 5.2.1 LTS arm64 on an Apple M1 Max Mac Studio with 32 GB RAM.

The installer came from https://download.blender.org/release/Blender5.2/blender-5.2.1-macos-arm64.dmg and matched the official SHA-256 manifest. codesign verification passed and spctl reported `accepted` and `source=Notarized Developer ID`. The replacement was tested before switching application paths. The original application remains at `/Applications/Blender-3.1.0-backup.app` for rollback; preferences and user assets were not changed.

The installed app passed a factory-startup headless Python check that saved a .blend scene, exported a GLB, and rendered a PNG, all under `/tmp/tasty-planet-blender-update/`. The process exited 0 and printed `BLENDER_ASSET_SMOKE_OK 5.2.1 LTS`. Its build hash is `9e2066aef7ef`. These are asset-pipeline smoke checks, not game-performance measurements.

The user selected Blender CLI over MCP. No add-on, server, or MCP configuration was installed. Performance must be checked in the running game at 1920 × 1080; the local Mac Studio is the proposed baseline device. Headless Blender success is not render or game performance evidence.

Blender CLI can run Python for asset creation, materials, rendering, and export. The third-party ahujasid/blender-mcp adds a live-session bridge and external asset-service integrations; those conveniences are not bundled CLI features.
