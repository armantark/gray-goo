# System patterns

Godot 4 is the selected engine, targeting standalone macOS first for personal play. The user proposed a representative four-level sampler; exact levels remain open. Rendering architecture and detailed growth/interaction rules remain to be resolved. Play is untimed and damage is deferred.

Liquid behavior contract: coherent translucent surface, local consumption, remaining mass persists. Connected fluid points are the user's suggested representation; choose the simplest implementation that delivers the actual behavior and allows the remaining liquid to form separate pools if cut through. The protagonist needs deformation coupled to motion and contact. Godot SoftBody3D with built-in Jolt is a candidate to inspect before inventing a custom solver, but adhesion and goo flow are not assumed to come for free. No liquid or soft-body implementation is selected yet.

Recommended scale representation: keep documented physical sizes separate from the convenient coordinate units used to render and simulate each active scale band; preserve meaningful size ratios within a scene. This avoids treating the entire growth journey as one simultaneously simulated universe. Cartoon representations at subatomic scales are accepted; do not impose scientific literalism on their appearance.

Source checks on 2026-09-04: Godot spatial shaders provide diffuse_toon and specular_toon modes. Web exports require Compatibility rendering and WebGL 2.0; Forward+/Mobile and C# web exports are not supported by the retrieved stable documentation. Browser delivery is outside the accepted proof of concept, so do not impose those web constraints on the desktop renderer. No renderer, language, or performance outcome is selected or verified yet.

Sources:
- https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html

Optional scale transitions: each level declares zero to two size jumps, with ordinary growth inside each camera view. A jump reveals larger types and retires tiny detail. Edible parts and emergent formations are independent of camera transitions. Candidate data stores jumps as a bounded array rather than three mandatory phases.
