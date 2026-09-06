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
    orange = material("Crab rust", "#D66E3E")
    tip = material("Crab claw tips", "#F4D4A1")
    eye = material("Crab eyes", "#182F36")
    white = material("Crab eye glint", "#FFF3D4")
    uv_sphere(collection, "crab_carapace", (0, 0, 0.49), (0.70, 0.61, 0.34), orange)
    for side in (-1, 1):
        for i in range(3):
            y = -0.30 + i * 0.34
            curve_tube(collection, "crab_leg", [(side * 0.48, y, 0.48), (side * 1.0, y - 0.12, 0.46), (side * 1.25, y - 0.43, 0.06)], 0.085, orange, radii=[1.2, 0.85, 0.15])
            uv_sphere(collection, "crab_knee", (side * 1.0, y - 0.12, 0.46), (0.095, 0.09, 0.085), orange, segments=16, rings=10)
        scale = 1.15 if side == -1 else 0.85
        x = side * 0.78
        curve_tube(collection, "crab_arm", [(side * 0.46, -0.30, 0.54), (side * 0.89, -0.75, 0.55), (x, -1.1, 0.55)], 0.12, orange)
        uv_sphere(collection, "crab_claw", (x, -1.16, 0.58), (0.25 * scale, 0.30 * scale, 0.20 * scale), orange)
        for sign in (-1, 1):
            curve_tube(collection, "crab_pincer", [(x + sign * 0.16 * scale, -1.26, 0.60), (x + sign * 0.19 * scale, -1.48, 0.60), (x + sign * 0.045 * scale, -1.67, 0.60)], 0.09 * scale, tip, radii=[1, 0.75, 0.1])
        curve_tube(collection, "crab_eyestalk", [(side * 0.27, -0.43, 0.58), (side * 0.33, -0.62, 0.93)], 0.065, orange)
        uv_sphere(collection, "crab_eye", (side * 0.33, -0.62, 0.96), (0.12, 0.105, 0.13), eye, segments=20, rings=12)
        uv_sphere(collection, "crab_eye_glint", (side * 0.33 - 0.025, -0.714, 1.0), (0.035, 0.02, 0.035), white, segments=12, rings=8)
        curve_tube(collection, "crab_feeler", [(side * 0.12, -0.57, 0.57), (side * 0.15, -0.93, 0.68), (side * 0.28, -1.06, 0.71)], 0.023, tip, radii=[1, 0.8, 0.1])


def hermit_shell_parts(collection):
    shell = material("Hermit shell ochre", "#987347")
    ridge = material("Hermit shell growth ridges", "#C3A071")
    inside = material("Hermit shell interior", "#493D32")
    # A closed conical whorl with a broad aperture at the crab's abdomen.
    vertices, faces = [], []
    rings, sides = 40, 48
    for i in range(rings + 1):
        t = i / rings
        radius = 0.76 * (1 - t) ** 0.85 + 0.015
        for j in range(sides):
            a = j / sides * math.tau
            rib = 1 + 0.035 * math.cos(a - t * math.tau * 3)
            vertices.append((math.cos(a) * radius * rib, 0.12 + t * 1.48, 0.78 + t * 0.48 + math.sin(a) * radius * 0.87 * rib))
    for i in range(rings):
        for j in range(sides):
            a, b = i * sides + j, i * sides + (j + 1) % sides
            faces.append((a + sides, b + sides, b, a))
    faces.append(tuple(reversed(range(rings * sides, (rings + 1) * sides))))
    mesh_object(collection, "hermit_shell_whorl", vertices, faces, shell)
    lip = [(math.cos(j / 48 * math.tau) * 0.77, 0.115, 0.78 + math.sin(j / 48 * math.tau) * 0.675) for j in range(48)]
    curve_tube(collection, "hermit_shell_lip", lip, 0.065, ridge, cyclic=True)
    uv_sphere(collection, "hermit_shell_aperture", (0, 0.135, 0.78), (0.70, 0.065, 0.61), inside)
    points = []
    for i in range(145):
        t = i / 144
        a = t * math.tau * 3
        radius = 0.76 * (1 - t) ** 0.85 + 0.021
        points.append((math.cos(a) * radius, 0.12 + t * 1.48, 0.78 + t * 0.48 + math.sin(a) * radius * 0.87))
    curve_tube(collection, "hermit_shell_spiral_ridge", points, 0.035, ridge, radii=[1 - i / 160 for i in range(145)])


def build_hermit_shell(collection):
    hermit_shell_parts(collection)


def build_crab_body(collection):
    crab_parts(collection)


def build_hermit_crab(collection):
    crab_parts(collection)
    hermit_shell_parts(collection)


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
