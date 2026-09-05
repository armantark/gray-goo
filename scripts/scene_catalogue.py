"""Assemble and check delegated scene data, then render its review document."""

import argparse
from collections import Counter
import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / "docs/design"
BANDS = [
    "subatomic", "atomic", "molecular", "microscopic",
    "miniature", "tabletop", "human", "landscape",
    "planetary", "stellar", "galactic", "spacetime",
]
FIELDS = {"id", "source_id", "band", "title", "setting", "food", "interaction", "jumps", "parts", "risk"}
SOURCES = json.loads((DESIGN / "sources/original-levels.json").read_text())
BY_SOURCE = {r["id"]: r for r in SOURCES}


def validate_scene(row):
    assert set(row) == FIELDS, f"Unexpected fields in scene {row.get('id')}"
    assert all(isinstance(row[k], str) and row[k].strip() for k in FIELDS - {"id", "source_id", "jumps", "parts"})
    assert row["source_id"] is None or row["source_id"] in BY_SOURCE
    assert row["band"] in BANDS
    assert isinstance(row["jumps"], list) and len(row["jumps"]) <= 2
    assert all(isinstance(j, str) and j.strip() for j in row["jumps"])
    assert row["parts"] is None or isinstance(row["parts"], str) and row["parts"].strip()


def candidates():
    rows = []
    for name, start, end in (
        ("micro", 1, 36),
        ("everyday", 37, 132),
        ("cosmos", 133, 240),
    ):
        data = json.loads((DESIGN / "candidates" / f"{name}.json").read_text())
        assert [r["id"] for r in data] == list(range(start, end + 1)), name
        for row in data:
            validate_scene(row)
        rows.extend(data)
    assert any(not r["jumps"] for r in rows), "Missing single-view levels"
    assert len({r["title"].casefold() for r in rows}) == 240, "Duplicate scene titles"
    return rows


def prepare(rows):
    (DESIGN / "catalogue.json").write_text(json.dumps(rows, indent=2, ensure_ascii=False) + "\n")
    prompt = (DESIGN / "curation-instructions.txt").read_text()
    prompt += "\n<sources>" + json.dumps(SOURCES) + "</sources>"
    prompt += "\n<band_order>" + json.dumps(BANDS) + "</band_order>\n<candidates>\n"
    prompt += "\n".join(json.dumps(row, ensure_ascii=False) for row in rows)
    prompt += "\n</candidates>\n"
    (DESIGN / "curation-prompt.txt").write_text(prompt)
    print(json.dumps({"candidates": len(rows), "bands": Counter(r["band"] for r in rows)}))


def scene(row, reason="", number=None):
    esc = html.escape
    label = f"LEVEL {number:02d}" if number is not None else f"SCENE {row['id']:03d}"
    fields = [("Eat", row["food"]), ("Interaction", row["interaction"]), ("Size jumps", "None. One view throughout." if not row["jumps"] else " / ".join(row["jumps"]))]
    if row["parts"]:
        fields.append(("Parts to whole", row["parts"]))
    if reason:
        fields.append(("Why selected", reason))
    fields.append(("Design risk", row["risk"]))
    body = "".join(f"<dt>{esc(k)}</dt><dd>{esc(v)}</dd>" for k, v in fields)
    source_html = ""
    if row["source_id"]:
        source = BY_SOURCE[row["source_id"]]
        chapter = {"laboratory": "Laboratory", "outside": "Outside", "picnictable": "Picnic Table", "ocean": "Ocean", "park": "Park", "city": "City", "sky": "Sky", "orbit": "Orbit", "cosmos": "Cosmos"}[source["chapter"]]
        url = "https://strategywiki.org/wiki/Tasty_Planet/" + chapter.replace(" ", "_") if source["chapter"] in {"laboratory", "outside", "picnictable", "ocean", "park", "city"} else "https://www.dingogames.com/tastyplanet/"
        source_html = f'<p class="source">Design influence: <a href="{esc(url)}">{chapter} {source["level"]}</a></p>'
    return f'<article id="scene-{row["id"]}-{number or 0}"><small>{label} · {esc(row["band"])}</small><h3>{esc(row["title"])}</h3><p>{esc(row["setting"])}</p><dl>{body}</dl>{source_html}</article>'


def selection(rows):
    raw = json.loads((DESIGN / "curation.raw.json").read_text())
    review = json.loads(raw["result"])
    campaign = [r["scene_id"] for r in review["campaign"]]
    prototype = [r["scene_id"] for r in review["prototype"]]
    by_id = {r["id"]: r for r in rows}
    assert len(campaign) == len(set(campaign)) == 60
    assert len(prototype) == len(set(prototype)) == 4
    assert set(campaign) <= by_id.keys() and set(prototype) <= set(campaign)
    band_order = [BANDS.index(by_id[i]["band"]) for i in campaign]
    assert band_order == sorted(band_order), "Campaign moves backward between scale bands"
    assert any(not by_id[i]["jumps"] for i in campaign), "Campaign forces jumps in every level"
    assert band_order[0] == 0 and band_order[-1] == 11
    (DESIGN / "selection.json").write_text(json.dumps(review, indent=2, ensure_ascii=False) + "\n")
    return review, by_id, campaign, prototype


