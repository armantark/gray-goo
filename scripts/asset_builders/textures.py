"""Procedural color atlases baked in Blender, shared by models and grounds."""
from __future__ import annotations

import math
from pathlib import Path

import bpy


# Scale, contrast, elongated grain: these preserve the material's authored color.
SURFACES = {
    "shell": (9.0, 0.40, (1.0, 1.0, 0.15)),
    "wood": (12.0, 0.30, (0.12, 4.0, 4.0)),
    "metal": (35.0, 0.23, (0.2, 1.0, 5.0)),
    "stone": (8.0, 0.45, (1.0, 1.0, 1.0)),
    "skin": (16.0, 0.24, (1.0, 1.0, 1.0)),
    "gas": (4.0, 0.64, (1.0, 1.0, 2.0)),
    "particle": (6.0, 0.32, (1.0, 1.0, 1.0)),
    "concrete": (38.0, 0.35, (1.0, 1.0, 1.0)),
    "sand": (65.0, 0.42, (1.0, 1.0, 1.0)),
    "fabric": (7.0, 0.68, (1.0, 1.0, 1.0)),
}

MODEL_SURFACES = {
    "shell": "shell", "snail": "shell", "periwinkle": "shell", "hermit_crab": "shell",
    "board": "wood", "skateboard": "wood", "bench": "wood", "tree": "wood",
    "bolt": "metal", "bearing": "metal", "bottle_cap": "metal", "truck": "metal",
    "rail": "metal", "fence_section": "metal", "trash_can": "metal", "parked_car": "metal",
    "rock": "stone", "boulder": "stone", "pebble": "stone", "ramp": "concrete",
    "galaxy": "gas", "galaxy_arm": "gas", "galaxy_bulge": "gas", "galaxy_group": "gas",
    "elliptical_galaxy": "gas", "dwarf_galaxy": "gas", "nebula": "gas", "knot": "gas",
    "red_dwarf": "gas", "yellow_star": "gas", "blue_giant": "gas", "black_hole": "gas",
    "quark": "particle", "proton": "particle", "neutron": "particle", "electron": "particle",
    "positron": "particle", "gluon": "particle", "photon": "particle", "pion": "particle",
}


def procedural_color(mat: bpy.types.Material, surface: str) -> bpy.types.NodeSocket:
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    scale, contrast, grain = SURFACES[surface]
    coordinate = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeVectorMath")
    mapping.operation = "MULTIPLY"
    mapping.inputs[1].default_value = grain
    links.new(coordinate.outputs["Generated"], mapping.inputs[0])
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = 3.0
    noise.inputs["Roughness"].default_value = 0.7
    links.new(mapping.outputs["Vector"], noise.inputs["Vector"])
    ramp = nodes.new("ShaderNodeValToRGB")
    color = tuple(mat.diffuse_color)
    ramp.color_ramp.elements[0].position = 0.22
    ramp.color_ramp.elements[0].color = tuple(v * (1.0 - contrast) for v in color[:3]) + (1.0,)
    ramp.color_ramp.elements[1].position = 0.78
    ramp.color_ramp.elements[1].color = tuple(min(1.0, v * (1.0 + contrast) + contrast * 0.025) for v in color[:3]) + (1.0,)
    links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    if surface == "fabric":
        return fabric_color(mat, coordinate.outputs["Generated"], ramp.outputs["Color"])
    return ramp.outputs["Color"]


def fabric_color(mat, coordinates, color):
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    cell = nodes.new("ShaderNodeTexVoronoi")
    cell.feature = "DISTANCE_TO_EDGE"
    cell.inputs["Scale"].default_value = 7.0
    links.new(coordinates, cell.inputs["Vector"])
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.0
    ramp.color_ramp.elements[0].color = (0.016, 0.024, 0.032, 1)
    ramp.color_ramp.elements[1].position = 0.08
    ramp.color_ramp.elements[1].color = (0.001, 0.002, 0.004, 1)
    links.new(cell.outputs["Distance"], ramp.inputs["Fac"])
    mix = nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "ADD"
    mix.inputs[0].default_value = 0.65
    links.new(color, mix.inputs[1])
    links.new(ramp.outputs["Color"], mix.inputs[2])
    return mix.outputs[0]


def join_and_unwrap(collection, name):
    bpy.ops.object.select_all(action="DESELECT")
    meshes = [obj for obj in collection.all_objects if obj.type == "MESH"]
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name + "_textured_mesh"
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.015)
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


def bake_atlas(collection, name: str, output_dir: Path, surface: str | None = None):
    obj = join_and_unwrap(collection, name)
    image = bpy.data.images.new(name + "_albedo", width=512, height=512, alpha=False)
    image.filepath_raw = str(output_dir / (name + ".png"))
    image.file_format = "PNG"
    surface = surface or MODEL_SURFACES.get(name, "skin")
    # Materials are copied because several models deliberately share a palette.
    for index, original in enumerate(list(obj.data.materials)):
        mat = original.copy()
        obj.data.materials[index] = mat
        nodes = mat.node_tree.nodes
        emission = nodes.new("ShaderNodeEmission")
        mat.node_tree.links.new(procedural_color(mat, surface), emission.inputs["Color"])
        mat.node_tree.links.new(emission.outputs[0], nodes.get("Material Output").inputs["Surface"])
        target = nodes.new("ShaderNodeTexImage")
        target.image = image
        nodes.active = target
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 1
    scene.render.bake.margin = 8
    bpy.ops.object.bake(type="EMIT")
    image.save()
    image.pack()
    baked = bpy.data.materials.new(name + " baked albedo")
    baked.use_nodes = True
    texture = baked.node_tree.nodes.new("ShaderNodeTexImage")
    texture.image = image
    bsdf = baked.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (1, 1, 1, 1)
    bsdf.inputs["Roughness"].default_value = 0.6
    baked.node_tree.links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
    obj.data.materials.clear()
    obj.data.materials.append(baked)
    for polygon in obj.data.polygons:
        polygon.material_index = 0
    print(f"BAKE_OK {name} resolution=512x512 uv_loops={len(obj.data.uv_layers.active.data)}", flush=True)
    return obj


def connected_images(socket):
    pending = [link.from_node for link in socket.links]
    visited = set()
    images = []
    while pending:
        node = pending.pop()
        if node in visited:
            continue
        visited.add(node)
        if node.type == "TEX_IMAGE":
            images.append(node.image)
        for input_socket in node.inputs:
            pending.extend(link.from_node for link in input_socket.links)
    return images


def verify_texture(name, meshes):
    if any(not obj.data.uv_layers for obj in meshes):
        raise RuntimeError(f"Round-trip lost UVs for {name}")
    for obj in meshes:
        for mat in obj.data.materials:
            bsdf = mat.node_tree.nodes.get("Principled BSDF")
            images = connected_images(bsdf.inputs["Base Color"])
            if len(images) != 1:
                raise RuntimeError(f"Round-trip lost albedo connection for {name}")
            image = images[0]
            if tuple(image.size) != (512, 512):
                raise RuntimeError(f"Round-trip texture is not 512x512 for {name}")
