"""Muted stellar, galactic, and cosmic-web model families."""
from __future__ import annotations

import math
from .geometry import (
    curve_tube,
    ico_sphere,
    material,
    mesh_object,
    uv_sphere,
)


def star_body(collection, name, color, size):
    surface = material(name + " photosphere", color)
    uv_sphere(collection, name + " star", (0, 0, size), (size, size, size), surface, segments=24, rings=16)


def dust_wisp(collection, name, points, width, mat, phase):
    vertices, colors = [], []
    for i, (x, y, z) in enumerate(points):
        t = i / (len(points) - 1)
        previous = points[max(0, i - 1)]
        following = points[min(len(points) - 1, i + 1)]
        dx, dy = following[0] - previous[0], following[1] - previous[1]
        length = math.hypot(dx, dy)
        taper = 0.015 + math.sin(math.pi * t) ** 0.7
        breadth = width * taper * (0.78 + 0.22 * math.sin(i * 1.9 + phase))
        offset_x, offset_y = -dy / length * breadth, dx / length * breadth
        longitudinal = min(1.0, t * 4, (1 - t) * 4) ** 2
        for across in (-1.0, -0.5, 0.0, 0.5, 1.0):
            vertices.append((x + offset_x * across, y + offset_y * across, z + 0.003 * taper * (across + 1)))
            colors.extend((1.0, 1.0, 1.0, longitudinal * (1 - abs(across)) ** 1.5))
    faces = [(i * 5 + j, i * 5 + j + 5, i * 5 + j + 6, i * 5 + j + 1)
             for i in range(len(points) - 1) for j in range(4)]
    obj = mesh_object(collection, name, vertices, faces, mat)
    attribute = obj.data.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="POINT")
    attribute.data.foreach_set("color", colors)
    obj.data.color_attributes.active_color_index = 0


def ensure_opaque_colors(collection):
    # Blender joins must not give unpainted star flecks the wisps' transparent default.
    for obj in collection.objects:
        if obj.type != "MESH" or obj.data.color_attributes.get("Color") is not None:
            continue
        attribute = obj.data.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="POINT")
        attribute.data.foreach_set("color", [1.0] * (len(obj.data.vertices) * 4))
        obj.data.color_attributes.active_color_index = 0


def broken_cloud(collection, name, center, length, width, angle, mat, phase):
    points = []
    for i in range(11):
        t = i / 10
        along = (t - 0.5) * length
        across = math.sin(t * math.pi * 1.6 + phase) * width * 0.65
        points.append((center[0] + math.cos(angle) * along - math.sin(angle) * across,
                       center[1] + math.sin(angle) * along + math.cos(angle) * across,
                       center[2] + math.sin(t * math.pi + phase) * 0.025))
    dust_wisp(collection, name, points, width, mat, phase)


def build_red_dwarf(collection):
    star_body(collection, "red dwarf", "#FFD8B8", 0.66)


def build_yellow_star(collection):
    star_body(collection, "yellow star", "#FFF4E2", 1.0)


def build_blue_giant(collection):
    star_body(collection, "blue giant", "#DCE9FF", 1.32)


def build_nebula(collection):
    dust = material("Nebula brown dust", "#3A3128")
    gas = material("Nebula slate gas", "#2E3A44")
    stars = material("Nebula starlight", "#FFF4E2")
    for i in range(11):
        center = (-1.80 + i * 0.36, 0.48 * math.sin(i * 1.1), 0.12 + 0.015 * i)
        length = 0.75 + 0.55 * (1 + math.sin(i * 2.1))
        width = 0.16 + 0.15 * math.sin(i * 1.7) ** 2
        broken_cloud(collection, "nebula_cloud", center, length, width, -0.35 + 0.55 * math.sin(i * 0.73),
                     dust if i % 2 else gas, i * 1.3)
    for i in range(42):
        x = -2 + i * 4 / 41
        y = 0.50 * math.sin(i * 2.399963) + 0.20 * math.sin(x * 2)
        size = 0.008 + 0.019 * math.sin(i * 1.8) ** 6
        ico_sphere(collection, "nebula_embedded_star", (x, y, 0.33), (size, size, size), stars, subdivisions=1)
    ensure_opaque_colors(collection)


def build_black_hole(collection):
    dark = material("Black hole event horizon", "#0A0C0F")
    hot = material("Accretion hot inner disk", "#FFF4E2", emission_strength=1.0)
    warm = material("Accretion warm disk", "#C89A65")
    dim = material("Accretion outer disk", "#64503B")
    uv_sphere(collection, "event_horizon", (0, 0, 0.61), (0.57, 0.57, 0.57), dark)
    vertices = []
    for i in range(96):
        angle = i * math.tau / 96
        for radius in (0.64, 0.70, 0.94, 1.43):
            vertices.append((math.cos(angle) * radius, math.sin(angle) * radius, 0.61))
    faces = [(i * 4 + j, i * 4 + j + 1, ((i + 1) % 96) * 4 + j + 1, ((i + 1) % 96) * 4 + j)
             for i in range(96) for j in range(3)]
    disk = mesh_object(collection, "accretion_disk", vertices, faces, hot)
    disk.data.materials.append(warm)
    disk.data.materials.append(dim)
    for i, polygon in enumerate(disk.data.polygons):
        polygon.material_index = i % 3


