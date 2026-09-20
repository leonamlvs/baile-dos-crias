# Test Strategy

Status: **Draft baseline**

## Priority

Automate deterministic rules; manually verify audio feel, browser behavior, touch ergonomics, and art integration.

## Automated tests

High value:

- Judgment boundary tests at every timing edge.
- Score/multiplier thresholds.
- Combo break/reset.
- Consecutive MISS reset and failure at 50.
- Accuracy/rank boundaries.
- Hold initial judgment and tick scoring.
- Input source aggregation (`0→1`, `1+→0`).
- Tap blocked while logical pad remains held.
- Chart schema validation.
- Save serialization/version validation.
- High-score replacement rules.
- Clean retry/session reset.

M1 additionally covers catalog diagnostics/exclusion, save-v1 validation and
quarantine behavior, explicit import confirmation, high-score replacement, and
nine-pad source aggregation. Persistence logic uses an in-memory store fake for
deterministic tests; the production store remains `user://`-backed.

M2 uses an injected fake playback source to test mix/latency compensation,
monotonic timing, pause/resume, completion, and clean retry. Chart tests cover
every validation boundary plus chord ordering, render-stall catch-up, backward
time rejection, and synchronized clock/chart reset.

M5 uses Python's standard `unittest` module and is invoked by the native
headless runner. It covers format-0/1 MIDI parsing, running status, variable
tempo maps, configurable pad mapping, Tap/Hold thresholds, strict interior Hold
ticks, malformed/pairing errors, runtime validation, and byte-identical output.

M6 adds deterministic coverage for Start beat phase, the 15-second preview
envelope, landscape-mobile blocking, shared touch-target minimums, selection
swipes, title overflow motion, responsive guard presence, the Start Data modal,
invalid/unsupported import rejection, explicit Replace/Cancel behavior,
countdown input blocking, interrupted countdown restart, CI configuration, and
release audio inclusion/exclusion rules.

## Headless validation

The MVP uses a small native GDScript test runner that extends `SceneTree` and runs
through Godot's `--headless --script` command. It reports deterministic pass/fail
results and exits nonzero on failure.

Do not add an external Godot test framework for the MVP.

Local validation should at least:

- import/load the Godot project;
- detect GDScript parse errors;
- load critical scenes/resources;
- run the native deterministic test suite.

M6 CI is defined in `.github/workflows/validate.yml`. A separate strict release
content command rejects a package without at least one valid song, character,
table, both MVP difficulties, and valid charts for every declared difficulty.
This is intentionally distinct from deterministic fixture tests.

## Manual desktop tests

- QWE/ASD/ZXC.
- Numpad with Num Lock on/off where OS/browser permits.
- Mixed equivalent inputs such as Q + KP7.
- Chords.
- Pause/retry/exit.
- Audio sync over a full song.
- Resize/portrait scaling.

## Manual mobile/Web tests

- Multi-finger Hold + Tap.
- Finger drag remains bound to initial pad.
- Rotate-device overlay.
- Focus/app switch auto-pause.
- Browser reload persistence.
- Backup export/import.
- itch.io embedded/fullscreen launch.

## Chart QA

Every contributed chart should be:

- schema-valid;
- playable through song end;
- checked for impossible/unintended overlaps;
- tested at its declared difficulty;
- reviewed for timing against the audio.
