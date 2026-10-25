#!/usr/bin/env python3
"""Read keybinds from the active Umbriel configuration and write JSON."""

import json
import os
import sys
import tomllib
from pathlib import Path


def collect_config(path: Path, visited: set[Path], bindings: dict[str, object]) -> None:
    """Collect keybind tables while following Umbriel's ordered includes."""
    # Umbriel resolves includes from the config path as written. Keep symlink
    # paths lexical here: active-shell.toml is a symlink to a profile config.
    path = Path(os.path.abspath(path))
    if path in visited:
        return
    visited.add(path)

    with path.open("rb") as config_file:
        config = tomllib.load(config_file)

    included = config.get("include", {}).get("files", [])
    if not isinstance(included, list):
        raise ValueError(f"{path}: include.files must be an array")

    for entry in included:
        child = Path(entry).expanduser()
        if not child.is_absolute():
            child = path.parent / child
        collect_config(child, visited, bindings)

    table = config.get("keybinds", {})
    if not isinstance(table, dict):
        raise ValueError(f"{path}: keybinds must be a table")
    bindings.update(table)


def action_label(value: object, key: str) -> str:
    if isinstance(value, str):
        action = value
    elif isinstance(value, dict) and isinstance(value.get("action"), str):
        action = value["action"]
    else:
        raise ValueError(f"keybind {key!r} has no string action")

    if action.startswith("spawn:"):
        return f"Run {action.removeprefix('spawn:')}"
    readable = action.replace("-", " ").replace("_", " ").strip()
    return readable[:1].upper() + readable[1:]


def main() -> int:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} OUTPUT.json", file=sys.stderr)
        return 2

    config_home = Path(
        os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
    )
    root_config = config_home / "umbriel" / "config.toml"
    bindings: dict[str, object] = {}

    try:
        collect_config(root_config, set(), bindings)
        if not bindings:
            raise ValueError(f"no keybinds found through {root_config}")

        rows = [
            {"key": key, "action": action_label(value, key)}
            for key, value in bindings.items()
        ]
        output = Path(sys.argv[1])
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n")
    except (OSError, tomllib.TOMLDecodeError, ValueError) as error:
        print(f"Could not load Umbriel keybinds: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
