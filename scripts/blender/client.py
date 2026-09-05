"""Call the project's three allowed MCP tools without printing image payloads."""
import argparse
import asyncio
import base64
import json
from pathlib import Path

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

PROJECT = Path(__file__).resolve().parents[2]
TOOLS = ("get_scene_info", "execute_blender_code", "get_viewport_screenshot")


async def run(args):
    server = StdioServerParameters(command=str(PROJECT / "scripts/blender/server.sh"))
    async with stdio_client(server) as streams:
        async with ClientSession(*streams) as session:
            initialized = await session.initialize()
            if args.tool == "catalog":
                catalog = await session.list_tools()
                selected = [tool.model_dump() for tool in catalog.tools if tool.name in TOOLS]
                report = {"server": initialized.serverInfo.model_dump(), "tools": selected}
            else:
                arguments = json.loads(Path(args.arguments).read_text()) if args.arguments else {}
                result = await session.call_tool(args.tool, arguments)
                report = result.model_dump()
                for index, item in enumerate(report["content"]):
                    if item["type"] == "image":
                        path = Path(args.output).with_suffix(f".{index}.png")
                        path.write_bytes(base64.b64decode(item.pop("data")))
                        item["path"] = str(path)
            Path(args.output).write_text(json.dumps(report, indent=2) + "\n")
            print(json.dumps({"output": args.output, "isError": report.get("isError", False)}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tool", choices=("catalog", *TOOLS))
    parser.add_argument("--arguments")
    parser.add_argument("--output", required=True)
    asyncio.run(run(parser.parse_args()))
