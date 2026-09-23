"""Skatepark hardware, gear, people, and background objects."""
from __future__ import annotations

import math
import bpy
from mathutils import Vector
from .geometry import (
    box,
    curve_tube,
    cylinder_between,
    ico_sphere,
    material,
    mesh_object,
    move_to_collection,
    smooth,
    torus,
    uv_sphere,
)


def build_bolt(collection):
    steel = material("Bolt galvanized", "#AAB8C1", metallic=0.7)
    cylinder_between(collection, "bolt_shaft", (0, 0, 0.10), (0, 0, 1.02), 0.14, steel)
    cylinder_between(collection, "bolt_hex_head", (0, 0, 1.0), (0, 0, 1.25), 0.30, steel, vertices=6, bevel=0.025)
    for i in range(7):
        torus(collection, "bolt_thread", (0, 0, 0.20 + i * 0.105), 0.14, 0.035, steel)


def build_bearing(collection):
    steel = material("Bearing steel", "#A6B4BD", metallic=0.75)
    dark = material("Bearing race", "#52636E")
    torus(collection, "bearing_outer_race", (0, 0, 0.15), 0.64, 0.12, steel)
    torus(collection, "bearing_inner_race", (0, 0, 0.15), 0.29, 0.085, dark)
    for i in range(8):
        a = i * math.tau / 8
        uv_sphere(collection, "bearing_ball", (math.cos(a) * 0.46, math.sin(a) * 0.46, 0.15), (0.11, 0.11, 0.11), steel, segments=12, rings=8)


def build_bottle_cap(collection):
    red = material("Bottle cap enamel", "#C85C4B")
    metal = material("Cap crimp edge", "#D6C7B2", metallic=0.4)
    cylinder_between(collection, "cap_top", (0, 0, 0.10), (0, 0, 0.27), 0.54, red, vertices=32, bevel=0.035)
    for i in range(20):
        a = i * math.tau / 20
        cylinder_between(collection, "cap_crimp", (math.cos(a) * 0.54, math.sin(a) * 0.54, 0.05), (math.cos(a) * 0.54, math.sin(a) * 0.54, 0.22), 0.048, metal, vertices=8)
    torus(collection, "cap_stamp", (0, 0, 0.28), 0.21, 0.025, metal)


def build_pebble(collection):
    stone = material("Pebble pale aggregate", "#A7A18E")
    ico_sphere(collection, "pebble", (0, 0, 0.23), (0.65, 0.47, 0.30), stone, subdivisions=2)


def build_truck(collection):
    metal = material("Truck brushed metal", "#A8B4BE", metallic=0.6)
    rubber = material("Truck bushings", "#BF8C58")
    box(collection, "truck_baseplate", (0, 0, 0.39), (0.39, 0.32, 0.05), metal, 0.045)
    cylinder_between(collection, "truck_kingpin", (0, 0, 0.34), (0.1, 0, 0.18), 0.12, rubber)
    cylinder_between(collection, "truck_axle", (0.1, -0.88, 0.16), (0.1, 0.88, 0.16), 0.10, metal, bevel=0.02)
    box(collection, "truck_hanger", (0.1, 0, 0.18), (0.17, 0.51, 0.12), metal, 0.06)


def build_helmet(collection):
    shell = material("Helmet ochre", "#DEA754")
    rim = material("Helmet padding", "#394951")
    uv_sphere(collection, "helmet_dome", (0, 0, 0.41), (0.87, 0.77, 0.67), shell)
    torus(collection, "helmet_rim", (0, 0, 0.18), 0.68, 0.095, rim)
    for x in (-0.32, 0, 0.32):
        points = [(x, y, 0.425 + 0.67 * math.sqrt(1 - (x / 0.87) ** 2 - (y / 0.77) ** 2)) for y in (-0.25, 0, 0.25)]
        curve_tube(collection, "helmet_vent", points, 0.036, rim)
    curve_tube(collection, "helmet_strap", [(-0.57, 0, 0.20), (-0.24, 0, -0.25), (0.30, 0, -0.25), (0.60, 0, 0.20)], 0.045, rim)


