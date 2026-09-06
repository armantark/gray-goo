"""Pack the Godot web export and serve the exact compressed build locally."""

import argparse
import gzip
import shutil
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

OUTPUT = Path(__file__).resolve().parents[1] / "dist"
MIME = {".wasm": "application/wasm", ".pck": "application/octet-stream"}


def pack():
    shutil.copytree(OUTPUT.parent / "licenses", OUTPUT / "licenses", dirs_exist_ok=True)
    headers = []
    for suffix, content_type in MIME.items():
        path = OUTPUT / ("index" + suffix)
        raw = path.read_bytes()
        expected = b"\x00asm" if suffix == ".wasm" else b"GDPC"
        if not raw.startswith(expected):
            raise ValueError(f"Expected a fresh Godot export: {path}")
        compressed = gzip.compress(raw, compresslevel=9, mtime=0)
        path.write_bytes(compressed)
        headers.append(f"/{path.name}\n  Content-Encoding: gzip\n  Content-Type: {content_type}\n")
        print(f"{path.name}: {len(raw)} -> {len(compressed)} bytes")
    (OUTPUT / "_headers").write_text("\n".join(headers))
    for path in OUTPUT.rglob("*"):
        if path.is_file() and path.stat().st_size > 25 * 1024 * 1024:
            raise ValueError(f"Static asset exceeds the host limit: {path}")


class PreviewHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(OUTPUT), **kwargs)

    def end_headers(self):
        if Path(self.path.split("?", 1)[0]).suffix in MIME:
            self.send_header("Content-Encoding", "gzip")
        super().end_headers()


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
