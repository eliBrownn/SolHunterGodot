"""Check the reformat's single move map, UID continuity and literal script references."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def move_map():
    text = (ROOT / "docs/reformat-roadmap.md").read_text(encoding="utf-8")
    section = text.split("<!-- reformat-move-map:start -->", 1)[1].split(
        "<!-- reformat-move-map:end -->", 1
    )[0]
    result = {}
    for line in section.splitlines():
        if not line.startswith("| "):
            continue
        destination, stems = [part.strip() for part in line.split("|")[1:3]]
        if destination.startswith(("Destination", "---")):
            continue
        for stem in stems.split(", "):
            old = "scripts/" + stem + ".gd"
            if old in result:
                raise ValueError("Duplicate owner: " + old)
            result[old] = "scripts/" + destination + "/" + stem + ".gd"
    return result


def main():
    mapping = move_map()
    failures = []
    expected = set(mapping.values())
    actual = {p.relative_to(ROOT).as_posix() for p in (ROOT / "scripts").rglob("*.gd")}
    for path in sorted(expected - actual):
        failures.append("Missing owned script: " + path)
    for path in sorted(actual - expected):
        failures.append("Script absent from ownership map: " + path)
    uids = {}
    for path in sorted(actual):
        sidecar = ROOT / (path + ".uid")
        if not sidecar.is_file():
            failures.append("Missing UID: " + path)
            continue
        uid = sidecar.read_text(encoding="utf-8").strip()
        if not uid.startswith("uid://") or uid in uids:
            failures.append("Invalid or duplicate UID: " + path)
        uids[uid] = path
    for folder in ["scripts", "resources", "scenes", "tests", "tools"]:
        for path in (ROOT / folder).rglob("*"):
            if path.suffix not in {".gd", ".tscn", ".tres", ".ps1", ".py"}:
                continue
            text = path.read_text(encoding="utf-8-sig")
            for reference in re.findall(r'res://(scripts/[a-zA-Z0-9_/]+\.gd)\b', text):
                if not (ROOT / reference).is_file():
                    failures.append("Broken script reference in %s: %s" % (path.relative_to(ROOT), reference))
    for failure in failures:
        print(failure)
    print("SCRIPT OWNERSHIP: %d mapped scripts, %d UIDs, %d failures" % (len(mapping), len(uids), len(failures)))
    return bool(failures)


if __name__ == "__main__":
    sys.exit(main())
