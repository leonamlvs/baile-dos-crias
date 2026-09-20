# Current Work

Updated: **2026-09-19**

## State

M0 through M5 are implemented and locally validated:

- Godot 4.7.2 project with Compatibility renderer;
- 720×1280 portrait logical viewport with uniform non-cropping scaling;
- Web export preset;
- native headless GDScript validation runner;
- matching local Web export templates and verified local release export;
- data-driven content catalog with diagnostics that exclude invalid items while retaining valid contributions;
- save-v1 local persistence, export/import confirmation boundary, corrupt-save quarantine, and unsupported-version preservation;
- runtime-only cosmetic and product-flow `GameState` selection;
- nine-pad logical input aggregation with keyboard, mouse, touch, multitouch, touch binding, and focus clearing;
- `AudioManager` gameplay ownership, compensated monotonic song clock, and 15-second preview playback with 250 ms fades;
- strict runtime chart-v1 parsing and absolute-time `ChartPlayer` traversal;
- deterministic M3 note lifecycle, scoring, rank, success/failure, and clean retry;
- `ScreenRouter` AutoLoad limited to scene navigation/transitions;
- Start, Character/Table Select, Song/Difficulty Select, Gameplay Pause, and Results product screens;
- responsive placeholder composition, keyboard selection, playback countdown, focus-loss pause, high-score storage, and pulsing text `NEW RECORD` feedback;
- dependency-free Python Standard MIDI File importer with configurable nine-pad mapping, exact tempo-map conversion, Tap/Hold thresholds, explicit strict-interior Hold ticks, and deterministic chart-v1 output;
- 317 deterministic M0/M1/M2/M3/M4/M5 native headless checks, including 13 Python importer tests.

Locked core decisions:

- Godot 4.7.2 + GDScript + Compatibility renderer.
- Web/itch.io primary target.
- 720×1280 portrait logical layout.
- 3×3 pads with dual keyboard layouts + pointer/touch.
- Multi-source logical input aggregation.
- Touch bound to initial pad until lift.
- Chords and Hold+Tap overlap allowed.
- Song clock authoritative.
- Symmetric judgment windows and current scoring table.
- 50 consecutive MISS failure.
- Absolute-ms runtime JSON charts.
- MIDI as authoring source; JSON as runtime format.
- Local save plus manual JSON export/import.
- Personal high score scoped by song+difficulty.
- Native headless GDScript tests; no external Godot test framework for MVP.
- Python MIDI-file-to-JSON CLI; live MIDI capture is out of scope.
- `ScreenRouter` is an AutoLoad limited to navigation/transitions.
- Hold ticks satisfy `time_ms < tick_ms < end_ms`; start/end are not ticks.
- Runtime charts contain at least one note.
- Song previews loop for 15 seconds with 250 ms fades.
- Start music stops on exit; Character Select is silent.
- Proportional selection layouts, centered Pause modal, and pulsing `NEW RECORD` text.
- Save-v1 persists only master volume and high scores; cosmetic selection and session statistics are not persisted.
- Invalid content is diagnosed and excluded without blocking valid content.

## Next milestone

M6 — art/audio integration and Web/mobile QA:

- replace placeholders with production assets and cleared audio;
- integrate final Start effects and mobile layout polish;
- perform browser/device QA and itch.io release export;
- add CI headless validation and CI Web export.

Later content blockers remain: final MIDI mapping presets, real-device tuning of the `0.5 beat` authoring threshold, and redistribution rights or replacement for the public gameplay song.

## Rule

M5 is complete. Do not begin M6 without an explicit request. CI setup and CI Web export validation remain M6 scope.
