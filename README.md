# Baile dos Crias — Specification Index

Status: **Current specification index; individual documents identify accepted and TBD decisions**
Target date: 2026-09-19

This repository documentation is the implementation source of truth for **Baile dos Crias**, a portrait rhythm game for Web/itch.io built with Godot.

Authoritative MVP specs govern implemented behavior unless a section is
explicitly marked TBD. Specification authority does not mean acceptance
criteria or M6 release sign-off have passed.

## Source precedence

When sources disagree, use this order:

1. Current files under `docs/`.
2. Accepted ADRs under `docs/decisions/`.
3. Wireframes for layout, proportions, and z-order.
4. Reference artwork for visual direction only.
5. The original `Baile dos Crias.md` as historical product context when supplied; it is not present in this repository.

Legacy reference art may still show the old name **Baile dos Amigos** or outdated result labels. Do not copy those conflicts into the implementation.

## Documents

- `docs/product-spec.md` — product scope, flows, screens, MVP.
- `docs/gameplay-spec.md` — notes, timing, score, combo, ranks, win/loss.
- `docs/ui-ux-spec.md` — UI behavior, responsive rules, screen states.
- `docs/architecture.md` — Godot structure and responsibilities.
- `docs/input-spec.md` — keyboard, numpad, pointer, touch, multitouch.
- `docs/audio-timing-spec.md` — authoritative song clock and audio behavior.
- `docs/chart-format.md` — runtime chart JSON.
- `docs/chart-authoring.md` — MIDI/MPC authoring workflow.
- `docs/content-structure.md` — songs, metadata, characters, tables, assets.
- `docs/save-data-spec.md` — local save plus import/export backup.
- `docs/technical-constraints.md` — engine, renderer, Web, viewport.
- `docs/acceptance-criteria.md` — objective completion criteria.
- `docs/test-strategy.md` — automated and manual validation.
- `docs/contributing.md` — contribution rules.
- `docs/codex-instructions.md` — persistent instructions for Codex.
- `docs/implementation-plan.md` — implementation milestones.
- `docs/current-work.md` — current status, open decisions, next work.
- `docs/decisions/` — accepted architecture/product decisions.

## Tracked source assets

Tracked reference assets currently consist of the image files under
`assets/ref/img/`:

- `playing-reference.png`
- `playing-wireframe.png`
- `score.png`
- `score-wireframe.png`
- `start.png`
- `start-wireframe.png`

No audio is currently tracked. Local reference audio may exist under
`assets/ref/audio/`, but it is not a repository input and must not ship until its
redistribution evidence is approved in `content/release-content.json`.

## Local validation

Requires Godot `4.7.2.stable`, its matching Web export templates, and Python
3.10 or newer for the M5 authoring tool/tests.

```powershell
godot --version
python --version
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/runner.gd
python -m unittest discover -s tools/chart_import/tests -v
godot --headless --path . --script res://scripts/validate_release_content.gd
New-Item -ItemType Directory -Force build/web | Out-Null
godot --headless --path . --export-release Web build/web/index.html
python scripts/verify_web_export.py build/web
```

These commands verify the pinned tools, import and parse the project, run the
integrated M0–M6 suite, optionally run the Python importer suite directly,
create and verify the local Web release build, and enforce the MVP release
content gate. The release-content command intentionally exits nonzero while no
cleared playable song, character, and DJ table are present.

GitHub Actions repeats project import, native and Python tests, strict release
content validation, Web export, artifact verification, and artifact upload with
Godot `4.7.2.stable` and matching export templates.

Restricted environments may report inability to write Godot's editor cache,
`user://` logs, or the Windows certificate store. Treat these as environment
warnings only when the command still exits zero and validation reports no
project parse/resource failure; they must never hide a nonzero exit status.
