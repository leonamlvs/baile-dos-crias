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

- AudioManager gameplay ownership through one dedicated player.
- Monotonic authoritative song clock compensated for audio mix/output latency.
- Strict JSON chart-v1 parser/validator with content-ID cross-check inputs.
- Absolute-time ChartPlayer events with stall catch-up and explicit reset.

Exit: deterministic timestamp events remain synchronized through playback
sampling, render stalls, pause/resume, completion, and clean retry.

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

## M6 — Placeholder integration + Web/mobile QA

- Keep simple geometric placeholders for production artwork not available in the repository.
  - Preserve intended dimensions, aspect ratios, anchors, positions, z-order, interaction areas, and animation bounds.
  - Keep visual asset slots isolated and replaceable so final artwork can be integrated later without changing gameplay logic or screen structure.
  - Do not generate, approximate, redraw, search for, or polish missing production artwork.
- Integrate only approved assets already available to the project.
- Integrate available approved audio where applicable.
- Implement beat-driven Start effects using the configured Start music.
- Implement song preview behavior defined in the specifications.
- Polish responsive mobile layout, touch behavior, and orientation handling using placeholders.
- Add background extension/letterboxing and landscape rotate-device behavior.
- Optimize for Compatibility/Web where needed.
- Produce and validate the itch.io Web export.
- Add CI headless validation and CI Web export.
- Perform browser/mobile/manual QA against the acceptance criteria.

Exit: release candidate is functionally complete and satisfies acceptance criteria using approved audio and replaceable visual placeholders; final production artwork may be integrated later without architectural or gameplay changes.

## Future

- Direct audio chart generation.
- Automatic difficulty derivation.
- Cloud accounts.
- Online leaderboards.