SHOE_STATIONS = [math.sin(u * math.pi / 2) for u in [-0.97 + 1.94 * i / 30 for i in range(31)]]
SHOE_HEIGHTS = [0.0, 0.2, 0.4, 0.55, 0.7, 0.8, 0.88, 0.94, 0.98]


def _shoe_half_width(x):
    ball = 0.07 * math.exp(-((x - 0.35) / 0.35) ** 2)
    waist = 0.07 * math.exp(-((x + 0.15) / 0.28) ** 2)
    heel = 0.04 * math.exp(-((x + 0.8) / 0.25) ** 2)
    # A rounder heel and a squarer toe, like a real last.
    end = (1 - x * x) ** 0.5 if x < 0 else (1 - x ** 3) ** (1 / 3)
    return (0.37 + ball - waist - heel) * end


def _shoe_lift(x):
    # Toe spring and a slightly rounded heel keep the sole from reading as a flat slab.
    return 0.10 * max(0.0, (x - 0.45) / 0.55) ** 2 + 0.03 * max(0.0, (-x - 0.7) / 0.3) ** 2


def _shoe_top(x):
    profile = [(-1.0, 0.48), (-0.85, 0.54), (-0.45, 0.52), (-0.12, 0.57), (0.2, 0.47), (0.55, 0.33), (0.85, 0.25), (1.0, 0.2)]
    for (x0, z0), (x1, z1) in zip(profile, profile[1:]):
        if x <= x1:
            return _shoe_lift(x) + z0 + (z1 - z0) * (x - x0) / (x1 - x0)
    return _shoe_lift(x) + profile[-1][1]


def _shoe_upper_point(x, v, side, offset=0.0):
    bottom = _shoe_lift(x) + 0.10
    width = _shoe_half_width(x) * (1 - v ** 4) ** (1 / 4)
    return Vector((x, side * (width + offset), bottom + v * (_shoe_top(x) - bottom)))


def _shoe_normal(x, v, side):
    along = _shoe_upper_point(x + 0.01, v, side) - _shoe_upper_point(x - 0.01, v, side)
    up = _shoe_upper_point(x, min(v + 0.01, 1.0), side) - _shoe_upper_point(x, max(v - 0.01, 0.0), side)
    normal = along.cross(up).normalized() * side
    return normal if normal.length > 0 else Vector((0, 0, 1))


def _ribbon(collection, name, path, normals, half_widths, mat):
    """A thin flat strip laid on a surface, for trim that should read as printed rather than tubular."""
    vertices, faces = [], []
    for index, (point, normal, half_width) in enumerate(zip(path, normals, half_widths)):
        tangent = path[min(index + 1, len(path) - 1)] - path[max(index - 1, 0)]
        across = tangent.cross(normal).normalized() * half_width
        vertices += [tuple(point - across), tuple(point + across)]
        if index:
            faces.append((index * 2 - 2, index * 2 - 1, index * 2 + 1, index * 2))
    obj = mesh_object(collection, name, vertices, faces, mat)
    solidify = obj.modifiers.new("Printed thickness", "SOLIDIFY")
    solidify.thickness = 0.005
    solidify.offset = 1.0
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=solidify.name)
    return obj


def _loft_faces(ring_count, count, material_for):
    faces, panels = [], []
    for i in range(ring_count - 1):
        for j in range(count):
            a, b = i * count + j, i * count + (j + 1) % count
            faces.append((a, b, b + count, a + count))
            panels.append(material_for(i))
    # Each end closes with a fan to the ring's center, stored after all ring vertices.
    for end, index in enumerate((0, ring_count - 1)):
        center = ring_count * count + end
        for j in range(count):
            a, b = index * count + j, index * count + (j + 1) % count
            faces.append((b, a, center) if index == 0 else (a, b, center))
            panels.append(material_for(index))
    return faces, panels


def _soften(obj, split_panels):
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    modifier = obj.modifiers.new("Soft loft", "SUBSURF")
    modifier.levels = 2
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    smooth(obj)
    if split_panels:
        # Each panel becomes its own UV island, so the baked atlas keeps a crisp seam.
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.separate(type="MATERIAL")
        bpy.ops.object.mode_set(mode="OBJECT")


