"""Build the local Bible review document from canonical repository Markdown.

Run: python tools/build_bible_review.py (requires markdown-it-py).
All text is bundled; existing illustrations are referenced relative to the HTML.
Reviews live in browser storage or exported JSON, never in canonical sources.
"""
from __future__ import annotations

import hashlib
import json
import re
import subprocess
from datetime import datetime
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

from markdown_it import MarkdownIt

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs/reference/SolHunter_Worldbuilding_Bible.html"
BIBLE = "docs/reference/SolHunter_Worldbuilding_Bible.md"
ECOSYSTEM = "docs/reference/ecosystem.md"
MD = MarkdownIt("commonmark", {"html": False}).enable("table")


def slug(value):
    return re.sub(r"[^\w\- ]", "", value.lower()).replace(" ", "-")


def category(path):
    if path == ECOSYSTEM:
        return "Ecosystem"
    if path == BIBLE:
        return "Bible"
    if path == "docs/story.md" or "/decisions/" in path:
        return "Story & decisions"
    if path == "docs/reference/sol_bible.md" or "/sols/" in path:
        return "Species"
    if "roadmap" in path or path in {
        "docs/development-plan.md", "docs/vastra-integration.md",
        "docs/development-workstation.md", "docs/readiness-alpha-contract.md",
    }:
        return "Roadmaps"
    return "Reference"


def sections(text):
    """Split only real headings outside fences; keep every original text line."""
    result, lines, title, level, fenced, seen = [], [], "Introduction", 1, False, {}

    def finish():
        if not lines:
            return
        key = slug(title) or "introduction"
        seen[key] = seen.get(key, 0) + 1
        anchor = key if seen[key] == 1 else f"{key}-{seen[key] - 1}"
        result.append({"title": title, "level": level, "anchor": anchor,
                       "markdown": "".join(lines)})

    for line in text.splitlines(keepends=True):
        if re.match(r"^\s{0,3}(`{3,}|~{3,})", line):
            fenced = not fenced
        heading = None if fenced else re.match(r"^(#{1,3}) (.+?)\s*$", line)
        if heading:
            finish()
            title, level, lines = heading[2], len(heading[1]), []
        lines.append(line)
    finish()
    return result


def render(text, path, paths):
    tokens = MD.parse(text)
    for token in tokens:
        for child in token.children or []:
            attr = "src" if child.type == "image" else "href" if child.type == "link_open" else None
            if not attr:
                continue
            target = child.attrGet(attr) or ""
            parsed = urlsplit(target)
            if parsed.scheme or target.startswith("//"):
                # Keep external references, but do not execute unsafe protocols.
                if parsed.scheme.lower() not in {"https", "http", "mailto"}:
                    child.attrSet(attr, "#")
                continue
            dest = ((ROOT / path).parent / unquote(parsed.path)).resolve() if parsed.path else ROOT / path
            try:
                relative = dest.relative_to(ROOT).as_posix()
            except ValueError:
                child.attrSet(attr, "#")
                continue
            if relative in paths and attr == "href":
                child.attrSet(attr, "#" + quote(relative, safe="/") + ("::" + quote(unquote(parsed.fragment)) if parsed.fragment else ""))
            else:
                import os
                child.attrSet(attr, quote(os.path.relpath(dest, OUTPUT.parent).replace("\\", "/"), safe="/") + ("#" + parsed.fragment if parsed.fragment else ""))
            if child.type == "image":
                child.attrSet("loading", "lazy")
    return MD.renderer.render(tokens, MD.options, {})


