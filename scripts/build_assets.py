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
import sys
import time
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from asset_builders.geometry import (
    consolidate_by_material,
    curve_tube,
    cylinder_between,
    extruded_polygon,
    ico_sphere,
    material,
    mesh_object,
    new_collection,
    torus,
    uv_sphere,
)
from asset_builders.particles import (
    build_electron,
    build_gluon,
    build_neutron,
    build_photon,
    build_pion,
    build_positron,
)
from asset_builders.tide_pool import (
    build_anemone,
    build_boulder,
    build_crab_body,
    build_hermit_crab,
    build_hermit_shell,
    build_periwinkle,
    build_sea_star,
    build_small_fish,
    build_snail,
)
from asset_builders.skatepark import (
    build_bearing,
    build_bench,
    build_bolt,
    build_bottle_cap,
    build_cone,
    build_fence_section,
    build_helmet,
    build_parked_car,
    build_pebble,
    build_rail_bar,
    build_rail_post,
    build_shoe,
    build_skater,
    build_trash_can,
    build_tree,
    build_truck,
    build_water_bottle,
)
from asset_builders.space import (
    build_black_hole,
    build_blue_giant,
    build_dwarf_galaxy,
    build_elliptical_galaxy,
    build_galaxy_arm,
    build_galaxy_bulge,
    build_galaxy_group,
    build_nebula,
    build_red_dwarf,
    build_spiral_galaxy,
    build_supercluster,
    build_yellow_star,
)
from asset_builders.textures import bake_atlas, verify_texture


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "assets" / "models"
SOURCE_DIR = ROOT / "assets" / "source"
MANIFEST_PATH = ROOT / "assets" / "asset_manifest.json"
SOURCE_PATH = SOURCE_DIR / "cartoon_asset_library.blend"

MODEL_COLORS = {
    "rail_post": "#A8B4BE",
    "rail_bar": "#A8B4BE",
    "gluon": "#77D8AD",
    "photon": "#FFE69A",
    "electron": "#79B9E1",
    "positron": "#F8AC73",
    "pion": "#B6989D",
    "neutron": "#7F9BAE",
    "snail": "#C59369",
    "periwinkle": "#C59369",
    "hermit_crab": "#D66E3E",
    "hermit_shell": "#987347",
    "crab_body": "#D58355",
    "anemone": "#DBAD7B",
    "sea_star": "#D89968",
    "small_fish": "#79AEB8",
    "boulder": "#9A9D91",
    "bolt": "#AAB8C1",
    "bearing": "#A6B4BD",
    "bottle_cap": "#C85C4B",
    "pebble": "#A7A18E",
    "truck": "#A8B4BE",
    "helmet": "#DEA754",
    "shoe": "#5B8CC2",
    "water_bottle": "#92BFCC",
    "skater": "#5B9F92",
    "bench": "#B49169",
    "cone": "#E68E43",
    "trash_can": "#69857A",
    "fence_section": "#A6AEAA",
    "parked_car": "#708D9C",
    "tree": "#78996B",
    "red_dwarf": "#BD775E",
    "yellow_star": "#E1CC9E",
    "blue_giant": "#B2CAD7",
    "nebula": "#837A6E",
    "black_hole": "#7F7565",
    "elliptical_galaxy": "#BDB196",
    "dwarf_galaxy": "#87959A",
    "galaxy_group": "#93968B",
    "galaxy_arm": "#897F71",
    "galaxy_bulge": "#D8CCAF",
    "quark": "#F2C94C",
    "proton": "#D96672",
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
    "galaxy": "#ABA695",
    "knot": "#A7ABA4",
}


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


