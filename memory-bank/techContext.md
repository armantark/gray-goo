# Technical context

The workspace is /Users/ArmanTarkhanian1/Desktop/tasty planet clone. It contains the Godot project at project.godot, runtime GDScript under src, shaders under shaders, and original generated assets under assets.

Use `/Applications/Blender.app/Contents/MacOS/Blender` directly; no PATH alias or separate CLI package is needed. On 2026-09-04, the user authorized updating the installed Blender 3.1.0 x86_64 build to Blender 5.2.1 LTS arm64 on an Apple M1 Max Mac Studio with 32 GB RAM.

The installer came from https://download.blender.org/release/Blender5.2/blender-5.2.1-macos-arm64.dmg and matched the official SHA-256 manifest. codesign verification passed and spctl reported `accepted` and `source=Notarized Developer ID`. The replacement was tested before switching application paths. The original application remains at `/Applications/Blender-3.1.0-backup.app` for rollback; preferences and user assets were not changed.

The installed app passed a factory-startup headless Python check that saved a .blend scene, exported a GLB, and rendered a PNG, all under `/tmp/tasty-planet-blender-update/`. The process exited 0 and printed `BLENDER_ASSET_SMOKE_OK 5.2.1 LTS`. Its build hash is `9e2066aef7ef`. These are asset-pipeline smoke checks, not game-performance measurements.

The project also has an approved Blender MCP setup for live model refinement. `.codex/config.toml` allows only scene information, code execution, and viewport screenshots, with text output limits. `scripts/blender/server.sh` enables safe mode and disables telemetry. The addon uses an isolated profile under ignored `.tooling/blender-mcp/`; its pinned Python runtime lives under `tooling/blender-mcp/`. Performance must be checked in the running game at 1920 × 1080; the local Mac Studio is the proposed baseline device. Headless Blender success is not render or game performance evidence.

Blender CLI can run Python for asset creation, materials, rendering, and export. The third-party ahujasid/blender-mcp adds a live-session bridge and external asset-service integrations; those conveniences are not bundled CLI features.

Godot 4.7.2 standard universal is installed at /Applications/Godot.app. Its official archive passed SHA512 verification, codesign verification, spctl assessment (`accepted`, `source=Notarized Developer ID`), and headless version execution (`4.7.2.stable.official.ed1daf0bf`). The existing /Applications/Godot_mono.app is untouched. Only macos.zip from the verified official export templates is installed under ~/Library/Application Support/Godot/export_templates/4.7.2.stable.

Regenerate models with Blender using scripts/build_assets.py and --python-exit-code 1. assets/source/.gdignore prevents Godot from trying to import the editable .blend source; the runtime uses the exported GLBs and committed .import settings. Regenerate the original short sounds with python3 scripts/build_audio.py.