def _loft(collection, name, rings, mats, material_for):
    """Join cross-section rings into a capped, subdivided tube along X."""
    count = len(rings[0])
    vertices = [tuple(point) for ring in rings for point in ring]
    vertices += [tuple(sum((Vector(point) for point in ring), Vector()) / count) for ring in (rings[0], rings[-1])]
    faces, panels = _loft_faces(len(rings), count, material_for)
    obj = mesh_object(collection, name, vertices, faces, mats[0])
    for mat in mats[1:]:
        obj.data.materials.append(mat)
    # Panels follow whole rings, so their seams stay clean lines after subdivision.
    for polygon, panel in zip(obj.data.polygons, panels):
        polygon.material_index = panel
    _soften(obj, len(mats) > 1)
    return obj


def _sole_ring(x):
    width, low = _shoe_half_width(x) * 1.08 + 0.03, _shoe_lift(x)
    ring = []
    for j in range(28):
        a = j * math.tau / 28
        c, s = math.cos(a), math.sin(a)
        ring.append((x * 1.025, width * math.copysign(abs(c) ** 0.25, c), low + 0.09 + 0.09 * math.copysign(abs(s) ** 0.25, s)))
    return ring


def _upper_ring(x):
    right = [_shoe_upper_point(x, v, 1) for v in SHOE_HEIGHTS]
    left = [_shoe_upper_point(x, v, -1) for v in reversed(SHOE_HEIGHTS)]
    return right + [(x, 0.0, _shoe_top(x))] + left + [(x, 0.0, _shoe_lift(x) + 0.10)]


def _shoe_panel(station):
    x = SHOE_STATIONS[station]
    return 1 if x > 0.55 else 0


def _shoe_body(collection):
    canvas = material("Shoe denim canvas", "#5B8CC2", roughness=0.9)
    suede = material("Shoe suede panels", "#4C7DB0", roughness=0.95)
    cream = material("Shoe rubber sole", "#EFE3C4", roughness=0.7)
    foxing = material("Shoe sole line", "#B44A3A")
    _loft(collection, "shoe_sole", [_sole_ring(x) for x in SHOE_STATIONS], [cream], lambda station: 0)
    _loft(collection, "shoe_upper", [_upper_ring(x) for x in SHOE_STATIONS], [canvas, suede], _shoe_panel)
    line = [(x * 1.025, side * (_shoe_half_width(x) * 1.08 + 0.035), _shoe_lift(x) + 0.06)
            for side in (1, -1) for x in (SHOE_STATIONS if side > 0 else SHOE_STATIONS[::-1])]
    curve_tube(collection, "shoe_sole_line", line, 0.02, foxing, cyclic=True)


def _shoe_collar(collection):
    canvas = material("Shoe denim canvas", "#5B8CC2", roughness=0.9)
    lining = material("Shoe lining", "#2A3843")
    foxing = material("Shoe sole line", "#B44A3A")
    wall = material("Shoe inner wall", "#3E5B78")
    uv_sphere(collection, "shoe_ankle_opening", (-0.45, 0, _shoe_top(-0.45) - 0.04), (0.33, 0.19, 0.06), lining)

    def rim(scale, drop):
        points = []
        # The collar stops at the throat on each side, leaving the tongue free.
        for i in range(21):
            a = 0.55 + i * (math.tau - 1.1) / 20
            x = -0.45 + 0.4 * scale * math.cos(a)
            # The collar dips over the ankle bones and rises again at the heel.
            points.append((x, 0.25 * scale * math.sin(a), _shoe_top(x) - drop - 0.03 * math.sin(a) ** 2))
        return points

    # A shaded inner wall between the padded lip and the dark lining gives the opening depth.
    curve_tube(collection, "shoe_inner_wall", rim(0.9, 0.03), 0.024, wall)
    curve_tube(collection, "shoe_padded_collar", rim(1.0, 0.0), 0.024, canvas)
    # The pull tab is a fabric loop folded over the back of the collar.
    top = _shoe_top(-0.97)
    loop = [(-0.985, 0, top - 0.1), (-1.005, 0, top - 0.02), (-0.97, 0, top + 0.03), (-0.92, 0, top + 0.01), (-0.9, 0, top - 0.03)]
    curve_tube(collection, "shoe_heel_tab", loop, 0.03, foxing)
    seam = material("Shoe toe cap stitching", "#233F5E")
    x = next(station for station in SHOE_STATIONS if station > 0.55)
    stitch = [_shoe_upper_point(x, v, 1, 0.004) for v in SHOE_HEIGHTS[1:]]
    stitch = stitch + [Vector((x, 0, _shoe_top(x) + 0.004))] + [point * Vector((1, -1, 1)) for point in reversed(stitch)]
    curve_tube(collection, "shoe_toe_cap_seam", [tuple(point) for point in stitch], 0.006, seam)


