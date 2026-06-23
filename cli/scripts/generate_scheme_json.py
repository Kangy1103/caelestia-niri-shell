#!/usr/bin/env python3
"""Generate scheme.json entries for schemes missing from the QML data.

Reads CLI key colours, runs gen_scheme() for full M3 palettes,
and merges them into services/scheme.json.
"""

import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO / "cli"))

from cns.utils.material.generator import gen_scheme, hex_to_hct
from cns.utils.scheme import scheme_data_dir as CLI_DATA

SCHEME_JSON_PATH = REPO / "services" / "scheme.json"
VARIANT = "tonalspot"


def txt_to_dict(path: Path) -> dict[str, str]:
    """Convert a CLI .txt colour file to a dict."""
    result = {}
    for line in path.read_text().strip().splitlines():
        if not line.strip():
            continue
        parts = line.strip().split(" ", 1)
        if len(parts) == 2:
            result[parts[0]] = parts[1]
    return result


class SimpleScheme:
    """Minimal scheme-like object for gen_scheme()."""
    def __init__(self, name: str, flavour: str, mode: str, variant: str = "tonalspot"):
        self.name = name
        self.flavour = flavour
        self.mode = mode
        self.variant = variant


def generate_scheme(name: str, flavour: str, primary_hex: str, mode: str) -> dict[str, str]:
    """Generate full M3 palette from a primary hex colour."""
    scheme = SimpleScheme(name, flavour, mode, VARIANT)
    primary_hct = hex_to_hct(primary_hex)
    return gen_scheme(scheme, primary_hct)


def load_existing_scheme_json() -> dict:
    with open(SCHEME_JSON_PATH) as f:
        return json.load(f)


def save_scheme_json(data: dict) -> None:
    # Sort top-level keys, then sort flavour dicts internally by key for diff readability
    ordered = {}
    for name in sorted(data.keys()):
        ordered[name] = {}
        for flavour in sorted(data[name].keys()):
            ordered[name][flavour] = {k: data[name][flavour][k] for k in sorted(data[name][flavour].keys())}
    with open(SCHEME_JSON_PATH, "w") as f:
        json.dump(ordered, f, indent=2)
        f.write("\n")


def main():
    data = load_existing_scheme_json()

    # --- Remove oldworld ---
    if "oldworld" in data:
        del data["oldworld"]
        print("Removed oldworld")

    # --- Replace onedark with genuine One Dark (primary = #61afef, dark-only) ---
    primary_onedark = "61afef"
    data["onedark"] = {
        "default": generate_scheme("onedark", "default", primary_onedark, "dark")
    }
    print(f"Replaced onedark with genuine One Dark (primary: #{primary_onedark})")

    # --- Caelestia: direct conversion from CLI dark.txt (already a full M3 palette) ---
    caelestia_dark = CLI_DATA / "caelestia" / "default" / "dark.txt"
    if caelestia_dark.exists():
        data["caelestia"] = {
            "default": txt_to_dict(caelestia_dark)
        }
        print("Added caelestia/default (dark, from CLI data)")

    # --- Schemes needing gen_scheme(): name, flavour, primary_hex, mode ---
    gen_schemes = [
        ("dracula", "medium", "BD93F9", "dark"),
        ("everblush", "medium", "8CCFB0", "dark"),
        ("everforest", "hard", "7FBBB3", "dark"),
        ("everforest", "medium", "7FBBB3", "dark"),
        ("everforest", "soft", "7FBBB3", "dark"),
        ("nord", "medium", "88C0D0", "dark"),
        ("solarized", "medium", "268BD2", "dark"),
        ("tokyonight", "medium", "7AA2F7", "dark"),
    ]

    for name, flavour, primary, mode in gen_schemes:
        if name not in data:
            data[name] = {}
        data[name][flavour] = generate_scheme(name, flavour, primary, mode)
        print(f"Generated {name}/{flavour} (primary: #{primary}, mode: {mode})")

    save_scheme_json(data)
    print(f"\nSaved {SCHEME_JSON_PATH}")
    print(f"Total scheme names: {len(data)}")
    total_flavours = sum(len(f) for f in data.values())
    print(f"Total flavour entries: {total_flavours}")


if __name__ == "__main__":
    main()
