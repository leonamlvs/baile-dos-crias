#!/usr/bin/env python3
"""Validate the minimum launch artifacts produced by the Godot Web preset."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


REQUIRED_SUFFIXES = (".html", ".js", ".wasm", ".pck")
REQUIRED_SUPPORT_FILES = (
    "index.audio.worklet.js",
    "index.audio.position.worklet.js",
    "index.icon.png",
)
APPROVED_START_AUDIO_MARKER = b"BASE DE FUNK 150 BPM"
UNLICENSED_GAMEPLAY_AUDIO_MARKER = "DJ André Marques Hero".encode()
DEFAULT_INVENTORY = Path("content/release-content.json")


def _load_inventory(path: Path) -> tuple[dict, list[str]]:
    if not path.is_file():
        return {}, [f"Release content inventory does not exist: {path}"]
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return {}, [f"Release content inventory is invalid: {error}"]
    if not isinstance(value, dict):
        return {}, ["Release content inventory root must be an object."]
    return value, []


def verify(export_directory: Path, inventory_path: Path = DEFAULT_INVENTORY) -> list[str]:
    errors: list[str] = []
    if not export_directory.is_dir():
        return [f"Web export directory does not exist: {export_directory}"]

    files = [path for path in export_directory.iterdir() if path.is_file()]
    for suffix in REQUIRED_SUFFIXES:
        matches = [path for path in files if path.suffix == suffix and path.stat().st_size > 0]
        if not matches:
            errors.append(f"Missing non-empty Web export artifact: *{suffix}")

    for filename in REQUIRED_SUPPORT_FILES:
        path = export_directory / filename
        if not path.is_file() or path.stat().st_size <= 0:
            errors.append(f"Missing non-empty Web support artifact: {filename}")

    index = export_directory / "index.html"
    if index.is_file():
        html = index.read_text(encoding="utf-8")
        for expected in ("index.js", "index.wasm", "index.pck"):
            if expected not in html:
                errors.append(f"index.html does not reference {expected}")

    pack = export_directory / "index.pck"
    if pack.is_file():
        pack_bytes = pack.read_bytes()
        if UNLICENSED_GAMEPLAY_AUDIO_MARKER in pack_bytes:
            errors.append("Web pack contains the unlicensed gameplay reference audio.")
        inventory, inventory_errors = _load_inventory(inventory_path)
        errors.extend(inventory_errors)
        project_license = inventory.get("project_license", {})
        if not isinstance(project_license, dict) or project_license.get("status") != "approved":
            errors.append("Project license is not approved in the release content inventory.")
        entries = inventory.get("entries", [])
        if not isinstance(entries, list):
            errors.append("Release content inventory entries must be an array.")
            entries = []
        for entry in entries:
            if not isinstance(entry, dict) or not entry.get("include_in_release", False):
                continue
            path = entry.get("path", "<missing path>")
            if not entry.get("cleared", False):
                errors.append(f"Release content is not cleared: {path}")
                continue
            marker = entry.get("package_marker", "")
            if not isinstance(marker, str) or not marker:
                errors.append(f"Release content has no package marker: {path}")
            elif marker.encode("utf-8") not in pack_bytes:
                errors.append(f"Web pack does not contain inventoried content: {path}")
        start_entries = [entry for entry in entries if isinstance(entry, dict) and entry.get("kind") == "start_audio"]
        if any(entry.get("cleared", False) for entry in start_entries) and APPROVED_START_AUDIO_MARKER not in pack_bytes:
            errors.append("Web pack does not contain the cleared Start audio.")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY)
    args = parser.parse_args()
    errors = verify(args.directory, args.inventory)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"Web export artifacts verified in {args.directory}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
