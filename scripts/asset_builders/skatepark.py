"""Skatepark hardware, gear, people, and background objects."""
from __future__ import annotations

import math
import bpy
from .geometry import (
    box,
    curve_tube,
    cylinder_between,
    ico_sphere,
    material,
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
    box(collection, "truck_baseplate", (0, 0, 0.12), (0.39, 0.32, 0.11), metal, 0.045)
    cylinder_between(collection, "truck_kingpin", (0, 0, 0.20), (0.1, 0, 0.51), 0.12, rubber)
    cylinder_between(collection, "truck_axle", (0.1, -0.88, 0.47), (0.1, 0.88, 0.47), 0.10, metal, bevel=0.02)
    box(collection, "truck_hanger", (0.1, 0, 0.45), (0.17, 0.51, 0.12), metal, 0.06)


def build_helmet(collection):
    shell = material("Helmet ochre", "#DEA754")
    rim = material("Helmet padding", "#394951")
    uv_sphere(collection, "helmet_dome", (0, 0, 0.41), (0.87, 0.77, 0.67), shell)
    torus(collection, "helmet_rim", (0, 0, 0.18), 0.68, 0.095, rim)
    for x in (-0.32, 0, 0.32):
        points = [(x, y, 0.425 + 0.67 * math.sqrt(1 - (x / 0.87) ** 2 - (y / 0.77) ** 2)) for y in (-0.25, 0, 0.25)]
        curve_tube(collection, "helmet_vent", points, 0.036, rim)
    curve_tube(collection, "helmet_strap", [(-0.57, 0, 0.20), (-0.24, 0, -0.25), (0.30, 0, -0.25), (0.60, 0, 0.20)], 0.045, rim)


def build_shoe(collection):
    fabric = material("Shoe canvas", "#657F98")
    cream = material("Shoe rubber sole", "#E7DCC1")
    lace = material("Shoe laces", "#EEE7D7")
    uv_sphere(collection, "shoe_sole", (0, 0, 0.12), (1.0, 0.42, 0.15), cream)
    uv_sphere(collection, "shoe_upper", (0.05, 0, 0.32), (0.85, 0.38, 0.29), fabric)
    uv_sphere(collection, "shoe_ankle", (-0.51, 0, 0.49), (0.34, 0.35, 0.36), fabric)
    for i in range(4):
        x = -0.20 + i * 0.19
        cylinder_between(collection, "shoe_lace", (x, -0.20, 0.61), (x + 0.08, 0.20, 0.61), 0.026, lace, vertices=12)


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
    shoe = material("Skater shoes", "#DDCEAA")
    hair = material("Skater hair", "#473D32")
    uv_sphere(collection, "skater_torso", (0, 0, 1.89), (0.43, 0.27, 0.59), shirt)
    uv_sphere(collection, "skater_head", (0.06, 0, 2.78), (0.29, 0.27, 0.36), skin)
    uv_sphere(collection, "skater_hair", (0.025, 0.035, 2.98), (0.30, 0.28, 0.20), hair)
    for sign in (-1, 1):
        hip = (sign * 0.23, 0, 1.44)
        knee = (sign * 0.45, -0.12, 0.87)
        ankle = (sign * 0.62, 0.02, 0.21)
        curve_tube(collection, "skater_leg", [hip, knee, ankle], 0.16, jeans)
        uv_sphere(collection, "skater_shoe", (sign * 0.62 + 0.08, -0.10, 0.14), (0.31, 0.20, 0.14), shoe)
        elbow = (sign * 0.70, 0.03, 1.80)
        hand = (sign * 0.94, -0.18, 2.01)
        cylinder_between(collection, "skater_sleeve", (sign * 0.29, 0, 2.23), elbow, 0.16, shirt)
        cylinder_between(collection, "skater_forearm", elbow, hand, 0.115, skin)
        uv_sphere(collection, "skater_hand", hand, (0.13, 0.12, 0.13), skin)


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