def _shoe_lace_strand(collection, x, sign, cream, eyelet):
    start, finish = _shoe_upper_point(x, 0.86, sign, -0.004), _shoe_upper_point(x + 0.08, 0.86, -sign, -0.004)
    lace = [start]
    for t in (0.2, 0.5, 0.8):
        point = start.lerp(finish, t)
        # The strand leaves its eyelet and hugs the tongue; the two strands of a cross
        # sit at different heights so they read as woven.
        point.z = max(point.z, _shoe_top(point.x) + 0.018 + 0.005 * sign * math.sin(t * math.pi))
        lace.append(point)
    lace.append(finish)
    _ribbon(collection, "shoe_lace", lace, [Vector((0, 0, 1))] * 5, [0.012, 0.02, 0.02, 0.02, 0.012], cream)
    for point in (start, finish):
        uv_sphere(collection, "shoe_eyelet", tuple(point), (0.022, 0.022, 0.006), eyelet, segments=12, rings=6)


def _shoe_trim(collection):
    cream = material("Shoe laces", "#F4EEDC")
    tongue = material("Shoe tongue", "#3F6A9B", roughness=0.95)
    eyelet = material("Shoe eyelets", "#26343F", metallic=0.3)
    # The tongue follows the instep and lifts slightly where it meets the ankle opening.
    xs = [-0.3 + 0.6 * i / 12 for i in range(13)]
    path = [Vector((x, 0, _shoe_top(x) + 0.006 + 0.03 * max(0.0, -0.18 - x) / 0.12)) for x in xs]
    widths = [0.16 * (1 - abs(2 * i / 12 - 1) ** 4) ** 0.25 + 0.01 for i in range(13)]
    _ribbon(collection, "shoe_tongue", path, [Vector((0, 0, 1))] * 13, widths, tongue)
    for x in (-0.1, 0.06, 0.22):
        for sign in (-1, 1):
            _shoe_lace_strand(collection, x, sign, cream, eyelet)
    # The stripe tapers at the heel and tucks under the sole edge at the midfoot.
    stripe = [(-0.5, 0.38), (-0.3, 0.41), (-0.05, 0.52), (0.15, 0.68), (0.28, 0.55), (0.31, 0.3), (0.32, 0.1)]
    for _ in range(3):
        # Corner cutting rounds the stripe's bends into one continuous swoop.
        stripe = [stripe[0]] + [point for a, b in zip(stripe, stripe[1:]) for point in (
            (0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]), (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1]))] + [stripe[-1]]
    widths = [0.022 * min(1.0, 0.4 + index / 6, 0.3 + (len(stripe) - 1 - index) / 5) for index in range(len(stripe))]
    for side in (-1, 1):
        path = [_shoe_upper_point(x, v, side, 0.006) for x, v in stripe]
        _ribbon(collection, "shoe_side_stripe", path, [_shoe_normal(x, v, side) for x, v in stripe], widths, cream)


def build_shoe(collection):
    _shoe_body(collection)
    _shoe_collar(collection)
    _shoe_trim(collection)


