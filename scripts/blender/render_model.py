"""Build one model headlessly, render its review views, and optionally export it.

Run from the repository root:
    /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
      --python-exit-code 1 --python scripts/blender/render_model.py -- shoe \
      --output builds/model-test/rev-1 [--export]

Views: front (toe), side (outer profile), back (heel), elevated three-quarter, and
game, which uses the game camera's 70 degree tilt at the pixel size the model has
in its level, plus a 4x nearest-neighbour enlargement of that view.
"""
import argparse
import json
import math
import subprocess
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_assets as assets
from asset_builders.geometry import material, mesh_object, new_collection, rgba

VIEWS = {
    "front": Vector((1, 0, 0.12)),
    "side": Vector((0, -1, 0.12)),
    "back": Vector((-1, 0, 0.12)),
    "elevated_threequarter": Vector((1.0, -1.3, 1.0)),
}
GAME_TILT = math.radians(70.0)
GAME_PIXELS = 160


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", choices=assets.BUILDERS)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--export", action="store_true")
    parser.add_argument("--game-radius", type=float, default=0.48, help="Target radius of the model in its level")
    parser.add_argument("--view-size", type=float, default=21.0, help="Camera height in world units when the model is food")
    parser.add_argument("--ground", default="#84917B")
    parser.add_argument("--background", default="#9DB8C7")
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else [])


def build(name, export):
    assets.clear_scene()
    collection = new_collection(name)
    assets.BUILDERS[name](collection)
    assets.consolidate_by_material(collection, name)
    atlas = assets.MODEL_DIR / f"{name}.png" if export else Path(bpy.app.tempdir) / f"{name}.png"
    assets.bake_atlas(collection, name, str(atlas))
    assets.add_root_and_normalize(collection, name)
    if not export:
        return collection
    entry = assets.export_collection(collection, name, str(assets.MODEL_DIR / f"{name}.glb"))
    manifest = json.loads(assets.MANIFEST_PATH.read_text())
    manifest[name] = entry
    assets.MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    assets.verify_exported_glbs({name: entry})
    print(f"EXPORT_CHECK_OK {name} {entry}")
    return collection


def stage(background):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = rgba(background)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    scene.render.use_freestyle = True
    scene.render.line_thickness_mode = "ABSOLUTE"
    for layer in scene.view_layers:
        layer.use_freestyle = True
        lineset = layer.freestyle_settings.linesets[0] if layer.freestyle_settings.linesets else layer.freestyle_settings.linesets.new("Outline")
        lineset.select_by_visibility = True
        lineset.select_silhouette = True
        lineset.select_border = False
        lineset.select_crease = False
        lineset.linestyle.color = (0.055, 0.08, 0.10)
        # Line widths below are multiplied by the line style thickness of 3; the game ink is 2.5 px at 1080p.
        lineset.linestyle.thickness = 3.0
    for name, direction, energy, color in (
        ("Key", (-0.5, 0.7, -1.0), 3.2, "#FFF0D0"),
        ("Fill", (0.8, -0.4, -0.3), 1.0, "#98DCFF"),
    ):
        light = bpy.data.objects.new(name, bpy.data.lights.new(name, "SUN"))
        light.data.energy = energy
        light.data.color = rgba(color)[:3]
        light.rotation_mode = "QUATERNION"
        light.rotation_quaternion = Vector(direction).to_track_quat("-Z", "Y")
        scene.collection.objects.link(light)
    camera = bpy.data.objects.new("Review camera", bpy.data.cameras.new("Review camera"))
    camera.data.type = "ORTHO"
    camera.rotation_mode = "QUATERNION"
    scene.collection.objects.link(camera)
    scene.camera = camera
    return camera


def render(camera, center, direction, scale, size, line, path):
    scene = bpy.context.scene
    camera.location = center + direction.normalized() * 20
    camera.rotation_quaternion = (-direction).to_track_quat("-Z", "Y")
    camera.data.ortho_scale = scale
    camera.data.clip_end = 100
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.line_thickness = line
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    print(f"RENDERED {path}")


def main():
    args = parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    collection = build(args.model, args.export)
    camera = stage(args.background)
    low, high = assets.collection_bounds(collection)
    center, extent = (low + high) / 2, max(high - low)
    for view, direction in VIEWS.items():
        render(camera, center, direction, extent * 1.3, 1024, 1.0, args.output / f"{args.model}-{view}.png")

    ground = new_collection("Game ground")
    mesh_object(ground, "Concrete", [(-9, -9, 0), (9, -9, 0), (9, 9, 0), (-9, 9, 0)], [(0, 1, 2, 3)], material("Game concrete", args.ground))
    radius = max(high.x - low.x, high.y - low.y) / 2
    pixels_per_unit = 1080 / args.view_size * args.game_radius / radius
    # Godot's camera sits toward +Z at yaw 0, which is Blender's -Y after the glTF Y-up conversion.
    game_direction = Vector((0, -math.cos(GAME_TILT), math.sin(GAME_TILT)))
    game_path = args.output / f"{args.model}-game.png"
    render(camera, center, game_direction, GAME_PIXELS / pixels_per_unit, GAME_PIXELS, 0.8, game_path)
    subprocess.run(["magick", str(game_path), "-filter", "point", "-resize", "400%", str(args.output / f"{args.model}-game-x4.png")], check=True)
    print(f"MODEL_REVIEW_OK {args.model} game_pixels_across={2 * radius * pixels_per_unit:.1f}")


if __name__ == "__main__":
    main()
