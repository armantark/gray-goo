"""Muted stellar, galactic, and cosmic-web model families."""
from __future__ import annotations

import math
from .geometry import (
    curve_tube,
    material,
    torus,
    uv_sphere,
)


def star_body(collection, name, color, size, halo):
    surface = material(name + " photosphere", color)
    fleck = material(name + " bright granules", "#E7DDCA")
    uv_sphere(collection, name + " star", (0, 0, size), (size, size, size), surface, segments=24, rings=16)
    for i in range(9):
        a = i * 2.399963
        r = size * (0.4 + (i % 3) * 0.18)
        z = size + math.sqrt(max(0, size * size - r * r))
        uv_sphere(collection, name + " granule", (math.cos(a) * r, math.sin(a) * r, z), (size * 0.05, size * 0.05, size * 0.017), fleck, segments=10, rings=6)
    if halo:
        torus(collection, name + " corona", (0, 0, size), size * 1.17, size * 0.035, surface, (0.13, 0.06, 0))


def build_red_dwarf(collection):
    star_body(collection, "red dwarf", "#BD775E", 0.66, False)


def build_yellow_star(collection):
    star_body(collection, "yellow star", "#E1CC9E", 1.0, True)


def build_blue_giant(collection):
    star_body(collection, "blue giant", "#B2CAD7", 1.32, True)


def build_nebula(collection):
    dust = material("Nebula brown dust", "#837A6E")
    gas = material("Nebula slate gas", "#748992")
    stars = material("Nebula starlight", "#E4D9C2")
    for i in range(13):
        a = i * 2.399963
        r = 0.30 + (i % 5) * 0.42
        location = (math.cos(a) * r, math.sin(a) * r * 0.63, 0.45 + (i % 3) * 0.14)
        uv_sphere(collection, "nebula_cloud", location, (0.78, 0.52, 0.26), dust if i % 2 else gas, segments=16, rings=10)
    for i in range(9):
        a = i * 2.399963
        uv_sphere(collection, "nebula_embedded_star", (math.cos(a) * 1.50, math.sin(a) * 0.83, 0.91), (0.055, 0.055, 0.055), stars, segments=10, rings=6)


def build_black_hole(collection):
    dark = material("Black hole event horizon", "#0A0C0F")
    hot = material("Accretion hot inner disk", "#C6A475")
    dust = material("Accretion outer disk", "#7F7565")
    uv_sphere(collection, "event_horizon", (0, 0, 0.61), (0.57, 0.57, 0.57), dark)
    for radius, mat in ((0.74, hot), (0.95, hot), (1.20, dust), (1.43, dust)):
        ring = torus(collection, "accretion_disk", (0, 0, 0.61), radius, 0.105, mat)
        ring.scale.z = 0.30
    torus(collection, "lensed_light_arc", (0, 0, 0.61), 0.66, 0.045, hot, (math.pi / 2, 0, 0))


def galaxy_arm_geometry(collection, angle=0.0):
    dust = material("Spiral brown dust", "#897F71")
    gas = material("Spiral blue dust", "#879BA4")
    star = material("Spiral stars", "#E2D9C3")
    points, radii = [], []
    for i in range(24):
        t = i / 23
        a = angle + t * math.pi * 1.48
        r = 0.57 + t * 2.58
        points.append((math.cos(a) * r, math.sin(a) * r, 0.18))
        radii.append(1.2 - t * 0.95)
    curve_tube(collection, "spiral_dust_lane", points, 0.22, dust, radii=radii)
    curve_tube(collection, "spiral_blue_ridge", [(x * 1.04, y * 1.04, z + 0.06) for x, y, z in points], 0.095, gas, radii=radii)
    for i in range(2, 24, 3):
        x, y, z = points[i]
        uv_sphere(collection, "spiral_star", (x, y, z + 0.16), (0.045, 0.045, 0.045), star, segments=10, rings=6)


def build_galaxy_arm(collection):
    galaxy_arm_geometry(collection)


def build_galaxy_bulge(collection):
    core = material("Galaxy warm bulge", "#D8CCAF")
    inner = material("Galaxy inner dust", "#A9A294")
    uv_sphere(collection, "galaxy_bulge", (0, 0, 0.31), (0.81, 0.81, 0.30), core)
    ring = torus(collection, "galaxy_inner_disk", (0, 0, 0.18), 0.88, 0.16, inner)
    ring.scale.z = 0.35


def build_spiral_galaxy(collection):
    build_galaxy_bulge(collection)
    for angle in (0, math.pi):
        galaxy_arm_geometry(collection, angle)


def build_elliptical_galaxy(collection):
    old = material("Elliptical old stars", "#BDB196")
    core = material("Elliptical nucleus", "#E5D8B8")
    uv_sphere(collection, "elliptical_halo", (0, 0, 0.32), (1.96, 1.17, 0.30), old)
    uv_sphere(collection, "elliptical_core", (0, 0, 0.46), (0.68, 0.43, 0.19), core)
    for i in range(18):
        a = i * 2.399963
        r = 0.3 + (i % 6) * 0.25
        uv_sphere(collection, "elliptical_star", (math.cos(a) * r, math.sin(a) * r * 0.60, 0.59), (0.04, 0.04, 0.025), core, segments=10, rings=6)


def build_dwarf_galaxy(collection):
    dust = material("Dwarf irregular dust", "#87959A")
    star = material("Dwarf stars", "#DDD4C0")
    for i in range(7):
        a = i * 2.4
        x, y = math.cos(a) * (0.15 + i * 0.11), math.sin(a) * (0.15 + i * 0.085)
        uv_sphere(collection, "dwarf_cloud", (x, y, 0.22), (0.45, 0.34, 0.19), dust, segments=16, rings=10)
        uv_sphere(collection, "dwarf_star", (x, y, 0.43), (0.045, 0.045, 0.045), star, segments=10, rings=6)


def build_galaxy_group(collection):
    dust = material("Group dust", "#93968B")
    core = material("Group galaxy centers", "#DACCB0")
    for i in range(7):
        a = i * 2.399963
        radius = 0.18 + i * 0.32
        center = (math.cos(a) * radius, math.sin(a) * radius * 0.66, 0.32 + (i % 2) * 0.15)
        uv_sphere(collection, "group_galaxy_disk", center, (0.61, 0.39, 0.09), dust, segments=16, rings=8)
        uv_sphere(collection, "group_galaxy_bulge", center, (0.16, 0.14, 0.17), core, segments=12, rings=8)


def build_supercluster(collection):
    dust = material("Supercluster filament dust", "#737D81")
    star = material("Supercluster galaxy light", "#C9C4AF")
    for arm in range(4):
        angle = arm * math.tau / 4 + 0.23
        points = [(math.cos(angle + t * 0.21) * t * 2.8, math.sin(angle + t * 0.21) * t * 2.8, 0.45 + math.sin(t * 4 + arm) * 0.16) for t in [i / 8 for i in range(9)]]
        curve_tube(collection, "supercluster_filament", points, 0.055, dust)
        for i, position in enumerate(points):
            size = 0.12 + (i % 3) * 0.065
            uv_sphere(collection, "supercluster_galaxy", position, (size * 1.6, size, size * 0.35), star, segments=12, rings=8)
