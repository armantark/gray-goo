"""Procedural color atlases baked in Blender, shared by models and grounds."""
from __future__ import annotations

import math

import bpy


# Fine pores and granules are confined to surfaces where they explain the material.
SURFACES = {"grip": (95.0, 0.16), "sand": (85.0, 0.12), "concrete": (110.0, 0.10)}


def procedural_color(mat: bpy.types.Material, surface: str) -> bpy.types.NodeSocket:
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    base = nodes.new("ShaderNodeRGB")
    base.outputs[0].default_value = mat.diffuse_color
    if surface not in SURFACES:
        return base.outputs[0]
    scale, contrast = SURFACES[surface]
    coordinate = nodes.new("ShaderNodeTexCoord")
    pores = nodes.new("ShaderNodeTexVoronoi")
    pores.feature = "F1"
    pores.inputs["Scale"].default_value = scale
    links.new(coordinate.outputs["Generated"], pores.inputs["Vector"])
    speckle = nodes.new("ShaderNodeValToRGB")
    speckle.color_ramp.elements[0].position = 0.07
    speckle.color_ramp.elements[0].color = (1 - contrast, 1 - contrast, 1 - contrast, 1)
    speckle.color_ramp.elements[1].position = 0.18
    speckle.color_ramp.elements[1].color = (1, 1, 1, 1)
    links.new(pores.outputs["Distance"], speckle.inputs["Fac"])
    mix = nodes.new("ShaderNodeMixRGB")
    mix.blend_type = "MULTIPLY"
    mix.inputs[0].default_value = 1.0
    links.new(base.outputs[0], mix.inputs[1])
    links.new(speckle.outputs["Color"], mix.inputs[2])
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


def bake_atlas(collection, name: str, output_path: str):
    obj = join_and_unwrap(collection, name)
    image = bpy.data.images.new(name + "_albedo", width=512, height=512, alpha=False)
    image.filepath_raw = output_path
    image.file_format = "PNG"
    # Materials are copied because several models deliberately share a palette.
    for index, original in enumerate(list(obj.data.materials)):
        mat = original.copy()
        obj.data.materials[index] = mat
        nodes = mat.node_tree.nodes
        emission = nodes.new("ShaderNodeEmission")
        mat.node_tree.links.new(procedural_color(mat, mat["texture_surface"]), emission.inputs["Color"])
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