def build_water_bottle(collection):
    body = material("Bottle blue", "#92BFCC")
    label = material("Bottle paper label", "#EEE9D5")
    cap = material("Bottle cap blue", "#437A98")
    cylinder_between(collection, "bottle_body", (0, 0, 0.16), (0, 0, 1.39), 0.42, body, bevel=0.12)
    uv_sphere(collection, "bottle_shoulder", (0, 0, 1.35), (0.41, 0.41, 0.26), body)
    cylinder_between(collection, "bottle_label", (0, 0, 0.57), (0, 0, 0.96), 0.43, label)
    cylinder_between(collection, "bottle_neck", (0, 0, 1.41), (0, 0, 1.65), 0.19, body)
    cylinder_between(collection, "bottle_lid", (0, 0, 1.60), (0, 0, 1.79), 0.23, cap, bevel=0.035)


def build_skater(collection):
    skin = material("Skater warm skin", "#BA8966")
    shirt = material("Skater teal shirt", "#5B9F92")
    jeans = material("Skater dark trousers", "#455969")
    shoe = material("Skater shoes", "#BB654D")
    cream = material("Skater sole and eye whites", "#F3E7CD")
    dark = material("Skater face and collar", "#293A3B")
    gold = material("Skater shirt badge", "#E9B45C")
    hair = material("Skater hair", "#473D32")

    box(collection, "skater_torso", (0, -0.03, 1.86), (0.38, 0.25, 0.45), shirt, 0.17)
    uv_sphere(collection, "skater_hips", (0, 0.02, 1.42), (0.35, 0.23, 0.22), jeans)
    cylinder_between(collection, "skater_neck", (0, -0.035, 2.23), (0, -0.035, 2.46), 0.13, skin)
    torus(collection, "skater_collar", (0, -0.035, 2.29), 0.13, 0.025, dark)
    uv_sphere(collection, "skater_badge", (0, -0.286, 2.02), (0.115, 0.017, 0.115), gold)
    curve_tube(collection, "skater_badge_wave", [(-0.08, -0.305, 2.00), (0, -0.307, 2.03), (0.08, -0.305, 2.00)], 0.017, cream)

    uv_sphere(collection, "skater_head", (0, -0.035, 2.68), (0.33, 0.29, 0.38), skin)
    uv_sphere(collection, "skater_hair_crown", (0, 0.005, 2.99), (0.34, 0.29, 0.17), hair)
    uv_sphere(collection, "skater_hair_nape", (0, 0.19, 2.80), (0.28, 0.12, 0.25), hair)
    fringe = uv_sphere(collection, "skater_swept_fringe", (-0.08, -0.258, 2.945), (0.235, 0.075, 0.10), hair)
    fringe.rotation_euler.y = -0.22
    for sign in (-1, 1):
        uv_sphere(collection, "skater_ear", (sign * 0.325, -0.005, 2.68), (0.065, 0.06, 0.105), skin)
        uv_sphere(collection, "skater_sideburn", (sign * 0.29, 0.01, 2.82), (0.055, 0.12, 0.12), hair)
        uv_sphere(collection, "skater_eye_white", (sign * 0.115, -0.307, 2.755), (0.064, 0.031, 0.078), cream)
        uv_sphere(collection, "skater_pupil", (sign * 0.115 + 0.009, -0.337, 2.755), (0.028, 0.012, 0.043), dark, segments=16, rings=12)
        curve_tube(collection, "skater_eyebrow", [(sign * 0.06, -0.300, 2.861), (sign * 0.115, -0.275, 2.88), (sign * 0.17, -0.257, 2.86)], 0.019, hair)
    uv_sphere(collection, "skater_nose", (0, -0.329, 2.658), (0.062, 0.079, 0.074), skin)
    curve_tube(collection, "skater_smile", [(-0.083, -0.296, 2.543), (0, -0.305, 2.522), (0.084, -0.293, 2.551)], 0.014, dark)

    for hip, knee, ankle in (
        ((-0.21, 0.015, 1.43), (-0.47, -0.22, 0.83), (-0.57, 0.035, 0.25)),
        ((0.21, 0.015, 1.43), (0.43, -0.31, 0.79), (0.55, 0.075, 0.25)),
    ):
        curve_tube(collection, "skater_leg", [hip, knee, ankle], 0.18, jeans, radii=[1.08, 1.0, 0.82])
        x, y, _ = ankle
        box(collection, "skater_shoe_sole", (x, y - 0.10, 0.065), (0.205, 0.32, 0.065), cream, 0.055)
        uv_sphere(collection, "skater_shoe_upper", (x, y - 0.085, 0.18), (0.19, 0.30, 0.13), shoe)
        uv_sphere(collection, "skater_shoe_heel", (x, y + 0.065, 0.24), (0.175, 0.15, 0.17), shoe)
        for offset in (-0.13, -0.045):
            cylinder_between(collection, "skater_shoe_lace", (x - 0.095, y + offset, 0.298), (x + 0.095, y + offset, 0.298), 0.014, cream, vertices=12)

    for shoulder, cuff, elbow, wrist in (
        ((-0.32, -0.025, 2.18), (-0.52, -0.025, 2.00), (-0.65, -0.06, 1.85), (-0.90, -0.20, 1.94)),
        ((0.32, -0.025, 2.18), (0.53, 0.015, 2.04), (0.67, 0.045, 1.94), (0.90, 0.08, 2.15)),
    ):
        uv_sphere(collection, "skater_shoulder", shoulder, (0.19, 0.23, 0.20), shirt)
        cylinder_between(collection, "skater_sleeve", shoulder, cuff, 0.19, shirt, bevel=0.045)
        curve_tube(collection, "skater_arm", [cuff, elbow, wrist], 0.105, skin, radii=[1.12, 1.0, 0.85])
        uv_sphere(collection, "skater_hand", wrist, (0.12, 0.10, 0.13), skin)
        uv_sphere(collection, "skater_thumb", (wrist[0], wrist[1] - 0.075, wrist[2] - 0.045), (0.061, 0.055, 0.073), skin)


