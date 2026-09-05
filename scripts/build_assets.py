"""Build the original smooth-cartoon asset library with Blender.

Run from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender \
      --background --factory-startup --python-exit-code 1 \
      --python scripts/build_assets.py

The exported GLBs use Blender's glTF Y-up conversion. In Blender coordinates,
X/Y are the ground plane and Z is height; every model is normalized to a
centered ground-plane footprint with its lowest point at Z=0 before export.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "assets" / "models"
SOURCE_DIR = ROOT / "assets" / "source"
MANIFEST_PATH = ROOT / "assets" / "asset_manifest.json"
SOURCE_PATH = SOURCE_DIR / "cartoon_asset_library.blend"

MODEL_COLORS = {
    "quark": "#F2C94C",
    "proton": "#D96672",
    "nucleus": "#A95D72",
    "plankton": "#65D6C1",
    "polyp": "#F58CA8",
    "coral_branch": "#E66F7F",
    "coral_fan": "#CB5D87",
    "rock": "#77828C",
    "shell": "#F2B27D",
    "wheel": "#F2B43A",
    "board": "#43AFA3",
    "skateboard": "#E85D4A",
    "rail": "#A8B4BE",
    "ramp": "#5AA8D8",
    "galaxy": "#796DE2",
    "knot": "#EAA4FF",
}


def rgba(hex_color: str, alpha: float = 1.0) -> tuple[float, float, float, float]:
    value = hex_color.removeprefix("#")
    return tuple(int(value[index : index + 2], 16) / 255 for index in (0, 2, 4)) + (alpha,)


def material(
    name: str,
    color: str,
    *,
    roughness: float = 0.52,
    metallic: float = 0.0,
    alpha: float = 1.0,
    transmission: float = 0.0,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = rgba(color, alpha)
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = rgba(color, alpha)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Alpha"].default_value = alpha
    transmission_input = bsdf.inputs.get("Transmission Weight") or bsdf.inputs.get("Transmission")
    if transmission_input:
        transmission_input.default_value = transmission
    emission_input = bsdf.inputs.get("Emission Color") or bsdf.inputs.get("Emission")
    if emission_input and emission_strength:
        emission_input.default_value = rgba(color)
    if bsdf.inputs.get("Emission Strength"):
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    if alpha < 1.0 and hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "DITHERED"
    return mat


def move_to_collection(obj: bpy.types.Object, collection: bpy.types.Collection) -> None:
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)


def smooth(obj: bpy.types.Object) -> None:
    if obj.type == "MESH":
        for polygon in obj.data.polygons:
            polygon.use_smooth = True


def add_bevel(obj: bpy.types.Object, width: float, segments: int = 3) -> None:
    modifier = obj.modifiers.new("Soft bevel", "BEVEL")
    modifier.width = width
    modifier.segments = segments
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.select_set(False)


def uv_sphere(
    collection: bpy.types.Collection,
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat: bpy.types.Material,
    *,
    segments: int = 24,
    rings: int = 16,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    smooth(obj)
    move_to_collection(obj, collection)
    return obj


def ico_sphere(
    collection: bpy.types.Collection,
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat: bpy.types.Material,
    subdivisions: int = 3,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    smooth(obj)
    move_to_collection(obj, collection)
    return obj


def cylinder_between(
    collection: bpy.types.Collection,
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    radius: float,
    mat: bpy.types.Material,
    *,
    vertices: int = 24,
    bevel: float = 0.0,
) -> bpy.types.Object:
    start_v = Vector(start)
    end_v = Vector(end)
    direction = end_v - start_v
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=direction.length,
        location=(start_v + end_v) * 0.5,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    obj.data.materials.append(mat)
    smooth(obj)
    move_to_collection(obj, collection)
    if bevel:
        add_bevel(obj, bevel)
    return obj


def torus(
    collection: bpy.types.Collection,
    name: str,
    location: tuple[float, float, float],
    major_radius: float,
    minor_radius: float,
    mat: bpy.types.Material,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(
        major_segments=32,
        minor_segments=12,
        major_radius=major_radius,
        minor_radius=minor_radius,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    smooth(obj)
    move_to_collection(obj, collection)
    return obj


def curve_tube(
    collection: bpy.types.Collection,
    name: str,
    points: list[tuple[float, float, float]],
    bevel_depth: float,
    mat: bpy.types.Material,
    *,
    radii: list[float] | None = None,
    cyclic: bool = False,
) -> bpy.types.Object:
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = bevel_depth
    curve.bevel_resolution = 3
    curve.resolution_u = 4
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for index, (bezier_point, coordinate) in enumerate(zip(spline.bezier_points, points)):
        bezier_point.co = coordinate
        bezier_point.handle_left_type = "AUTO"
        bezier_point.handle_right_type = "AUTO"
        if radii:
            bezier_point.radius = radii[index]
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve)
    curve.materials.append(mat)
    collection.objects.link(obj)
    return obj


def mesh_object(
    collection: bpy.types.Collection,
    name: str,
    vertices: list[tuple[float, float, float]],
    faces: list[tuple[int, ...]],
    mat: bpy.types.Material,
    *,
    bevel: float = 0.0,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    mesh.materials.append(mat)
    smooth(obj)
    if bevel:
        add_bevel(obj, bevel)
    return obj


def new_collection(name: str) -> bpy.types.Collection:
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    return collection


def consolidate_by_material(collection: bpy.types.Collection, model_name: str) -> None:
    """Bake curves and merge static geometry that shares one material."""
    for obj in list(collection.objects):
        if obj.type != "CURVE":
            continue
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.convert(target="MESH")

    groups: dict[bpy.types.Material, list[bpy.types.Object]] = {}
    for obj in collection.objects:
        if obj.type != "MESH" or len(obj.data.materials) != 1 or obj.data.materials[0] is None:
            continue
        groups.setdefault(obj.data.materials[0], []).append(obj)

    for mat, objects in groups.items():
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        active = objects[0]
        bpy.context.view_layer.objects.active = active
        if len(objects) > 1:
            bpy.ops.object.join()
        safe_material_name = "_".join(mat.name.lower().split())
        active.name = f"{model_name}_{safe_material_name}"


def build_quark(collection: bpy.types.Collection) -> None:
    gold = material("Quark gold", "#F2C94C", roughness=0.32, emission_strength=0.08)
    coral = material("Quark accent", "#FF6B6B", roughness=0.38)
    navy = material("Quark orbit", "#415A77", metallic=0.15, roughness=0.28)
    uv_sphere(collection, "quark_body", (0, 0, 0.68), (0.64, 0.64, 0.64), gold)
    torus(collection, "quark_orbit", (0, 0, 0.68), 0.82, 0.055, navy, (0.7, 0.0, 0.3))
    uv_sphere(collection, "quark_marker", (0.68, -0.17, 1.12), (0.12, 0.12, 0.12), coral, segments=16, rings=10)


def build_proton(collection: bpy.types.Collection) -> None:
    colors = (
        material("Constituent coral", "#F26B6B", roughness=0.4),
        material("Constituent blue", "#55A7E0", roughness=0.4),
        material("Constituent gold", "#F1C75B", roughness=0.4),
    )
    positions = ((-0.45, -0.23, 0.64), (0.45, -0.23, 0.64), (0.0, 0.42, 0.78))
    for index, (position, mat) in enumerate(zip(positions, colors), 1):
        uv_sphere(collection, f"constituent_{index}", position, (0.64, 0.64, 0.64), mat)


def build_nucleus(collection: bpy.types.Collection) -> None:
    proton_mat = material("Nuclear coral", "#DD647A", roughness=0.48)
    neutron_mat = material("Nuclear indigo", "#6670A8", roughness=0.48)
    positions = [
        (-0.52, -0.38, 0.58),
        (0.05, -0.50, 0.52),
        (0.55, -0.22, 0.62),
        (-0.58, 0.22, 0.68),
        (0.0, 0.10, 0.75),
        (0.58, 0.32, 0.66),
        (-0.25, 0.58, 0.82),
        (0.32, 0.64, 0.86),
        (0.08, 0.18, 1.22),
    ]
    for index, position in enumerate(positions):
        mat = proton_mat if index % 2 == 0 else neutron_mat
        uv_sphere(collection, f"nucleon_{index + 1}", position, (0.48, 0.48, 0.48), mat, segments=20, rings=12)


def build_plankton(collection: bpy.types.Collection) -> None:
    body = material(
        "Plankton membrane",
        "#65D6C1",
        roughness=0.2,
        alpha=0.72,
        transmission=0.22,
    )
    nucleus_mat = material("Plankton nucleus", "#3A8F8B", roughness=0.38)
    flagella = material("Plankton flagella", "#B9F5E8", roughness=0.3, emission_strength=0.05)
    uv_sphere(collection, "plankton_body", (0, 0, 0.52), (0.86, 0.56, 0.46), body)
    uv_sphere(collection, "plankton_nucleus", (-0.18, 0.02, 0.58), (0.24, 0.19, 0.19), nucleus_mat, segments=18, rings=12)
    for index, sign in enumerate((-1, 1)):
        curve_tube(
            collection,
            f"plankton_flagellum_{index + 1}",
            [
                (0.72, sign * 0.22, 0.54),
                (1.10, sign * 0.42, 0.66),
                (1.38, sign * 0.16, 0.46),
                (1.65, sign * 0.36, 0.58),
            ],
            0.035,
            flagella,
            radii=[1.0, 0.8, 0.55, 0.2],
        )
    for index, angle in enumerate((-0.95, -0.48, 0.0, 0.48, 0.95)):
        start = (-0.70, math.sin(angle) * 0.34, 0.52 + math.cos(angle) * 0.1)
        end = (-1.12, math.sin(angle) * 0.66, 0.42 + math.cos(angle) * 0.24)
        curve_tube(collection, f"plankton_cilia_{index + 1}", [start, end], 0.025, flagella, radii=[0.75, 0.15])


def build_polyp(collection: bpy.types.Collection) -> None:
    body = material("Polyp body", "#F58CA8", roughness=0.5)
    tip = material("Polyp tips", "#FFE0C7", roughness=0.42)
    uv_sphere(collection, "polyp_base", (0, 0, 0.26), (0.65, 0.65, 0.28), body)
    uv_sphere(collection, "polyp_column", (0, 0, 0.72), (0.48, 0.48, 0.62), body)
    uv_sphere(collection, "polyp_mouth", (0, 0, 1.30), (0.24, 0.24, 0.12), tip, segments=20, rings=12)
    for index in range(8):
        angle = math.tau * index / 8
        direction = Vector((math.cos(angle), math.sin(angle), 0))
        points = [
            tuple(direction * 0.18 + Vector((0, 0, 1.28))),
            tuple(direction * 0.50 + Vector((0, 0, 1.52))),
            tuple(direction * 0.82 + Vector((0, 0, 1.48 + 0.10 * (index % 2)))),
            tuple(direction * 1.04 + Vector((0, 0, 1.31))),
        ]
        curve_tube(collection, f"tentacle_{index + 1}", points, 0.095, body, radii=[1.2, 1.0, 0.65, 0.25])
        uv_sphere(collection, f"tentacle_tip_{index + 1}", points[-1], (0.07, 0.07, 0.07), tip, segments=12, rings=8)


def add_coral_attachment(
    collection: bpy.types.Collection,
    name: str,
    location: tuple[float, float, float],
    body: bpy.types.Material,
    tip: bpy.types.Material,
) -> None:
    uv_sphere(collection, f"{name}_cup", location, (0.20, 0.20, 0.13), body, segments=16, rings=10)
    uv_sphere(
        collection,
        f"{name}_center",
        (location[0], location[1], location[2] + 0.11),
        (0.09, 0.09, 0.07),
        tip,
        segments=12,
        rings=8,
    )


def build_coral_branch(collection: bpy.types.Collection) -> None:
    coral = material("Branch coral", "#E66F7F", roughness=0.56)
    highlight = material("Branch polyp sites", "#FFD0B7", roughness=0.42)
    base = material("Coral base", "#866B70", roughness=0.7)
    ico_sphere(collection, "coral_base", (0, 0, 0.25), (0.88, 0.68, 0.30), base, subdivisions=2)
    paths = [
        [(0, 0, 0.32), (-0.08, 0.0, 1.15), (0.12, 0.04, 2.10), (0.02, 0.0, 3.15)],
        [(-0.02, 0, 1.10), (-0.62, 0.06, 1.55), (-0.92, 0.08, 2.32)],
        [(0.05, 0, 1.55), (0.68, -0.05, 2.02), (1.02, -0.02, 2.76)],
        [(-0.32, 0.03, 1.42), (-0.76, -0.02, 1.88), (-1.32, -0.02, 1.92)],
        [(0.50, -0.03, 1.92), (0.92, 0.04, 2.22), (1.38, 0.08, 2.18)],
    ]
    for index, path in enumerate(paths):
        curve_tube(collection, f"coral_branch_{index + 1}", path, 0.18, coral, radii=[1.25, 0.85, 0.52, 0.32][: len(path)])
        add_coral_attachment(collection, f"branch_site_{index + 1}", path[-1], coral, highlight)
    add_coral_attachment(collection, "branch_site_mid", (-0.77, 0.05, 1.78), coral, highlight)


def build_coral_fan(collection: bpy.types.Collection) -> None:
    coral = material("Fan coral", "#CB5D87", roughness=0.52)
    edge = material("Fan coral tips", "#F7A6B8", roughness=0.45)
    base = material("Fan coral base", "#7C6673", roughness=0.72)
    ico_sphere(collection, "fan_base", (0, 0, 0.24), (1.0, 0.56, 0.28), base, subdivisions=2)
    endpoints: list[tuple[float, float, float]] = []
    for index in range(9):
        t = index / 8
        x = -2.35 + 4.70 * t
        z = 2.45 + 1.02 * math.sin(math.pi * t)
        endpoint = (x, 0.0, z)
        endpoints.append(endpoint)
        bend = (x * 0.38, 0.05 * (-1) ** index, 1.42 + 0.28 * math.sin(math.pi * t))
        curve_tube(
            collection,
            f"fan_ray_{index + 1}",
            [(0, 0, 0.35), bend, endpoint],
            0.105,
            coral,
            radii=[1.35, 0.82, 0.34],
        )
        uv_sphere(collection, f"fan_tip_{index + 1}", endpoint, (0.14, 0.11, 0.14), edge, segments=14, rings=8)
    for band in (0.48, 0.70):
        points = []
        for index, endpoint in enumerate(endpoints):
            x = endpoint[0] * band
            z = 0.42 + (endpoint[2] - 0.20) * band
            points.append((x, 0.0, z))
        curve_tube(collection, f"fan_crosslink_{int(band * 100)}", points, 0.07, edge, radii=[0.8] * len(points))


def build_rock(collection: bpy.types.Collection) -> None:
    stone = material("Rock slate", "#77828C", roughness=0.86)
    facet = material("Rock warm face", "#92989B", roughness=0.82)
    rock = ico_sphere(collection, "rounded_rock", (0, 0, 0.66), (1.24, 0.92, 0.70), stone, subdivisions=3)
    rock.rotation_euler = (0.08, -0.14, 0.22)
    uv_sphere(collection, "rock_highlight", (-0.37, -0.55, 0.86), (0.48, 0.16, 0.26), facet, segments=20, rings=10)


def extruded_polygon(
    collection: bpy.types.Collection,
    name: str,
    outline: list[tuple[float, float]],
    z_bottom: float,
    z_top: float,
    mat: bpy.types.Material,
    bevel: float,
) -> bpy.types.Object:
    vertices = [(x, y, z_bottom) for x, y in outline] + [(x, y, z_top) for x, y in outline]
    count = len(outline)
    faces: list[tuple[int, ...]] = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    for index in range(count):
        next_index = (index + 1) % count
        faces.append((index, next_index, next_index + count, index + count))
    return mesh_object(collection, name, vertices, faces, mat, bevel=bevel)


def build_shell(collection: bpy.types.Collection) -> None:
    shell = material("Shell peach", "#F2B27D", roughness=0.5)
    rib = material("Shell ribs", "#FFE0B0", roughness=0.4)
    outline = [(0.0, -1.05)]
    for index in range(13):
        angle = math.radians(-75 + index * 12.5)
        radius = 1.78 + 0.10 * (index % 2)
        outline.append((math.sin(angle) * radius, math.cos(angle) * radius * 0.88 - 0.15))
    outline.reverse()
    extruded_polygon(collection, "shell_body", outline, 0.0, 0.22, shell, 0.12)
    hinge = (0.0, -0.92, 0.29)
    for index, angle_degrees in enumerate((-64, -43, -22, 0, 22, 43, 64)):
        angle = math.radians(angle_degrees)
        end = (math.sin(angle) * 1.60, math.cos(angle) * 1.42 - 0.15, 0.29)
        middle = ((hinge[0] + end[0]) * 0.48, (hinge[1] + end[1]) * 0.48, 0.43)
        curve_tube(collection, f"shell_rib_{index + 1}", [hinge, middle, end], 0.045, rib, radii=[0.65, 1.0, 0.18])
    uv_sphere(collection, "shell_hinge", hinge, (0.22, 0.16, 0.13), rib, segments=18, rings=10)


def build_wheel_parts(
    collection: bpy.types.Collection,
    prefix: str,
    center: tuple[float, float, float],
    wheel_mat: bpy.types.Material,
    hub_mat: bpy.types.Material,
    radius: float = 0.52,
    width: float = 0.54,
) -> None:
    x, y, z = center
    cylinder_between(collection, f"{prefix}_urethane", (x, y - width / 2, z), (x, y + width / 2, z), radius, wheel_mat, vertices=32, bevel=0.08)
    for sign in (-1, 1):
        face_y = y + sign * (width / 2 + 0.012)
        cylinder_between(
            collection,
            f"{prefix}_bearing_{'left' if sign < 0 else 'right'}",
            (x, face_y - sign * 0.025, z),
            (x, face_y + sign * 0.025, z),
            radius * 0.23,
            hub_mat,
            vertices=24,
            bevel=0.015,
        )


def build_wheel(collection: bpy.types.Collection) -> None:
    urethane = material("Wheel gold", "#F2B43A", roughness=0.46)
    hub = material("Wheel bearing", "#59656F", metallic=0.65, roughness=0.22)
    build_wheel_parts(collection, "wheel", (0, 0, 0.54), urethane, hub)


def deck_body(
    collection: bpy.types.Collection,
    prefix: str,
    center_z: float,
    deck_mat: bpy.types.Material,
    grip_mat: bpy.types.Material,
) -> None:
    xs = [-2.45, -2.1, -1.65, -0.9, 0.0, 0.9, 1.65, 2.1, 2.45]
    vertices: list[tuple[float, float, float]] = []
    for x in xs:
        rise = 0.30 * max(0.0, (abs(x) - 1.60) / 0.85) ** 2
        half_width = 0.78 * (1.0 - 0.10 * (abs(x) / 2.45) ** 2)
        vertices.extend(
            [
                (x, -half_width, center_z + rise - 0.09),
                (x, half_width, center_z + rise - 0.09),
                (x, -half_width, center_z + rise + 0.09),
                (x, half_width, center_z + rise + 0.09),
            ]
        )
    faces: list[tuple[int, ...]] = []
    for index in range(len(xs) - 1):
        a = index * 4
        b = (index + 1) * 4
        faces.extend(
            [
                (a + 2, b + 2, b + 3, a + 3),
                (a, a + 1, b + 1, b),
                (a, b, b + 2, a + 2),
                (a + 1, a + 3, b + 3, b + 1),
            ]
        )
    faces.extend([(0, 2, 3, 1), (len(vertices) - 4, len(vertices) - 3, len(vertices) - 1, len(vertices) - 2)])
    mesh_object(collection, f"{prefix}_deck", vertices, faces, deck_mat, bevel=0.065)
    grip_points = []
    for x in xs[1:-1]:
        rise = 0.30 * max(0.0, (abs(x) - 1.60) / 0.85) ** 2
        half_width = 0.66 * (1.0 - 0.08 * (abs(x) / 2.45) ** 2)
        grip_points.extend([(x, -half_width, center_z + rise + 0.145), (x, half_width, center_z + rise + 0.145)])
    grip_faces = []
    for index in range(len(xs[1:-1]) - 1):
        a = index * 2
        grip_faces.append((a, a + 2, a + 3, a + 1))
    grip = mesh_object(collection, f"{prefix}_grip", grip_points, grip_faces, grip_mat)
    solidify = grip.modifiers.new("Grip thickness", "SOLIDIFY")
    solidify.thickness = 0.025
    bpy.context.view_layer.objects.active = grip
    grip.select_set(True)
    bpy.ops.object.modifier_apply(modifier=solidify.name)
    grip.select_set(False)


def build_board(collection: bpy.types.Collection) -> None:
    deck = material("Board teal", "#43AFA3", roughness=0.48)
    grip = material("Board grip", "#243C43", roughness=0.84)
    deck_body(collection, "board", 0.18, deck, grip)


def build_skateboard(collection: bpy.types.Collection) -> None:
    deck = material("Skateboard coral", "#E85D4A", roughness=0.45)
    grip = material("Skateboard grip", "#27343B", roughness=0.88)
    metal = material("Truck metal", "#A8B4BE", roughness=0.30, metallic=0.72)
    wheel_mat = material("Skate wheel mint", "#68D6B4", roughness=0.42)
    bearing = material("Skate bearing", "#59656F", metallic=0.7, roughness=0.2)
    deck_body(collection, "skateboard", 0.72, deck, grip)
    for axle_index, x in enumerate((-1.48, 1.48), 1):
        cylinder_between(collection, f"truck_post_{axle_index}", (x, 0, 0.30), (x, 0, 0.62), 0.13, metal, bevel=0.025)
        cylinder_between(collection, f"truck_axle_{axle_index}", (x, -0.92, 0.30), (x, 0.92, 0.30), 0.10, metal, bevel=0.025)
        for side_index, y in enumerate((-0.96, 0.96), 1):
            build_wheel_parts(collection, f"skate_wheel_{axle_index}_{side_index}", (x, y, 0.30), wheel_mat, bearing, radius=0.31, width=0.28)


def build_rail(collection: bpy.types.Collection) -> None:
    steel = material("Rail steel", "#A8B4BE", roughness=0.22, metallic=0.76)
    feet = material("Rail feet", "#6D7982", roughness=0.38, metallic=0.52)
    cylinder_between(collection, "rail_bar", (-2.3, 0, 1.18), (2.3, 0, 1.18), 0.13, steel, vertices=32, bevel=0.025)
    for index, x in enumerate((-1.55, 1.55), 1):
        cylinder_between(collection, f"rail_leg_{index}", (x, 0, 0.12), (x, 0, 1.18), 0.105, steel, bevel=0.02)
        cylinder_between(collection, f"rail_foot_{index}", (x, -0.48, 0.08), (x, 0.48, 0.08), 0.11, feet, bevel=0.025)


def build_ramp(collection: bpy.types.Collection) -> None:
    ramp_mat = material("Ramp blue", "#5AA8D8", roughness=0.54)
    coping = material("Ramp coping", "#B9C3CA", roughness=0.22, metallic=0.68)
    sample_count = 13
    width = 3.6
    length = 4.8
    height = 2.35
    thickness = 0.16
    vertices: list[tuple[float, float, float]] = []
    for index in range(sample_count):
        t = index / (sample_count - 1)
        angle = t * math.pi / 2
        x = -length / 2 + math.sin(angle) * length
        z = height * (1.0 - math.cos(angle)) + thickness
        vertices.extend([(x, -width / 2, 0.0), (x, width / 2, 0.0), (x, -width / 2, z), (x, width / 2, z)])
    faces: list[tuple[int, ...]] = []
    for index in range(sample_count - 1):
        a = index * 4
        b = (index + 1) * 4
        faces.extend(
            [
                (a + 2, b + 2, b + 3, a + 3),
                (a, a + 1, b + 1, b),
                (a, b, b + 2, a + 2),
                (a + 1, a + 3, b + 3, b + 1),
            ]
        )
    faces.extend([(0, 2, 3, 1), (len(vertices) - 4, len(vertices) - 3, len(vertices) - 1, len(vertices) - 2)])
    mesh_object(collection, "quarter_pipe", vertices, faces, ramp_mat, bevel=0.055)
    high_x = -length / 2 + length
    high_z = height + thickness
    cylinder_between(collection, "ramp_coping", (high_x, -width / 2 - 0.04, high_z), (high_x, width / 2 + 0.04, high_z), 0.12, coping, vertices=32, bevel=0.02)


def build_galaxy(collection: bpy.types.Collection) -> None:
    core = material("Galaxy core", "#FFF3C4", roughness=0.28, emission_strength=0.8)
    violet = material("Galaxy violet", "#796DE2", roughness=0.36, emission_strength=0.38)
    cyan = material("Galaxy cyan", "#62D5E8", roughness=0.34, emission_strength=0.42)
    uv_sphere(collection, "galaxy_core", (0, 0, 0.30), (0.82, 0.82, 0.28), core, segments=28, rings=16)
    uv_sphere(collection, "galaxy_inner_glow", (0, 0, 0.24), (1.28, 1.28, 0.15), violet, segments=28, rings=12)
    for arm in range(4):
        points = []
        radii = []
        for index in range(18):
            t = index / 17
            angle = arm * math.tau / 4 + t * math.tau * 1.15
            radius = 0.46 + 2.85 * t
            points.append((math.cos(angle) * radius, math.sin(angle) * radius, 0.24 + 0.05 * math.sin(angle * 2)))
            radii.append(1.35 - 1.10 * t)
        curve_tube(collection, f"spiral_arm_{arm + 1}", points, 0.16, violet if arm % 2 == 0 else cyan, radii=radii)
    for index in range(16):
        angle = index * 2.399963
        radius = 0.72 + (index % 5) * 0.48
        location = (math.cos(angle) * radius, math.sin(angle) * radius, 0.31 + 0.04 * (index % 3))
        star_mat = core if index % 4 == 0 else cyan
        ico_sphere(collection, f"galaxy_star_{index + 1}", location, (0.07, 0.07, 0.07), star_mat, subdivisions=2)


def build_knot(collection: bpy.types.Collection) -> None:
    knot_mat = material("Cosmic knot", "#EAA4FF", roughness=0.25, metallic=0.08, emission_strength=0.62)
    accent = material("Cosmic knot accent", "#79E4FF", roughness=0.28, emission_strength=0.52)
    points = []
    samples = 72
    for index in range(samples):
        t = math.tau * index / samples
        radius = 1.46 + 0.44 * math.cos(3 * t)
        points.append((radius * math.cos(2 * t), radius * math.sin(2 * t), 0.88 * math.sin(3 * t)))
    curve_tube(collection, "trefoil_knot", points, 0.27, knot_mat, radii=[1.0] * samples, cyclic=True)
    torus(collection, "knot_halo", (0, 0, 0), 1.06, 0.055, accent, (0.18, 0.0, 0.0))
    uv_sphere(collection, "knot_core", (0, 0, 0), (0.24, 0.24, 0.24), accent, segments=20, rings=12)


BUILDERS = {
    "quark": build_quark,
    "proton": build_proton,
    "nucleus": build_nucleus,
    "plankton": build_plankton,
    "polyp": build_polyp,
    "coral_branch": build_coral_branch,
    "coral_fan": build_coral_fan,
    "rock": build_rock,
    "shell": build_shell,
    "wheel": build_wheel,
    "board": build_board,
    "skateboard": build_skateboard,
    "rail": build_rail,
    "ramp": build_ramp,
    "galaxy": build_galaxy,
    "knot": build_knot,
}


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)


def collection_bounds(collection: bpy.types.Collection) -> tuple[Vector, Vector]:
    return object_bounds(collection.all_objects)


def object_bounds(objects: list[bpy.types.Object] | bpy.types.bpy_prop_collection) -> tuple[Vector, Vector]:
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    corners: list[Vector] = []
    for obj in objects:
        if obj.type not in {"MESH", "CURVE", "SURFACE", "FONT"}:
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        corners.extend(evaluated.matrix_world @ vertex.co for vertex in mesh.vertices)
        evaluated.to_mesh_clear()
    if not corners:
        raise RuntimeError("Object set has no renderable geometry")
    minimum = Vector((min(point.x for point in corners), min(point.y for point in corners), min(point.z for point in corners)))
    maximum = Vector((max(point.x for point in corners), max(point.y for point in corners), max(point.z for point in corners)))
    return minimum, maximum


def add_root_and_normalize(collection: bpy.types.Collection, model_name: str) -> bpy.types.Object:
    root = bpy.data.objects.new(f"{model_name}_ROOT", None)
    root.empty_display_type = "CIRCLE"
    root.empty_display_size = 0.45
    collection.objects.link(root)
    for obj in list(collection.objects):
        if obj == root or obj.parent is not None:
            continue
        world = obj.matrix_world.copy()
        obj.parent = root
        obj.matrix_world = world
    minimum, maximum = collection_bounds(collection)
    root.location += Vector((-(minimum.x + maximum.x) / 2, -(minimum.y + maximum.y) / 2, -minimum.z))
    bpy.context.view_layer.update()
    return root


def export_collection(collection: bpy.types.Collection, model_name: str) -> dict[str, float | str]:
    minimum, maximum = collection_bounds(collection)
    width_x = maximum.x - minimum.x
    width_y = maximum.y - minimum.y
    height = maximum.z - minimum.z
    radius = max(width_x, width_y) / 2
    if radius <= 0 or height <= 0:
        raise RuntimeError(f"Invalid bounds for {model_name}: radius={radius}, height={height}")

    bpy.ops.object.select_all(action="DESELECT")
    for obj in collection.all_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next((obj for obj in collection.all_objects if obj.type == "MESH"), None)
    output_path = MODEL_DIR / f"{model_name}.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_cameras=False,
        export_lights=False,
    )
    return {
        "path": f"res://assets/models/{model_name}.glb",
        "radius": round(radius, 6),
        "height": round(height, 6),
        "color": MODEL_COLORS[model_name],
    }


def arrange_source_library(roots: dict[str, bpy.types.Object]) -> None:
    spacing_x = 8.0
    spacing_y = 7.0
    for index, model_name in enumerate(BUILDERS):
        row, column = divmod(index, 4)
        roots[model_name].location += Vector(((column - 1.5) * spacing_x, (1.5 - row) * spacing_y, 0.0))
    bpy.context.scene["asset_library_note"] = (
        "Collection roots are arranged for editing. Generated GLBs were exported with each root at the origin."
    )


def validate_outputs(manifest: dict[str, dict[str, float | str]]) -> None:
    expected = set(BUILDERS)
    if set(manifest) != expected:
        raise RuntimeError(f"Manifest model mismatch: expected {sorted(expected)}, got {sorted(manifest)}")
    for name, entry in manifest.items():
        path = MODEL_DIR / f"{name}.glb"
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Missing or empty GLB: {path}")
        if entry["radius"] <= 0 or entry["height"] <= 0:
            raise RuntimeError(f"Non-positive bounds for {name}: {entry}")
        collection = bpy.data.collections.get(name)
        if collection is None or not any(obj.type in {"MESH", "CURVE"} for obj in collection.all_objects):
            raise RuntimeError(f"No source geometry for {name}")


def color_as_hex(color: tuple[float, float, float, float]) -> str:
    channels = [max(0, min(255, round(channel * 255))) for channel in color[:3]]
    return "#" + "".join(f"{channel:02X}" for channel in channels)


def verify_exported_geometry(name: str, imported: list[bpy.types.Object]) -> None:
    meshes = [obj for obj in imported if obj.type == "MESH"]
    if not meshes or any(len(obj.data.vertices) == 0 or len(obj.data.polygons) == 0 for obj in meshes):
        raise RuntimeError(f"Round-trip produced empty mesh geometry for {name}")
    materials = {slot.material for obj in meshes for slot in obj.material_slots if slot.material is not None}
    if not materials:
        raise RuntimeError(f"Round-trip produced no materials for {name}")
    material_summary = ",".join(
        f"{mat.name}:{color_as_hex(tuple(mat.diffuse_color))}" for mat in sorted(materials, key=lambda item: item.name)
    )
    mesh_names = ",".join(sorted(obj.name for obj in meshes))
    print(
        f"VERIFY {name} meshes={len(meshes)} vertices={sum(len(obj.data.vertices) for obj in meshes)} "
        f"names={mesh_names} materials={material_summary}"
    )


def verify_exported_bounds(name: str, imported: list[bpy.types.Object], entry: dict[str, float | str]) -> None:
    minimum, maximum = object_bounds(imported)
    center_x = (minimum.x + maximum.x) / 2
    center_y = (minimum.y + maximum.y) / 2
    measured_radius = max(maximum.x - minimum.x, maximum.y - minimum.y) / 2
    measured_height = maximum.z - minimum.z
    tolerance = 0.002
    if abs(center_x) > tolerance or abs(center_y) > tolerance or abs(minimum.z) > tolerance:
        raise RuntimeError(f"Export origin mismatch for {name}: center=({center_x}, {center_y}), base={minimum.z}")
    if abs(measured_radius - float(entry["radius"])) > tolerance:
        raise RuntimeError(f"Export radius mismatch for {name}: manifest={entry['radius']}, measured={measured_radius}")
    if abs(measured_height - float(entry["height"])) > tolerance:
        raise RuntimeError(f"Export height mismatch for {name}: manifest={entry['height']}, measured={measured_height}")


def verify_exported_glbs(manifest: dict[str, dict[str, float | str]]) -> None:
    """Round-trip each GLB through Blender and verify exported geometry/data."""
    for name, entry in manifest.items():
        existing_objects = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=str(MODEL_DIR / f"{name}.glb"))
        imported = [obj for obj in bpy.data.objects if obj not in existing_objects]
        verify_exported_geometry(name, imported)
        verify_exported_bounds(name, imported, entry)
        for obj in imported:
            bpy.data.objects.remove(obj, do_unlink=True)


def main() -> None:
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    clear_scene()
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    bpy.context.scene.world.color = (0.035, 0.045, 0.065)
    bpy.context.preferences.filepaths.save_version = 0

    roots: dict[str, bpy.types.Object] = {}
    for model_name, builder in BUILDERS.items():
        collection = new_collection(model_name)
        builder(collection)
        consolidate_by_material(collection, model_name)
        roots[model_name] = add_root_and_normalize(collection, model_name)

    manifest = {name: export_collection(bpy.data.collections[name], name) for name in BUILDERS}
    validate_outputs(manifest)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    for name, entry in manifest.items():
        collection = bpy.data.collections[name]
        collection["export_path"] = entry["path"]
        collection["godot_radius"] = entry["radius"]
        collection["godot_height"] = entry["height"]
        collection["average_color"] = entry["color"]
    arrange_source_library(roots)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_PATH), compress=True)
    verify_exported_glbs(manifest)

    print(f"ASSET_BUILD_OK models={len(manifest)} source={SOURCE_PATH}")
    for name in manifest:
        print(f"ASSET {name} bytes={(MODEL_DIR / f'{name}.glb').stat().st_size} bounds={manifest[name]['radius']},{manifest[name]['height']}")


if __name__ == "__main__":
    main()
