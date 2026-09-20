# Current Work

Updated: **2026-09-19**

## State

M0 through M5 are complete. M6 automated integration and release hardening are
implemented and locally validated, but M6 release sign-off is **blocked** by
missing cleared MVP content and outstanding human browser/device QA:

- Godot 4.7.2 project with Compatibility renderer;
- 720×1280 portrait logical viewport with uniform non-cropping scaling;
- Web export preset and deterministic artifact verifier;
- native headless GDScript validation runner;
- matching local Web export templates and verified local release export;
- data-driven content catalog with diagnostics that exclude invalid items while retaining valid contributions;
- save-v1 local persistence, export/import confirmation boundary, corrupt-save quarantine, and unsupported-version preservation;
- runtime-only cosmetic and product-flow `GameState` selection;
- nine-pad logical input aggregation with keyboard, mouse, touch, multitouch, touch binding, and focus clearing;
- `AudioManager` gameplay ownership, compensated monotonic song clock,
  playback-position-driven 150 BPM Start effects, and 15-second preview playback
  with 250 ms fades;
- strict runtime chart-v1 parsing and absolute-time `ChartPlayer` traversal;
- deterministic M3 note lifecycle, scoring, rank, success/failure, and clean retry;
- `ScreenRouter` AutoLoad limited to scene navigation/transitions;
- Start, Character/Table Select, Song/Difficulty Select, Gameplay Pause, and Results product screens;
- responsive placeholder composition, keyboard/swipe selection, mobile-safe
  controls, landscape rotate-device blocking, interruption-safe countdown,
  focus-loss pause, high-score storage, and pulsing text `NEW RECORD` feedback;
- a subordinate Start-screen Data modal with Web export/import, actionable
  rejection, and explicit Replace/Cancel confirmation;
- a GitHub Actions workflow pinned to Godot 4.7.2 and its matching templates,
  with project import, native/Python tests, strict content validation, Web
  export, artifact validation, and artifact upload;
- dependency-free Python Standard MIDI File importer with configurable nine-pad mapping, exact tempo-map conversion, Tap/Hold thresholds, explicit strict-interior Hold ticks, and deterministic chart-v1 output;
- 373 deterministic M0–M6 native headless checks, including 13 Python importer
  tests;
- a successful local Web release export containing HTML, JavaScript, WASM, PCK,
  audio worklets, and icons. The approved Start track is present; the unlicensed
  gameplay reference track is absent.

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
- The Start-screen Data control is subordinate to `VAI`; valid imports require
  explicit Replace, while Cancel and invalid/unsupported data cannot mutate the save.

## M6 release blockers

- Strict release-content validation currently fails because `content/` has no
  valid character, DJ table, or redistribution-cleared playable song with both
  MVP charts. The reference gameplay MP3 remains excluded from Web export.
- GitHub-hosted CI has been configured but was not executed from this local
  workspace. It will remain red at the strict content gate until the content
  blocker is resolved; export steps still run with `if: always()`.
- An automated Edge launch was attempted, but the available restricted Windows
  environment could not provide a usable browser GPU process. Browser runtime,
  IndexedDB persistence, download/file-picker behavior, itch.io embed/fullscreen,
  and browser focus behavior still require human browser QA.
- Physical-phone multitouch, Hold+Tap ergonomics, rotation, focus/app switching,
  safe-area/resizing, and audio sync still require real-device QA.
- Production character/table/logo/speaker/background artwork remains unavailable.
  Geometric slots are isolated and functional; replacing them is owner-supplied
  art integration, not a gameplay redesign.

Later content tuning remains: final MIDI mapping presets and real-device tuning
of the `0.5 beat` authoring threshold.

## Next work

Resolve the release-content/licensing gate, run the hosted CI workflow, then
complete the documented browser, itch.io, and physical-device checklist. Mark
M6 complete only after those checks pass.

## Rule

Do not begin post-M6 features. Keep the strict release gate intact and do not
ship the gameplay reference track without recorded redistribution rights.
