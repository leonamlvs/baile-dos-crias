# Implementation Plan

Status: **Accepted roadmap**

Order is dependency-driven; do not implement unresolved polish before core timing/input is stable.

## M0 — Project baseline

- Godot 4.7.2 project, 720×1280 scaling, Compatibility renderer, Web preset,
  folder structure, and behavior-free placeholder scenes are present.
- Add the native headless GDScript validation runner and documented commands.
- Install matching Web export templates and validate a release export in the
  local development environment.
- CI setup and CI Web export validation remain M6 scope.

Exit: local headless validation passes, all placeholder scenes load, and a local
Web release export made with Godot 4.7.2 templates contains the required launch
artifacts.

## M1 — Data, save, input

- Content metadata loaders with per-item diagnostics and exclusion of invalid
  contributions.
- Save-v1 for master volume and personal high scores only; runtime cosmetic
  selection is not persisted.
- Local persistence with invalid-save quarantine and unsupported-version
  preservation.
- Pending-confirmation backup export/import adapter with a narrow Web bridge.
- Nine-pad InputRouter with source aggregation, touch binding, and focus clear.

Exit: deterministic M0/M1 input, save, and content tests pass headlessly.

## M2 — Audio clock + chart runtime

- AudioManager gameplay ownership.
- Authoritative song clock.
- JSON chart parser/validator.
- ChartPlayer.

Exit: timestamp events remain synchronized through play/pause/resume/retry.

## M3 — Gameplay core

- Pad grid.
- Tap.
- Hold.
- Chords.
- Judgments.
- Score/accuracy/combo/miss streak.
- Success/failure.

Exit: full placeholder chart can be played and scored deterministically.

## M4 — Product screens

- Start.
- Character/table selection.
- Song/difficulty selection.
- Pause.
- Results.
- Navigation/state wiring.

Exit: complete MVP flow works with placeholders.

## M5 — Chart authoring tool

- Python MIDI-file-to-JSON CLI; live MIDI capture is out of scope.
- Configurable MIDI pad map.
- MIDI tempo-map conversion.
- Tap/Hold conversion.
- Explicit Hold ticks.
- JSON validation/output.

Exit: a performed MIDI chart can become a playable chart without manual note entry.

## M6 — Art/audio integration + Web/mobile QA

- Replace placeholders with production assets.
- Beat-driven Start effects.
- Song preview.
- Mobile layout/touch polish.
- itch.io export.
- CI headless validation and CI Web export.
- Browser/mobile/manual QA.

Exit: release candidate satisfies acceptance criteria.

## Future

- Direct audio chart generation.
- Automatic difficulty derivation.
- Cloud accounts.
- Online leaderboards.
