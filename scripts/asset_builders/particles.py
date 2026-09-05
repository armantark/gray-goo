"""Charged particles and their readable cartoon formations."""
from __future__ import annotations

import math
from .geometry import (
    box,
    curve_tube,
    cylinder_between,
    extruded_polygon,
    material,
    uv_sphere,
)


def build_gluon(collection):
    green = material("Gluon mint", "#77D8AD")
    points = [(math.sin(t * math.tau * 3) * 0.28, -1.0 + t * 2, 0.35 + math.cos(t * math.tau * 3) * 0.24) for t in [i / 40 for i in range(41)]]
    curve_tube(collection, "gluon_spring", points, 0.085, green)
    for y in (-1.0, 1.0):
        uv_sphere(collection, "gluon_end", (0, y, 0.59), (0.16, 0.16, 0.16), green)


def build_photon(collection):
    gold = material("Photon light", "#FFE69A", emission_strength=0.2)
    outline = [(-1.25, -0.05), (-0.25, 0.5), (-0.3, 0.13), (1.25, 0.12), (0.28, -0.5), (0.35, -0.12)]
    extruded_polygon(collection, "photon_wave_arrow", outline, 0, 0.17, gold, 0.045)
    points = [(-1.2 + i * 0.1, math.sin(i * 0.48) * 0.24, 0.30) for i in range(25)]
    curve_tube(collection, "photon_wave", points, 0.055, gold)


def charged_particle(collection, positive):
    body = material("Positron amber" if positive else "Electron blue", "#F8AC73" if positive else "#79B9E1")
    sign = material("Charge marking", "#F7F5E9")
    uv_sphere(collection, "charge_body", (0, 0, 0.46), (0.46, 0.46, 0.46), body)
    box(collection, "charge_minus", (0, 0, 0.90), (0.22, 0.055, 0.025), sign, 0.02)
    if positive:
        box(collection, "charge_plus", (0, 0, 0.91), (0.055, 0.22, 0.025), sign, 0.02)


def build_electron(collection):
    charged_particle(collection, False)


def build_positron(collection):
    charged_particle(collection, True)


def build_pion(collection):
    red = material("Pion quark", "#E77974")
    blue = material("Pion antiquark", "#70B7CA")
    binding = material("Pion binding", "#EEE0A6")
    cylinder_between(collection, "pion_bond", (-0.55, 0, 0.48), (0.55, 0, 0.48), 0.14, binding)
    for x, mat in ((-0.55, red), (0.55, blue)):
        uv_sphere(collection, "pion_constituent", (x, 0, 0.48), (0.46, 0.46, 0.46), mat)


def build_neutron(collection):
    neutral = material("Neutron slate", "#7F9BAE")
    light = material("Neutron light", "#ACBAC6")
    positions = ((-0.45, -0.23, 0.64), (0.45, -0.23, 0.64), (0.0, 0.42, 0.78))
    for index, position in enumerate(positions):
        uv_sphere(collection, "neutron_constituent", position, (0.64, 0.64, 0.64), [neutral, light, neutral][index])