def build_bench(collection):
    wood = material("Bench weathered wood", "#B49169")
    metal = material("Bench frame", "#626F6F", metallic=0.3)
    for y in (-0.30, 0, 0.30):
        box(collection, "bench_seat_slat", (0, y, 0.85), (1.62, 0.12, 0.095), wood, 0.035)
    for z in (1.20, 1.53):
        box(collection, "bench_back_slat", (0, 0.42, z), (1.62, 0.09, 0.12), wood, 0.035)
    for x in (-1.12, 1.12):
        for y in (-0.29, 0.32):
            cylinder_between(collection, "bench_leg", (x, y, 0.06), (x, y, 0.82), 0.085, metal)
        cylinder_between(collection, "bench_back_post", (x, 0.42, 0.14), (x, 0.42, 1.63), 0.075, metal)


def build_cone(collection):
    orange = material("Cone orange", "#E68E43")
    white = material("Cone reflective band", "#EEEAD4")
    dark = material("Cone rubber foot", "#485257")
    box(collection, "cone_base", (0, 0, 0.10), (0.68, 0.68, 0.10), dark, 0.08)
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=0.49, radius2=0.075, depth=1.55, location=(0, 0, 0.96))
    obj = bpy.context.object
    obj.name = "cone_body"
    obj.data.materials.append(orange)
    move_to_collection(obj, collection)
    smooth(obj)
    for z, radius in ((0.77, 0.34), (1.14, 0.24)):
        torus(collection, "cone_band", (0, 0, z), radius, 0.065, white)


def build_trash_can(collection):
    metal = material("Trash can green", "#69857A", metallic=0.25)
    dark = material("Trash can opening", "#263C38")
    cylinder_between(collection, "trash_can_body", (0, 0, 0.10), (0, 0, 1.49), 0.66, metal, bevel=0.07)
    cylinder_between(collection, "trash_can_opening", (0, 0, 1.50), (0, 0, 1.53), 0.52, dark)
    torus(collection, "trash_can_lip", (0, 0, 1.52), 0.60, 0.075, metal)
    for i in range(12):
        a = i * math.tau / 12
        cylinder_between(collection, "trash_can_rib", (math.cos(a) * 0.66, math.sin(a) * 0.66, 0.21), (math.cos(a) * 0.66, math.sin(a) * 0.66, 1.36), 0.025, metal, vertices=8)


