# Runtime Chart Format

Status: **Authoritative MVP baseline; explicit TBD items remain open**

## Purpose

Runtime charts are deterministic, human-readable JSON. MIDI is an authoring source, not the gameplay format.

All gameplay timing is absolute milliseconds.

## Minimal schema

```json
{
  "version": 1,
  "song_id": "song-id",
  "difficulty": "normal",
  "notes": [
    {
      "id": "n0001",
      "time_ms": 1240,
      "pad": 7,
      "type": "tap"
    },
    {
      "id": "n0002",
      "time_ms": 2400,
      "pad": 5,
      "type": "hold",
      "end_ms": 4200,
      "ticks_ms": [2869, 3337, 3806]
    }
  ]
}
```

## Fields

Chart:

- `version`: schema version.
- `song_id`: must match metadata.
- `difficulty`: difficulty identifier.
- `notes`: ordered note events; must contain at least one note.

Every note:

- `id`: unique within chart.
- `time_ms`: intended initial hit time.
- `pad`: integer `1..9`.
- `type`: `tap` or `hold`.

Hold only:

- `end_ms`: end time; must be greater than `time_ms`.
- `ticks_ms`: authoritative scoring ticks, sorted and strictly inside the Hold bounds.

## Runtime rules

- Notes with the same `time_ms` are valid chords.
- A Hold tick MUST satisfy `time_ms < tick_ms < end_ms`.
- Neither the initial Hold judgment nor the exact Hold end is a sustain tick.
- Overlapping Holds and Taps are valid.
- Multiple notes may exist on different pads simultaneously.
- The chart format does not require constant BPM.
- Runtime does not recalculate MIDI tempo.
- Visual approach duration/spawn lead time is presentation configuration, not part of judgment timing unless later required.
- Tap notes must not contain Hold-only `end_ms` or `ticks_ms` fields.

## Runtime traversal

The M2 `ChartPlayer` expands a validated chart into ordered absolute-time events:

- `note` at each Tap or Hold `time_ms`;
- `hold_tick` at every explicit tick;
- `hold_end` at each Hold `end_ms`.

Events with the same timestamp retain their source order. Advancing across a
render stall emits every crossed event exactly once. Time cannot move backwards;
retry requires an explicit reset of both chart traversal and the song clock.

## Validation

Reject a chart if:

- schema version unsupported;
- `notes` is empty;
- song/difficulty identifiers invalid;
- pad outside `1..9`;
- timestamps negative or unsorted where ordering is required;
- Hold has invalid `end_ms`;
- any Hold tick satisfies `tick_ms <= time_ms` or `tick_ms >= end_ms`;
- duplicate note IDs exist;
- required fields are missing or wrong type.

Do not silently repair invalid charts at runtime.
