"""Capture isolated asset review angles through the validated Blender MCP client."""
import argparse
import json
from pathlib import Path
import subprocess
import time

PROJECT = Path(__file__).resolve().parents[2]
ANGLES = {
    "front": (0, -1, 0),
    "side": (1, 0, 0),
    "back": (0, 1, 0),
    "elevated_threequarter": (4, -6, 4),
}


def call(tool, arguments, destination):
    argument_path = destination.with_suffix(".args.json")
    argument_path.write_text(json.dumps(arguments, indent=2) + "\n")
    with destination.with_suffix(".log").open("w") as log:
        subprocess.run([
            "uv", "run", "--project", "tooling/blender-mcp", "--no-sync",
            "python", "scripts/blender/client.py", tool,
            f"--arguments={argument_path}", f"--output={destination}",
        ], cwd=PROJECT, stdout=log, stderr=log, check=True)
    response = json.loads(destination.read_text())
    result = (response.get("structuredContent") or {}).get("result", "")
    if response.get("isError") or (tool == "execute_blender_code" and not result.startswith("Code executed successfully:")):
        raise RuntimeError(json.dumps(response))
    return response


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", choices=("hermit_crab", "skater", "skateboard"))
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--user-prompt", required=True)
    parser.add_argument("--angle", choices=ANGLES)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    for angle, direction in ANGLES.items():
        if args.angle and args.angle != angle:
            continue
        code = f'''import bpy
from mathutils import Vector
collection = bpy.data.collections[{args.model!r}]
objects = list(collection.all_objects)
for obj in bpy.context.scene.objects:
    obj.hide_set(obj not in objects)
    obj.select_set(obj in objects)
mesh = next(obj for obj in objects if obj.type == 'MESH')
bpy.context.view_layer.objects.active = mesh
bpy.context.view_layer.update()
depsgraph = bpy.context.evaluated_depsgraph_get()
evaluated = [obj.evaluated_get(depsgraph) for obj in objects if obj.type in ('MESH', 'CURVE', 'SURFACE', 'FONT')]
points = [obj.matrix_world @ Vector(point) for obj in evaluated for point in obj.bound_box]
low = Vector(tuple(min(p[i] for p in points) for i in range(3)))
high = Vector(tuple(max(p[i] for p in points) for i in range(3)))
center = (low + high) / 2
extent = max(high - low)
area = next(a for a in bpy.context.screen.areas if a.type == 'VIEW_3D')
space = area.spaces.active
space.overlay.show_overlays = False
space.show_gizmo = False
space.shading.type = 'MATERIAL'
space.shading.use_scene_world = False
space.shading.use_scene_lights = False
region = space.region_3d
region.view_perspective = 'ORTHO'
region.view_location = center
region.view_rotation = Vector({direction!r}).to_track_quat('Z', 'Y')
region.view_distance = extent * 1.5
area.tag_redraw()
print({args.model!r}, {angle!r}, 'center', tuple(center), 'extent', extent, 'view_rotation', tuple(region.view_rotation), 'distance', region.view_distance)
'''
        stem = args.output / f"{args.model}-{angle}"
        call("execute_blender_code", {"code": code, "user_prompt": args.user_prompt}, stem.with_suffix(".camera.json"))
        time.sleep(3)
        call("get_viewport_screenshot", {"max_size": 1600, "user_prompt": args.user_prompt}, stem.with_suffix(".json"))
        print(stem.with_suffix(".0.png"), flush=True)


if __name__ == "__main__":
    main()
