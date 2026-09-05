"""Tide-pool animals and boulders."""
from __future__ import annotations

import math
from .geometry import (
    curve_tube,
    cylinder_between,
    ico_sphere,
    material,
    mesh_object,
    torus,
    uv_sphere,
)


def spiral_shell(collection, prefix, center, size, conical=False):
    shell = material(prefix + " amber shell", "#C59369")
    stripe = material(prefix + " ivory lip", "#E9D2AE")
    x, y, z = center
    points, radii = [], []
    for i in range(49):
        t = i / 48
        angle = t * math.tau * 2.4
        radius = size * (0.08 + t * 0.58)
        height = z + size * (0.85 - t * 0.70) if conical else z + math.sin(angle) * radius
        points.append((x + math.cos(angle) * radius, y + (math.sin(angle) * radius if conical else t * size * 0.17), height))
        radii.append(0.25 + t * 0.75)
    curve_tube(collection, prefix + " spiral shell", points, size * 0.34, shell, radii=radii)
    torus(collection, prefix + " shell lip", points[-1], size * 0.24, size * 0.045, stripe, (math.pi / 2, 0, 0))


def snail_body(collection, name, length):
    body = material(name + " soft foot", "#96AD70")
    eye = material(name + " eyes", "#253337")
    uv_sphere(collection, name + " foot", (0, 0, 0.20), (length, 0.39, 0.21), body)
    for y in (-0.24, 0.24):
        curve_tube(collection, name + " eyestalk", [(length * 0.63, y, 0.31), (length * 0.88, y * 1.4, 0.65), (length * 0.93, y * 1.5, 0.86)], 0.055, body)
        uv_sphere(collection, name + " eye", (length * 0.93, y * 1.5, 0.86), (0.075, 0.075, 0.075), eye, segments=12, rings=8)


def build_snail(collection):
    snail_body(collection, "snail", 1.05)
    spiral_shell(collection, "snail", (-0.20, 0, 0.87), 1.0)


def build_periwinkle(collection):
    snail_body(collection, "periwinkle", 0.73)
    spiral_shell(collection, "periwinkle", (-0.20, 0, 0.43), 0.88, conical=True)


def crab_parts(collection):
    orange = material("Crab rust", "#D58355")
    tip = material("Crab claw tips", "#EBD0A2")
    eye = material("Crab eyes", "#222D31")
    uv_sphere(collection, "crab_carapace", (0, 0, 0.49), (0.70, 0.61, 0.34), orange)
    for side in (-1, 1):
        for i in range(3):
            y = -0.36 + i * 0.35
            curve_tube(collection, "crab_leg", [(side * 0.48, y, 0.48), (side * 1.05, y - 0.22, 0.40), (side * 1.30, y - 0.42, 0.09)], 0.065, orange, radii=[1, 0.9, 0.2])
        curve_tube(collection, "crab_arm", [(side * 0.46, -0.30, 0.54), (side * 0.80, -0.86, 0.55), (side * 0.71, -1.17, 0.54)], 0.10, orange)
        uv_sphere(collection, "crab_claw", (side * 0.71, -1.23, 0.58), (0.24, 0.32, 0.19), orange)
        for offset in (-0.1, 0.1):
            curve_tube(collection, "crab_pincer", [(side * 0.71 + offset, -1.38, 0.58), (side * 0.71 + offset * 0.4, -1.63, 0.58)], 0.08, tip, radii=[1, 0.2])
        cylinder_between(collection, "crab_eyestalk", (side * 0.27, -0.43, 0.58), (side * 0.31, -0.55, 0.90), 0.055, orange)
        uv_sphere(collection, "crab_eye", (side * 0.31, -0.55, 0.91), (0.085, 0.085, 0.085), eye, segments=12, rings=8)


def build_crab_body(collection):
    crab_parts(collection)


def build_hermit_crab(collection):
    crab_parts(collection)
    spiral_shell(collection, "hermit", (0, 0.37, 0.94), 1.15, conical=True)


def build_anemone(collection):
    stalk = material("Anemone column", "#C47462")
    tentacle = material("Anemone tentacles", "#DBAD7B")
    mouth = material("Anemone mouth", "#713F3E")
    uv_sphere(collection, "anemone_column", (0, 0, 0.30), (0.67, 0.67, 0.35), stalk)
    uv_sphere(collection, "anemone_oral_disk", (0, 0, 0.60), (0.72, 0.72, 0.13), mouth)
    for i in range(20):
        a = i * math.tau / 20
        radius = 0.50 + (i % 2) * 0.2
        points = [(math.cos(a) * radius, math.sin(a) * radius, 0.56), (math.cos(a + 0.13) * radius * 1.35, math.sin(a + 0.13) * radius * 1.35, 0.95), (math.cos(a + 0.28) * radius * 1.18, math.sin(a + 0.28) * radius * 1.18, 1.32 + (i % 3) * 0.08)]
        curve_tube(collection, "anemone_tentacle", points, 0.085, tentacle, radii=[1.1, 0.8, 0.25])


def build_sea_star(collection):
    skin = material("Sea star coral", "#D89968")
    spots = material("Sea star spots", "#F4D6AA")
    uv_sphere(collection, "sea_star_disk", (0, 0, 0.24), (0.49, 0.49, 0.24), skin)
    for i in range(5):
        a = i * math.tau / 5
        points = [(math.cos(a) * r, math.sin(a) * r, z) for r, z in ((0.25, 0.24), (0.77, 0.24), (1.28, 0.12))]
        curve_tube(collection, "sea_star_arm", points, 0.27, skin, radii=[1.3, 0.95, 0.15])
        for r in (0.45, 0.72, 0.94):
            uv_sphere(collection, "sea_star_ossicle", (math.cos(a) * r, math.sin(a) * r, 0.43 - r * 0.09), (0.055, 0.055, 0.035), spots, segments=12, rings=8)


def build_small_fish(collection):
    body = material("Fish silver blue", "#79AEB8")
    fin = material("Fish fins", "#CBA76F")
    eye = material("Fish pupil", "#202E32")
    uv_sphere(collection, "fish_body", (0, 0, 0.51), (0.94, 0.29, 0.42), body)
    mesh_object(collection, "fish_tail", [(-0.72, 0, 0.52), (-1.39, 0, 0.99), (-1.19, 0, 0.49), (-1.39, 0, 0.08), (-1.28, 0.09, 0.49)], [(0, 1, 2), (0, 2, 3), (0, 4, 1), (0, 3, 4)], fin)
    mesh_object(collection, "fish_dorsal_fin", [(-0.40, 0, 0.81), (-0.20, 0, 1.13), (0.45, 0, 0.84), (0, 0.08, 0.83)], [(0, 1, 2), (0, 3, 1), (1, 3, 2)], fin)
    for side in (-1, 1):
        uv_sphere(collection, "fish_eye", (0.64, side * 0.22, 0.63), (0.095, 0.045, 0.095), eye, segments=12, rings=8)
        curve_tube(collection, "fish_gill", [(0.37, side * 0.27, 0.75), (0.29, side * 0.30, 0.56), (0.34, side * 0.26, 0.35)], 0.025, fin)


def build_boulder(collection):
    stone = material("Boulder granite", "#9A9D91")
    mat = material("Boulder seam", "#737E72")
    ico_sphere(collection, "boulder_base", (0, 0, 0.79), (1.44, 1.11, 0.95), stone, subdivisions=2)
    ico_sphere(collection, "boulder_shoulder", (-0.64, 0.18, 0.71), (0.82, 0.86, 0.72), mat, subdivisions=2)
