# Papercuts

- 2026-09-04: After the workspace switched to managed permissions, committing the design updates failed with `fatal: Unable to create '/Users/ArmanTarkhanian1/Desktop/tasty planet clone/.git/index.lock': Operation not permitted`; the .git directory is read-only under the default sandbox, so the authorized commit needs a reviewed escalation.

- 2026-09-04: Tried to inspect the current Codex model/reasoning selector with cua.getApp("Codex"). Tool refused: `Computer Use is not allowed to use the app 'com.openai.codex' for safety reasons.` No setting was changed; native subagents can still be dispatched explicitly with gpt-6-astra and high reasoning.
- 2026-09-04: Blender discovery leaf's application glob failed with `zsh:1: no matches found: /Users/ArmanTarkhanian1/Applications/Blender*`; a pathlib directory scan resolved the discovery.
- 2026-09-04: Official Blender documentation opens through web returned `(402) Payment Required` for https://www.blender.org/releases/, https://docs.blender.org/manual/en/latest/advanced/command_line/arguments.html, and https://docs.blender.org/api/current/info_overview.html; direct curl retrieval worked. Initial HTML lookup for `id="cmdoption-python"` found no match, so inspected the literal command flags instead.
