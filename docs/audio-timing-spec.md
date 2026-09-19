# Audio and Timing Specification

Status: **Draft baseline**

## Core invariant

The song is the authoritative gameplay clock.

Note spawn/progress, hit judgment, Hold progress, Hold ticks, chart progression, and song completion MUST derive from song time, not accumulated frame delta.

## Song clock

Use Godot playback position with audio-mix/output-latency compensation appropriate for the locked engine version.

The M2 clock samples:

`playback_position + time_since_last_mix - output_latency`

It converts the result to absolute milliseconds, clamps it to zero, and never
reports a value lower than its previous playing sample. The clock is implemented
over an injectable playback source so pause/resume/retry behavior can be tested
without real audio output.

The exposed gameplay clock MUST:

- Be monotonic while playing.
- Stop while paused.
- Resume without chart drift.
- Reset cleanly on retry.
- Match chart timestamps expressed in absolute milliseconds.

Visual animation reads this clock; visual animation never defines timing.

`AudioManager` owns the gameplay `AudioStreamPlayer` and exposes start, pause,
resume, retry, stop, current song time, and completion state. Retry resets the
clock and begins the loaded stream from zero.

## Countdown

Initial start and gameplay resume/retry:

`3 → 2 → 1 → VAI! → active song/gameplay`

On resume, gameplay remains frozen until countdown completes.

## Start-screen music

Confirmed track:

`BASE DE FUNK 150 BPM  INSTRUMENTAL  USO LIVRE 03 Prod DIL34N.mp3`

Use declared 150 BPM for Start-screen beat effects.

Nominal beat interval:

`60 / 150 = 0.4 s`

Woofer pulse and soundwave events use a configurable beat offset so visual beats can be aligned to the actual track.

Do not perform real-time beat detection for this screen.

## Gameplay music

Current reference track:

`DJ André Marques Hero - O jogo (128 kbps).mp3`

Runtime charts use absolute timestamps, so gameplay MUST NOT assume constant BPM.

BPM/tempo maps matter during chart authoring/import, not hit judgment at runtime.

## Preview audio

The focused song card plays a 15-second looping preview. Each preview loop uses
a 250 ms fade-in and a 250 ms fade-out. The preview start timestamp is song
metadata and defaults to `0` when omitted.

Start-screen music stops when leaving Start. Character Select is silent. Song
Select owns preview playback; leaving it stops the preview.

## Pause

Pause must suspend active gameplay and audio coherently.

Retry seeks/restarts from the beginning and creates a new gameplay session.

Exit stops gameplay audio and discards the run.

## Volume

MVP exposes master volume in Pause and persists it in save data.
