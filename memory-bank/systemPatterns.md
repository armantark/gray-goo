# System patterns

Godot 4 is the selected engine, targeting standalone macOS first for personal play. The four-level opening progression is accepted in projectbrief.md. Rendering architecture and gameplay rules remain to be resolved.

Recommended scale representation: keep documented physical sizes separate from the convenient coordinate units used to render and simulate each active scale band; preserve size ratios within a scene. This avoids treating the entire growth journey as one simultaneously simulated universe. Precise subatomic representation still requires a user decision.

Source checks on 2026-09-04: Godot spatial shaders provide diffuse_toon and specular_toon modes. Web exports require Compatibility rendering and WebGL 2.0; Forward+/Mobile and C# web exports are not supported by the retrieved stable documentation. Browser delivery is outside the accepted proof of concept, so do not impose those web constraints on the desktop renderer. No renderer, language, or performance outcome is selected or verified yet.

Sources:
- https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html
