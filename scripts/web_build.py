"""Pack the Godot web export and serve the exact compressed build locally."""

import argparse
import gzip
import shutil
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

OUTPUT = Path(__file__).resolve().parents[1] / "dist"
BINARY_SUFFIXES = (".wasm", ".pck")


def pack():
    shutil.copytree(OUTPUT.parent / "licenses", OUTPUT / "licenses", dirs_exist_ok=True)
    for suffix in BINARY_SUFFIXES:
        path = OUTPUT / ("index" + suffix)
        raw = path.read_bytes()
        expected = b"\x00asm" if suffix == ".wasm" else b"GDPC"
        if not raw.startswith(expected):
            raise ValueError(f"Expected a fresh Godot export: {path}")
        compressed = gzip.compress(raw, compresslevel=9, mtime=0)
        path.write_bytes(compressed)
        print(f"{path.name}: {len(raw)} -> {len(compressed)} bytes")
    # Decode in Godot's preloader so static hosts need no header overrides.
    loader = OUTPUT / "index.js"
    source = loader.read_text()
    marker = "const tr = getTrackedResponse(response, tracker[file]);"
    if source.count(marker) != 1:
        raise ValueError("Godot preloader changed; review compressed asset loading")
    source = source.replace(marker, """if (file.endsWith('.wasm') || file.endsWith('.pck')) {
            response = new Response(response.body.pipeThrough(new DecompressionStream('gzip')));
        }
        """ + marker)
    loader.write_text(source)
    (OUTPUT / "_headers").unlink(missing_ok=True)
    for path in OUTPUT.rglob("*"):
        if path.is_file() and path.stat().st_size > 25 * 1024 * 1024:
            raise ValueError(f"Static asset exceeds the host limit: {path}")


class PreviewHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(OUTPUT), **kwargs)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["pack", "serve"])
    parser.add_argument("--port", type=int, default=8064)
    args = parser.parse_args()
    if args.action == "pack":
        pack()
    else:
        print(f"Gray Goo preview: http://127.0.0.1:{args.port}", flush=True)
        ThreadingHTTPServer(("127.0.0.1", args.port), PreviewHandler).serve_forever()
