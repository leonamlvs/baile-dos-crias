# Baile dos Crias — Specification Index

Status: **Draft baseline**  
Target date: 2026-09-19

This repository documentation is the implementation source of truth for **Baile dos Crias**, a portrait rhythm game for Web/itch.io built with Godot.

## Source precedence

When sources disagree, use this order:

1. Current files under `docs/`.
2. Accepted ADRs under `docs/decisions/`.
3. Wireframes for layout, proportions, and z-order.
4. Reference artwork for visual direction only.
5. The original `Baile dos Crias.md` as historical product context.

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

## Current source assets

1. Current files under `assets/ref/`.
2. Image files under `assets/ref/img/`.
3. Audio files under `assets/ref/audio/`.

- `playing-reference.png`
- `playing-wireframe.png`
- `score.png`
- `score-wireframe.png`
- `start.png`
- `start-wireframe.png`
- `BASE DE FUNK 150 BPM  INSTRUMENTAL  USO LIVRE 03 Prod DIL34N.mp3`
- `DJ André Marques Hero - O jogo (128 kbps).mp3` — current gameplay reference track, not automatically approved for redistribution.

## Local validation

Requires Godot `4.7.2.stable` and its matching Web export templates.

```powershell
godot --version
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/runner.gd
godot --headless --path . --export-release Web build/web/index.html
```

The first command verifies the pinned engine, the second imports and parses the
project, the third runs native M0 validation, and the fourth creates the local
Web release build. CI automation remains M6 scope.

Restricted environments may report inability to write Godot's editor cache,
`user://` logs, or the Windows certificate store. Treat these as environment
warnings only when the command still exits zero and validation reports no
project parse/resource failure; they must never hide a nonzero exit status.