def build_fence_section(collection):
    metal = material("Fence galvanized", "#A6AEAA", metallic=0.4)
    for x in (-2, 2):
        cylinder_between(collection, "fence_post", (x, 0, 0.0), (x, 0, 2.55), 0.08, metal)
    for z in (0.15, 2.35):
        cylinder_between(collection, "fence_crossbar", (-2, 0, z), (2, 0, z), 0.055, metal)
    for x in [i * 0.4 for i in range(-4, 5)]:
        cylinder_between(collection, "fence_wire_vertical", (x, 0, 0.16), (x, 0, 2.34), 0.016, metal, vertices=8)
    for z in [0.4 + i * 0.38 for i in range(5)]:
        cylinder_between(collection, "fence_wire_horizontal", (-2, 0, z), (2, 0, z), 0.016, metal, vertices=8)


def build_parked_car(collection):
    paint = material("Car faded blue", "#708D9C", metallic=0.2)
    glass = material("Car windows", "#314A56")
    tire = material("Car tires", "#303B3E")
    chrome = material("Car trim", "#BBC0B8", metallic=0.5)
    light = material("Car headlights", "#F1DFC0")
    box(collection, "car_body", (0, 0, 0.58), (2.13, 0.91, 0.35), paint, 0.24)
    box(collection, "car_cabin", (-0.15, 0, 1.10), (1.16, 0.77, 0.43), paint, 0.23)
    for side in (-1, 1):
        box(collection, "car_side_windows", (-0.15, side * 0.76, 1.19), (0.92, 0.02, 0.23), glass, 0.06)
        box(collection, "car_door_pillar", (-0.22, side * 0.79, 1.18), (0.07, 0.025, 0.27), paint, 0.015)
        box(collection, "car_headlight", (2.12, side * 0.60, 0.67), (0.035, 0.20, 0.10), light, 0.035)
        for x in (-1.35, 1.32):
            cylinder_between(collection, "car_tire", (x, side * 0.83, 0.38), (x, side * 1.02, 0.38), 0.40, tire, bevel=0.055)
            cylinder_between(collection, "car_hub", (x, side * 1.03, 0.38), (x, side * 1.055, 0.38), 0.22, chrome)
    box(collection, "car_windshield", (1.025, 0, 1.21), (0.025, 0.61, 0.23), glass, 0.04)


def build_tree(collection):
    bark = material("Tree bark", "#907254")
    leaf = material("Tree leaf green", "#78996B")
    light = material("Tree sunlit leaves", "#9BAC76")
    cylinder_between(collection, "tree_trunk", (0, 0, 0.05), (0.08, 0, 2.72), 0.21, bark)
    for i in range(5):
        a = i * 2.4
        end = (math.cos(a) * 0.75, math.sin(a) * 0.75, 2.5 + (i % 2) * 0.55)
        cylinder_between(collection, "tree_branch", (0, 0, 1.65), end, 0.09, bark)
        ico_sphere(collection, "tree_crown", end, (0.93, 0.87, 0.91), leaf if i % 2 else light, subdivisions=2)
    ico_sphere(collection, "tree_top", (0, 0, 3.44), (0.86, 0.81, 0.80), leaf, subdivisions=2)


def build_rail_post(collection):
    steel = material("Rail steel", "#A8B4BE", roughness=0.22, metallic=0.76)
    cylinder_between(collection, "rail_leg", (0, 0, 0.12), (0, 0, 1.18), 0.105, steel, bevel=0.02)
    cylinder_between(collection, "rail_foot", (0, -0.48, 0.08), (0, 0.48, 0.08), 0.11, steel, bevel=0.025)


def build_rail_bar(collection):
    steel = material("Rail steel", "#A8B4BE", roughness=0.22, metallic=0.76)
    cylinder_between(collection, "rail_bar", (-2.3, 0, 0.13), (2.3, 0, 0.13), 0.13, steel, vertices=32, bevel=0.025)
