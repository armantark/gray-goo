# Papercuts

- 2026-09-04: `pinchtab instances` in the isolated scene-atlas session returned `Error 403: {"code":"session_scope_forbidden","details":{"safeControlledEnvironmentOnly":true},"error":"agent session is not allowed to access this endpoint"}`. Use only the session's own navigation and tab-scoped operations; do not remove session scoping to reach the global inventory.

- 2026-09-04: Scene-curation preparation searched the nonexistent `/Users/ArmanTarkhanian1/.codex/skills/ask-kimi/scripts/kimi_client.py`; the installed wrapper actually invokes `kimi_direct.py`.
- 2026-09-04: The Kimi quota probe failed its network refresh in the restricted sandbox with `Kimi quota refresh failed after 3 attempts: <urlopen error [Errno 8] nodename nor servname provided, or not known>`; requested reviewed network access before selecting the curator.

- 2026-09-04: After the workspace switched to managed permissions, committing the design updates failed with `fatal: Unable to create '/Users/ArmanTarkhanian1/Desktop/tasty planet clone/.git/index.lock': Operation not permitted`; the .git directory is read-only under the default sandbox, so the authorized commit needs a reviewed escalation.

- 2026-09-04: Tried to inspect the current Codex model/reasoning selector with cua.getApp("Codex"). Tool refused: `Computer Use is not allowed to use the app 'com.openai.codex' for safety reasons.` No setting was changed; native subagents can still be dispatched explicitly with gpt-6-astra and high reasoning.
- 2026-09-04: Blender discovery leaf's application glob failed with `zsh:1: no matches found: /Users/ArmanTarkhanian1/Applications/Blender*`; a pathlib directory scan resolved the discovery.
- 2026-09-04: Official Blender documentation opens through web returned `(402) Payment Required` for https://www.blender.org/releases/, https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html, and https://docs.blender.org/api/current/info_overview.html; direct curl retrieval worked. Initial HTML lookup for `id="cmdoption-python"` found no match, so inspected the literal command flags instead.

2026-09-04: Original-level research: web.open StrategyWiki returned `(403) Forbidden`; sandbox curl failed `curl: (6) Could not resolve host: strategywiki.org`. Reviewed network curl succeeded.

2026-09-04: Source retrieval: Fandom original-game overview curl returned `curl: (56) The requested URL returned error: 403`. Use retrieved StrategyWiki chapters and official game material; do not invent absent chapter walkthroughs.

2026-09-04: Official `/tastyplanet/downloadmac.htm` returns a binary download, not HTML. `file` reported `zlib compressed data`, unzip exited 9, and sandbox `hdiutil imageinfo` returned `Device not configured`; inspect download headers/types before text parsing.

2026-09-04: Local commit rejected by slop-gate: `scripts/scene_catalogue.py: render 22 (new)` cyclomatic; `candidates 19 (new)` and `render 35 (new)` cognitive. Split scene validation, scene markup and selection validation into their distinct responsibilities before retrying.

2026-09-04: Retry of local commit rejected by slop-gate for `scripts/scene_catalogue.py: E303 x1 (was 0)` after responsibility split; removed the extra blank line.
