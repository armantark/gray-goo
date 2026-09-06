"""Apply the canonical asset builders to the open Blender session through MCP."""
import argparse
import ast
import json
from pathlib import Path

from capture_views import call

PROJECT = Path(__file__).resolve().parents[2]


def asset_definitions():
    sources = [PROJECT / "scripts/asset_builders" / f"{name}.py"
               for name in ("geometry", "textures", "tide_pool", "skatepark", "particles", "space")]
    sources.append(PROJECT / "scripts/build_assets.py")
    definitions = {}
    for path in sources:
        for node in ast.parse(path.read_text()).body:
            if isinstance(node, ast.FunctionDef):
                definitions[node.name] = node
            elif isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name):
                if node.targets[0].id in {"SURFACES", "MODEL_SURFACES", "MODEL_COLORS", "BUILDERS"}:
                    definitions[node.targets[0].id] = node
    return definitions


def builder_code(names):
    definitions = asset_definitions()
    required = set()
    pending = list(names)
    while pending:
        name = pending.pop()
        if name in required or name not in definitions:
            continue
        required.add(name)
        pending.extend(child.id for child in ast.walk(definitions[name]) if isinstance(child, ast.Name))
    return "import bpy\nimport math\nfrom mathutils import Vector\n" + "\n\n".join(
        ast.unparse(node) for name, node in definitions.items() if name in required
    ) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("models", nargs="+")
    parser.add_argument("--pass-name", required=True)
    parser.add_argument("--export", action="store_true")
    args = parser.parse_args()
    destination = PROJECT / "builds/model-review" / args.pass_name
    destination.mkdir(parents=True, exist_ok=True)
    builder_map = asset_definitions()["BUILDERS"].value
    builders = {key.value: value.id for key, value in zip(builder_map.keys, builder_map.values)}
    for name in args.models:
        builder = builders[name]
        functions = [builder, "new_collection", "add_root_and_normalize"]
        if args.export:
            functions += ["consolidate_by_material", "bake_atlas", "export_collection"]
        code = builder_code(functions)
        code += f'''
for obj in bpy.context.scene.objects:
    obj.hide_set(False)
    obj.select_set(False)
old = bpy.data.collections.get({name!r})
offset = Vector((0, 0, 0))
if old:
    low, high = collection_bounds(old)
    offset = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
    for obj in list(old.all_objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(old)
collection = new_collection({name!r})
{builder}(collection)
root = add_root_and_normalize(collection, {name!r})
'''
        if args.export:
            code += f'''
export_copy = new_collection('ExportWorkingCopy')
for original in list(collection.objects):
    if original.type not in {{'MESH', 'CURVE'}}:
        continue
    obj = original.copy()
    obj.data = original.data.copy()
    obj.parent = None
    obj.matrix_world = original.matrix_world.copy()
    export_copy.objects.link(obj)
consolidate_by_material(export_copy, {name!r})
bake_atlas(export_copy, {name!r}, {str(PROJECT / 'assets/models' / (name + '.png'))!r})
entry = export_collection(export_copy, {name!r}, {str(PROJECT / 'assets/models' / (name + '.glb'))!r})
print('MANIFEST_ENTRY', entry)
for obj in list(export_copy.all_objects):
    bpy.data.objects.remove(obj, do_unlink=True)
bpy.data.collections.remove(export_copy)
'''
        code += "root.location += offset\nbpy.context.view_layer.update()\n"
        response = call("execute_blender_code", {
            "code": code,
            "user_prompt": "Refine the selected models in physically open Blender through MCP, review from multiple angles, and export the accepted game assets.",
        }, destination / f"{name}-build.json")
        if args.export:
            output = response["structuredContent"]["result"]
            entry = ast.literal_eval(output.split("MANIFEST_ENTRY ", 1)[1].splitlines()[0])
            manifest_path = PROJECT / "assets/asset_manifest.json"
            manifest = json.loads(manifest_path.read_text())
            manifest[name] = entry
            manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
        print(f"Applied {name} through MCP", flush=True)


if __name__ == "__main__":
    main()
