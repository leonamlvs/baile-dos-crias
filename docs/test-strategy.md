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

CI execution and CI Web export validation are M6 scope.

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
