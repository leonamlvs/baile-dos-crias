# Current Work

Updated: **2026-09-19**

## State

M0 through M3 are implemented and locally validated:

- Godot 4.7.2 project with Compatibility renderer;
- 720×1280 portrait logical viewport with uniform non-cropping scaling;
- Web export preset;
- planned folder structure and placeholder product screens;
- native headless GDScript validation runner;
- matching local Web export templates and verified local release export;
- data-driven content catalog with diagnostics that exclude invalid items while
  retaining valid contributions;
- save-v1 local persistence, export/import confirmation boundary, corrupt-save
  quarantine, and unsupported-version preservation;
- runtime-only cosmetic `GameState` selection;
- nine-pad logical input aggregation with keyboard, mouse, touch, multitouch,
  touch binding, and focus clearing;
- `AudioManager` gameplay ownership and compensated monotonic song clock;
- strict runtime chart-v1 parsing and validation;
- absolute-time `ChartPlayer` traversal with chord ordering, render-stall
  catch-up, pause stability, and clean retry;
- scene-local 3×3 gameplay pad grid with keyboard, pointer, and multitouch routing;
- song-time-derived Tap expansion and Hold progress presentation;
- deterministic Tap/Hold/chord lifecycle with pre-hold, release/resume, explicit
  Hold ticks, and exact-window expiry;
- judgment, score, positive combo/multiplier, MISS streak, accuracy, rank, and
  success/failure gameplay services;
- clean gameplay retry/reset across notes, score, timers, and physical/logical
  held input state;
- 288 deterministic M0/M1/M2/M3 native headless checks.

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
- Save-v1 persists only master volume and high scores; cosmetic selection and
  session statistics are not persisted.
- Invalid content is diagnosed and excluded without blocking valid content.

## Next milestone

M4 — product screens:

- Start and navigation flow;
- character/table and song/difficulty selection;
- Pause and Results screens;
- screen/state/audio wiring around the completed gameplay core.

Later content blockers remain: final MIDI mapping presets, real-device tuning of
the `0.5 beat` authoring threshold, and redistribution rights or replacement for
the public gameplay song.

## Rule

M3 is complete. Do not begin M4 without an explicit request. CI setup and CI Web
export validation remain M6 scope.
