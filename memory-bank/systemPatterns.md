# System patterns

No engine or rendering architecture has been selected. The four-level opening progression is accepted in projectbrief.md. Technical recommendations remain provisional until the interview resolves them.

Engine recommendation (pending user acceptance): Godot 4, desktop first, optional browser demo. Keep documented physical sizes separate from the convenient coordinate units used to render and simulate each active scale band; preserve size ratios within a scene. This avoids treating the entire growth journey as one simultaneously simulated universe.

Source checks on 2026-09-04: Godot spatial shaders provide diffuse_toon and specular_toon modes. Web exports require Compatibility rendering and WebGL 2.0; Forward+/Mobile and C# web exports are not supported by the retrieved stable documentation. Keeping a web target would therefore constrain renderer and language choices and require a representative visual/performance test early. No renderer, language, or performance outcome is selected or verified yet.

Sources:
- https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html
