# Acceptance Criteria

Status: **Authoritative MVP acceptance baseline; release sign-off remains open**

## Project

- Opens in Godot 4.7.2 without parse/resource errors.
- Web export runs with Compatibility renderer.
- Layout preserves a 720×1280 logical portrait composition.

## Start

- Shows current logo, speakers, and `VAI`.
- `VAI` floats.
- Speakers pulse and spawn soundwaves to the 150 BPM Start track.
- Pointer/touch starts on release.
- `Space` and `Enter` start.

## Selection

- Character/table screen works with one item but data model supports more.
- Keyboard track focus and left/right selection work.
- Pointer/touch arrows and swipe work.
- Song cards support focus opacity, title overflow motion, preview, metadata, difficulty selection.
- Next remains disabled until a difficulty is selected.
- Personal high score changes with selected difficulty.

## Input

- Both keyboard layouts map correctly.
- Equivalent sources on one pad do not create duplicate presses.
- A logical release occurs only after all equivalent sources release.
- Multitouch supports simultaneous pads.
- A dragged finger remains bound to its starting pad.
- Chords and Hold+Tap combinations work.

## Gameplay

- Countdown precedes initial play and resume/retry.
- Notes visually reach target size at their hit time.
- Judgments use ±50/100/150/220 ms windows.
- Base points are 100/75/50/10/0.
- Combo/multiplier thresholds behave exactly as specified.
- Hold ticks yield PERFECT while held and MISS while released.
- Pre-held Hold starts as PERFECT.
- Tap requires a new press transition.
- 50 consecutive MISS judgments end the run.
- Any non-MISS resets MISS streak.
- Song end without 50 consecutive MISS is success.

## Results

- Shows all five judgment counts.
- Accuracy and rank match the specified formulas.
- Shows max positive combo and final score.
- Stores a new personal high score only when exceeded.
- Retry starts a clean run.
- Exit returns to song selection.

## Pause/focus

- Pause freezes gameplay timing/audio consistently.
- Focus loss auto-pauses without accumulating MISS.
- Resume uses countdown.

## Save/backup

- Settings and high scores survive a normal browser reload where browser storage persists.
- Export downloads a valid versioned backup.
- Import validates before replacement.
- Import requires explicit confirmation.
- Invalid/unsupported backup never overwrites current data.

## Charts

- Invalid JSON is rejected with actionable error output.
- Runtime charts with no notes are rejected.
- Every Hold tick satisfies `time_ms < tick_ms < end_ms`; a tick at the Hold
  start or exact end is rejected.
- Chords and variable-tempo authored material are representable through absolute timestamps.
- MIDI importer can map nine configurable MIDI notes to pads and emit valid JSON.