def deck_surface(collection, prefix, center_z, deck_mat, grip_mat, grip):
    xs = [-2.44, -2.39, -2.28, -2.12, -1.92, -1.70, -1.3, -0.7, 0, 0.7, 1.3, 1.70, 1.92, 2.12, 2.28, 2.39, 2.44]
    vertices, faces = [], []
    for x in xs:
        taper = math.sqrt(max(0.01, 1 - (max(0, abs(x) - 1.70) / 0.75) ** 2))
        width = 0.75 * taper * (0.91 if grip else 1)
        rise = 0.22 * max(0, (abs(x) - 1.65) / 0.80) ** 1.7
        for y in (-width, 0, width):
            z = center_z + rise + 0.025 * (y / 0.75) ** 2
            vertices.append((x * (0.985 if grip else 1), y, z + (0.007 if grip else 0)))
    for i in range(len(xs) - 1):
        for j in range(2):
            a = i * 3 + j
            faces.append((a, a + 3, a + 4, a + 1))
    obj = mesh_object(collection, prefix + ("_grip" if grip else "_deck"), vertices, faces, grip_mat if grip else deck_mat)
    if not grip:
        solidify = obj.modifiers.new("Laminated deck thickness", "SOLIDIFY")
        solidify.thickness = 0.10
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier=solidify.name)
        obj.select_set(False)


def deck_body(
    collection: bpy.types.Collection,
    prefix: str,
    center_z: float,
    deck_mat: bpy.types.Material,
    grip_mat: bpy.types.Material,
) -> None:
    # Both surfaces follow the same kicktail profile so the grip stays flush.
    deck_surface(collection, prefix, center_z, deck_mat, grip_mat, False)
    deck_surface(collection, prefix, center_z, deck_mat, grip_mat, True)
    bolt = material("Deck mounting bolts", "#9CA8AA", metallic=0.7)
    for x in (-1.63, -1.31, 1.31, 1.63):
        for y in (-0.23, 0.23):
            uv_sphere(collection, prefix + "_bolt", (x, y, center_z + 0.012), (0.043, 0.043, 0.012), bolt, segments=12, rings=8)
    graphic = material("Deck cream graphic", "#F5DCAE")
    for x in (-0.45, 0.0, 0.45):
        cylinder_between(collection, prefix + "_underside_graphic", (x, -0.52, center_z - 0.108), (x + 0.27, 0.52, center_z - 0.108), 0.065, graphic, vertices=12)


def build_board(collection: bpy.types.Collection) -> None:
    deck = material("Board teal", "#43AFA3", roughness=0.48)
    grip = material("Board grip", "#243C43", roughness=0.84, texture_surface="grip")
    deck_body(collection, "board", 0.18, deck, grip)


def build_skateboard(collection: bpy.types.Collection) -> None:
    deck = material("Skateboard coral", "#E85D4A", roughness=0.45)
    grip = material("Skateboard grip", "#27343B", roughness=0.88, texture_surface="grip")
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


BUILDERS = {
    "rail_post": build_rail_post,
    "rail_bar": build_rail_bar,
    "gluon": build_gluon,
    "photon": build_photon,
    "electron": build_electron,
    "positron": build_positron,
    "pion": build_pion,
    "neutron": build_neutron,
    "snail": build_snail,
    "periwinkle": build_periwinkle,
    "hermit_crab": build_hermit_crab,
    "hermit_shell": build_hermit_shell,
    "crab_body": build_crab_body,
    "anemone": build_anemone,
    "sea_star": build_sea_star,
    "small_fish": build_small_fish,
    "boulder": build_boulder,
    "bolt": build_bolt,
    "bearing": build_bearing,
    "bottle_cap": build_bottle_cap,
    "pebble": build_pebble,
    "truck": build_truck,
    "helmet": build_helmet,
    "shoe": build_shoe,
    "water_bottle": build_water_bottle,
    "skater": build_skater,
    "bench": build_bench,
    "cone": build_cone,
    "trash_can": build_trash_can,
    "fence_section": build_fence_section,
    "parked_car": build_parked_car,
    "tree": build_tree,
    "red_dwarf": build_red_dwarf,
    "yellow_star": build_yellow_star,
    "blue_giant": build_blue_giant,
    "nebula": build_nebula,
    "black_hole": build_black_hole,
    "elliptical_galaxy": build_elliptical_galaxy,
    "dwarf_galaxy": build_dwarf_galaxy,
    "galaxy_group": build_galaxy_group,
    "galaxy_arm": build_galaxy_arm,
    "galaxy_bulge": build_galaxy_bulge,
    "quark": build_quark,
    "proton": build_proton,
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
    "galaxy": build_spiral_galaxy,
    "knot": build_supercluster,
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
    bpy.context.view_layer.update()
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


def export_collection(collection: bpy.types.Collection, model_name: str, output_path: str) -> dict[str, float | str]:
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
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_vertex_color="ACTIVE",
        export_cameras=False,
        export_lights=False,
    )
    return {
        "path": f"res://assets/models/{model_name}.glb",
        "radius": round(radius, 6),
        "height": round(height, 6),
        "color": MODEL_COLORS[model_name],
        "texture": f"res://assets/models/{model_name}.png",
    }


