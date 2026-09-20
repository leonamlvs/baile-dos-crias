#!/usr/bin/env python3
"""Validate the minimum launch artifacts produced by the Godot Web preset."""

from __future__ import annotations

import argparse
from pathlib import Path


REQUIRED_SUFFIXES = (".html", ".js", ".wasm", ".pck")
REQUIRED_SUPPORT_FILES = (
    "index.audio.worklet.js",
    "index.audio.position.worklet.js",
    "index.icon.png",
)
APPROVED_START_AUDIO_MARKER = b"BASE DE FUNK 150 BPM"
UNLICENSED_GAMEPLAY_AUDIO_MARKER = "DJ André Marques Hero".encode()


def verify(export_directory: Path) -> list[str]:
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
        if APPROVED_START_AUDIO_MARKER not in pack_bytes:
            errors.append("Web pack does not contain the approved Start audio.")
        if UNLICENSED_GAMEPLAY_AUDIO_MARKER in pack_bytes:
            errors.append("Web pack contains the unlicensed gameplay reference audio.")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    errors = verify(args.directory)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"Web export artifacts verified in {args.directory}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