def galaxy_arm_geometry(collection, angle=0.0):
    dust = material("Spiral brown dust", "#3A3128")
    gas = material("Spiral blue dust", "#2E3A44")
    star = material("Spiral stars", "#FFF4E2")
    for i in range(18):
        points = []
        for j in range(11):
            t = i / 21 + j / 10 * (0.14 + 0.035 * math.sin(i * 1.7) ** 2)
            a = angle + t * math.pi * 0.75 + 0.045 * math.sin(i * 2.4)
            r = 0.57 * math.exp(math.log(3.15 / 0.57) * t) + 0.045 * math.sin(i * 1.9)
            points.append((math.cos(a) * r, math.sin(a) * r, 0.12 + 0.025 * math.sin(t * 9 + i)))
        dust_wisp(collection, "spiral_dust_wisp", points, (0.22 - i * 0.006) * (0.8 + 0.2 * math.sin(i) ** 2),
                  dust if i % 3 else gas, i * 2.1)
    for i in range(96):
        t = (i + 0.35 * math.sin(i * 2.4)) / 96
        a = angle + t * math.pi * 0.75 + 0.065 * math.sin(i * 1.7)
        r = 0.57 * math.exp(math.log(3.15 / 0.57) * t) + (0.045 + t * 0.075) * math.sin(i * 2.399963)
        size = 0.007 + 0.014 * math.sin(i * 1.8) ** 8
        position = (math.cos(a) * r, math.sin(a) * r, 0.19 + 0.025 * math.sin(i))
        ico_sphere(collection, "spiral_star", position, (size, size, size), star, subdivisions=1)
    ensure_opaque_colors(collection)


def build_galaxy_arm(collection):
    galaxy_arm_geometry(collection)


def build_galaxy_bulge(collection):
    core = material("Galaxy warm bulge", "#D8CCAF")
    uv_sphere(collection, "galaxy_bulge", (0, 0, 0.22), (0.81, 0.81, 0.22), core)


def build_spiral_galaxy(collection):
    build_galaxy_bulge(collection)
    for angle in (0, math.pi):
        galaxy_arm_geometry(collection, angle)


def build_elliptical_galaxy(collection):
    old = material("Elliptical old stars", "#3A3128")
    core = material("Elliptical nucleus", "#E5D8B8")
    uv_sphere(collection, "elliptical_halo", (0, 0, 0.32), (1.96, 1.17, 0.30), old)
    uv_sphere(collection, "elliptical_core", (0, 0, 0.46), (0.68, 0.43, 0.19), core)
    for i in range(18):
        a = i * 2.399963
        r = 0.3 + (i % 6) * 0.25
        uv_sphere(collection, "elliptical_star", (math.cos(a) * r, math.sin(a) * r * 0.60, 0.59), (0.04, 0.04, 0.025), core, segments=10, rings=6)


def build_dwarf_galaxy(collection):
    dust = material("Dwarf irregular dust", "#2E3A44")
    star = material("Dwarf stars", "#FFF4E2")
    for i in range(8):
        a = i * 2.4
        center = (math.cos(a) * (0.15 + i * 0.11), math.sin(a) * (0.15 + i * 0.085), 0.10 + i * 0.014)
        broken_cloud(collection, "dwarf_cloud", center, 0.72 + 0.58 * math.sin(i * 1.2) ** 2,
                     0.09 + 0.075 * math.sin(i * 2.1) ** 2, 0.35 + math.sin(i) * 0.65, dust, i * 1.8)
    for i in range(34):
        a = i * 2.399963
        radius = 0.12 + math.sqrt(i / 33) * 1.08
        size = 0.008 + 0.015 * math.sin(i * 1.3) ** 6
        ico_sphere(collection, "dwarf_star", (math.cos(a) * radius, math.sin(a) * radius * 0.6, 0.25),
                   (size, size, size), star, subdivisions=1)
    ensure_opaque_colors(collection)


def build_galaxy_group(collection):
    dust = material("Group dust", "#2E3A44")
    core = material("Group galaxy centers", "#D8CCAF")
    galaxies = [(-0.35, 0.18, 0.82, 0.3), (0.74, -0.23, 0.63, -0.5),
                (-1.15, -0.52, 0.38, 0.8), (1.43, 0.64, 0.47, 0.1),
                (0.23, 1.10, 0.31, -0.8), (-0.57, -1.05, 0.27, 0.4),
                (1.79, -0.79, 0.23, 1.1)]
    for i, (x, y, size, angle) in enumerate(galaxies):
        center = (x, y, 0.15 + (i % 3) * 0.045)
        disk = uv_sphere(collection, "group_galaxy_disk", center, (size, size * 0.53, size * 0.055), dust, segments=16, rings=8)
        disk.rotation_euler.z = angle
        uv_sphere(collection, "group_galaxy_bulge", center, (size * 0.24, size * 0.20, size * 0.12), core, segments=12, rings=8)


def build_supercluster(collection):
    dust = material("Supercluster filament dust", "#2E3A44")
    star = material("Supercluster galaxy light", "#FFF4E2")
    for arm in range(4):
        angle = arm * math.tau / 4 + 0.23
        points = [(math.cos(angle + t * 0.21) * t * 2.8, math.sin(angle + t * 0.21) * t * 2.8, 0.45 + math.sin(t * 4 + arm) * 0.16) for t in [i / 8 for i in range(9)]]
        curve_tube(collection, "supercluster_filament", points, 0.055, dust)
        for i, position in enumerate(points):
            size = 0.12 + (i % 3) * 0.065
            uv_sphere(collection, "supercluster_galaxy", position, (size * 1.6, size, size * 0.35), star, segments=12, rings=8)