def arrange_source_library(roots: dict[str, bpy.types.Object]) -> None:
    spacing_x = 8.0
    spacing_y = 7.0
    for index, model_name in enumerate(BUILDERS):
        row, column = divmod(index, 8)
        roots[model_name].location += Vector(((column - 3.5) * spacing_x, (3.0 - row) * spacing_y, 0.0))
    bpy.context.scene["asset_library_note"] = (
        "Collection roots are arranged for editing. Generated GLBs were exported with each root at the origin."
    )


def validate_outputs(manifest: dict[str, dict[str, float | str]]) -> None:
    expected = set(BUILDERS)
    if set(manifest) != expected:
        raise RuntimeError(f"Manifest model mismatch: expected {sorted(expected)}, got {sorted(manifest)}")
    for name, entry in manifest.items():
        texture = MODEL_DIR / f"{name}.png"
        if not texture.is_file() or texture.stat().st_size == 0:
            raise RuntimeError(f"Missing texture: {texture}")
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
    verify_texture(name, meshes)
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


def build_grounds(output_dir: str):
    grounds = {
        "ground_particle": ("#A5BBB3", "flat"),
        "ground_sand": ("#C3AE86", "sand"),
        "ground_concrete": ("#A3A79E", "concrete"),
        "ground_space": ("#151D25", "flat"),
    }
    for name, (color, surface) in grounds.items():
        collection = new_collection(name)
        mat = material(name, color, texture_surface=surface)
        mesh_object(collection, name, [(-1, -1, 0), (1, -1, 0), (1, 1, 0), (-1, 1, 0)], [(0, 1, 2, 3)], mat)
        bake_atlas(collection, name, output_dir + "/" + name + ".png")
        # Ground source patches sit apart from the editable model library.
        collection.objects[0].location = (-24, list(grounds).index(name) * 3, 0)


def main() -> None:
    started = time.perf_counter()
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
        bake_atlas(collection, model_name, str(MODEL_DIR / f"{model_name}.png"))
        roots[model_name] = add_root_and_normalize(collection, model_name)

    manifest = {name: export_collection(bpy.data.collections[name], name, str(MODEL_DIR / f"{name}.glb")) for name in BUILDERS}
    validate_outputs(manifest)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    for name, entry in manifest.items():
        collection = bpy.data.collections[name]
        collection["export_path"] = entry["path"]
        collection["godot_radius"] = entry["radius"]
        collection["godot_height"] = entry["height"]
        collection["average_color"] = entry["color"]
    build_grounds(str(MODEL_DIR))
    arrange_source_library(roots)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_PATH), compress=True)
    verify_exported_glbs(manifest)

    print(f"ASSET_BUILD_OK models={len(manifest)} textures={len(manifest)} grounds=4 seconds={time.perf_counter() - started:.3f} source={SOURCE_PATH}")
    for name in manifest:
        print(f"ASSET {name} bytes={(MODEL_DIR / f'{name}.glb').stat().st_size} bounds={manifest[name]['radius']},{manifest[name]['height']}")


if __name__ == "__main__":
    main()