def render(rows):
    review, by_id, campaign, prototype = selection(rows)
    esc = html.escape
    prototype_html = "".join(scene(by_id[r["scene_id"]], r["reason"]) for r in review["prototype"])
    campaign_html = []
    for band in BANDS:
        selected = [(n, r) for n, r in enumerate(review["campaign"], 1) if by_id[r["scene_id"]]["band"] == band]
        cards = "".join(scene(by_id[r["scene_id"]], r["reason"], n) for n, r in selected)
        campaign_html.append(f'<details><summary>{esc(band.title())}<span>{len(selected)} levels</span></summary><div class="grid">{cards}</div></details>')
    all_html = "".join(f'<details><summary>{esc(b.title())}<span>{sum(r["band"] == b for r in rows)} candidates</span></summary><div class="grid">' + "".join(scene(r) for r in rows if r["band"] == b) + '</div></details>' for b in BANDS)
    risks = "".join(f"<li>{esc(v)}</li>" for v in review["risks"])
    corrections = "".join(f"<li>{esc(v)}</li>" for v in review["corrections"])
    document = """<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Gray goo · Scene atlas</title><link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ccircle cx='32' cy='32' r='27' fill='%239aa5b6'/%3E%3C/svg%3E"><style>
    :root{--bg:#0c0e12;--surface:#161a21;--surface-2:#1e232c;--border:#2a3040;--text:#e8ecf4;--text-dim:#a2acbd;--accent:#4f8cff;--accent-glow:rgba(79,140,255,.15);--red:#ff5c5c;--green:#4ade80;--amber:#fbbf24;--purple:#a78bfa;--radius:12px;color-scheme:dark}
    *{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:16px/1.6 Outfit,system-ui,sans-serif}main{max-width:1240px;margin:auto;padding:48px 24px 80px}header{border-bottom:1px solid var(--border);padding-bottom:28px;margin-bottom:36px}h1{font-size:clamp(2rem,6vw,3.8rem);line-height:1.08;margin:18px 0}h2{margin-top:40px}h3{line-height:1.3;margin:8px 0 12px}p{color:var(--text-dim);max-width:85ch}a{color:#8eb9ff;text-underline-offset:4px}nav{display:flex;gap:24px;flex-wrap:wrap}.badge,small{font:12px/1.5 'JetBrains Mono',monospace;letter-spacing:.06em;color:var(--green)}.counts{display:flex;gap:32px;margin:26px 0;flex-wrap:wrap}.counts b{display:block;font-size:34px;line-height:1.2}.counts span{color:var(--text-dim)}.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}article{min-width:0;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:22px;overflow-wrap:anywhere}article p{margin:0 0 16px}dl{margin:0}dt{font-size:12px;text-transform:uppercase;letter-spacing:.08em;color:var(--text-dim);margin-top:12px}dd{margin:2px 0 0;font-size:14px}details{border-top:1px solid var(--border);margin:0 0 10px;padding-top:4px}summary{padding:15px 5px;cursor:pointer;font-size:19px}summary span{float:right;font-size:13px;color:var(--text-dim);padding-top:5px}details[open]>summary{color:var(--green)}.notice{border-left:3px solid var(--amber);padding:12px 20px;background:var(--surface-2);margin:26px 0}.notice p{margin:0}li{margin-bottom:12px}footer{margin-top:48px;padding-top:20px;border-top:1px solid var(--border);color:var(--text-dim);font-size:13px}@media(max-width:700px){main{padding:28px 16px 56px}.grid{grid-template-columns:1fr}.counts{gap:24px}article{padding:18px}summary span{float:none;display:block;padding-left:19px}}
    </style></head><body><main><header><span class="badge">EXPLORATION RESULTS · DESIGN PROPOSAL</span><h1>From particles<br>to spacetime.</h1><p>SCENE_SUMMARY</p><div class="counts"><div><b>240</b><span>scene candidates</span></div><div><b>60</b><span>campaign selections</span></div><div><b>4</b><span>prototype recommendations</span></div></div><nav><a href="#prototype">Prototype</a><a href="#campaign">Campaign</a><a href="#risks">Open design work</a><a href="#catalogue">All candidates</a></nav></header><aside class="notice"><p>This is a scene proposal. The first Tasty Planet informs pacing, playful arrangements, and growth rewards. These are new scene proposals, not copies of its levels. The source is its official Mac demo, edition 1.4.1; identity with the 2006 release is unverified. New interactions, edible parts, and camera jumps are our proposals. A level can have zero, one, or two jumps. No levels are built yet. Exact scale continuity and balance remain open.</p></aside><section id="prototype"><h2>Four scenes to build first</h2><div class="grid">PROTOTYPE_CARDS</div></section><section id="campaign"><h2>The proposed campaign</h2><p>Open a scale band to see its levels in campaign order.</p>CAMPAIGN_CARDS</section><section id="risks"><h2>Open design work</h2><ul>DESIGN_RISKS</ul>CORRECTIONS</section><section id="catalogue"><h2>The full candidate pool</h2><p>These include scenes the curator did not select. Open a scale band to review alternatives.</p>ALL_CARDS</section><footer>Drafted by three Luna agents. Curated by Kimi K3. Codex checked counts, source references, jump limits, and campaign order. Original levels supplied design influences. The campaign does not follow their level list or require coverage of each source. Final scene choices remain with the user.</footer></main></body></html>"""
    replacements = {
        "SCENE_SUMMARY": esc(review["summary"]), "PROTOTYPE_CARDS": prototype_html,
        "CAMPAIGN_CARDS": "".join(campaign_html), "DESIGN_RISKS": risks,
        "CORRECTIONS": f"<h3>Candidate corrections</h3><ul>{corrections}</ul>" if corrections else "",
        "ALL_CARDS": all_html,
    }
    for key, value in replacements.items():
        document = document.replace(key, value)
    path = ROOT / "memory-bank/status-updates/scene-atlas-2026-09-04.html"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(document)
    print(json.dumps({"candidates": len(rows), "campaign": len(campaign), "prototype": len(prototype), "bands": Counter(by_id[i]["band"] for i in campaign), "artifact": str(path)}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("prepare", "render"))
    args = parser.parse_args()
    data = candidates()
    (prepare if args.action == "prepare" else render)(data)