def ecosystem_pictures():
    """Reuse original review artwork; add independently fingerprinted captures."""
    import os
    folder = ROOT / "artifacts/plant-closeup-review"
    manifest = folder / "review-manifest.json"
    current = ROOT / "artifacts/ecosystem-review/manifest.json"
    pictures = []
    source_hashes = {}

    def source_matches(path, expected):
        if path not in source_hashes:
            location = ROOT / path
            source_hashes[path] = hashlib.sha256(location.read_bytes()).hexdigest() if location.is_file() else None
        return source_hashes[path] == expected

    def image_path(base, name):
        path = (base / name).resolve()
        path.relative_to(ROOT)
        if not path.is_file():
            raise ValueError(f"Missing ecosystem picture: {path}")
        return quote(os.path.relpath(path, OUTPUT.parent).replace("\\", "/"), safe="/")

    if manifest.exists():
        for row in json.loads(manifest.read_text(encoding="utf-8"))["plants"]:
            versions = []
            for label, sample in [("Latest Plants review", row.get("revision", row)), ("Original Plants review", row)]:
                views = [image_path(folder, x) for x in sample["views"]]
                if versions and views == versions[0]["views"]:
                    continue
                versions.append({"label": label, "views": views})
            pictures.append({"code": row["code"], "name": row["name"], "biome": row["biome"],
                             "role": row["status"], "versions": versions})
    if current.exists():
        capture = json.loads(current.read_text(encoding="utf-8"))
        for row in capture["items"]:
            images = [image_path(current.parent, p) for p in row["views"]]
            valid = all(source_matches(p, h) for p, h in row["source_hashes"].items())
            valid = valid and all(hashlib.sha256((current.parent / p).read_bytes()).hexdigest() == h
                                  for p, h in row.get("image_hashes", {}).items())
            version = {"label": "Current isolated capture" if valid else "Capture needs refresh",
                       "views": images, "current": valid, "captured": row["captured"]}
            existing = next((p for p in pictures if p["code"] == row["code"]), None)
            if existing:
                existing["versions"].insert(0, version)
                existing["role"] = row["status"]
            else:
                pictures.append({"code": row["code"], "name": row["name"], "biome": row["biome"],
                                 "role": row["status"], "versions": [version]})
    for picture in pictures:
        picture["sha256"] = hashlib.sha256(json.dumps(picture, sort_keys=True).encode("utf-8")).hexdigest()
    return pictures


def build():
    paths = sorted(p.relative_to(ROOT).as_posix() for p in (ROOT / "docs").rglob("*.md"))
    records = []
    for path in paths:
        raw = (ROOT / path).read_bytes()
        # Some historical notes contain isolated Windows-1252 punctuation amid
        # UTF-8. Recover only those bytes; do not rewrite the original records.
        text = raw.decode("utf-8-sig", errors="surrogateescape")
        encoding = "utf-8-sig"
        if any(0xDC80 <= ord(c) <= 0xDCFF for c in text):
            text = "".join(bytes([ord(c) - 0xDC00]).decode("cp1252", errors="replace")
                           if 0xDC80 <= ord(c) <= 0xDCFF else c for c in text)
            encoding = "utf-8 with legacy Windows-1252 byte recovery"
        parts = sections(text)
        assert "".join(p["markdown"] for p in parts) == text, path
        for part in parts:
            part["id"] = path + "::" + part["anchor"]
            part["html"] = render(part["markdown"], path, set(paths))
            part["search"] = part.pop("markdown").lower()
        records.append({"path": path, "title": parts[0]["title"], "category": category(path),
                        "sha256": hashlib.sha256(raw).hexdigest(), "encoding": encoding, "sections": parts})
    git = Path(r"C:\Program Files\Git\cmd\git.exe")
    revision = subprocess.check_output([str(git) if git.exists() else "git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    payload = {"schema": 1, "date": "November 1, 2026", "built": datetime.now().astimezone().isoformat(timespec="seconds"),
               "revision": revision, "bible": BIBLE, "ecosystem": ECOSYSTEM,
               "ecosystemPictures": ecosystem_pictures(), "documents": records}
    data = json.dumps(payload, ensure_ascii=False).replace("<", "\\u003c").replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
    template = (ROOT / "tools/bible_review.html").read_text(encoding="utf-8")
    assert template.count("__BIBLE_DATA__") == 1
    OUTPUT.write_text(template.replace("__BIBLE_DATA__", data), encoding="utf-8")
    print(f"Built {OUTPUT.relative_to(ROOT)}: {len(records)} complete documents, {sum(len(d['sections']) for d in records)} review sections; source SHA-256 recorded for every document.")


if __name__ == "__main__":
    build()
