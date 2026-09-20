# Tools

## MIDI chart importer

M5 provides a dependency-free Python CLI that converts an existing Standard
MIDI File into deterministic chart-v1 JSON. It supports MIDI formats 0 and 1
with ticks-per-quarter-note timing. SMPTE division and live MIDI capture are out
of scope.

```powershell
python tools/chart_import/midi_to_json.py `
  content/songs/example/source/normal.mid `
  content/songs/example/charts/normal.json `
  --config tools/chart_import/example-config.json `
  --song-id example `
  --difficulty normal
```

Configuration fields:

- `note_to_pad`: exactly nine distinct MIDI pitches mapped bijectively to pads
  `1..9`;
- `hold_threshold_beats`: duration at or above which a note becomes a Hold,
  default `0.5`;
- `hold_tick_beats`: interval between generated sustain ticks, default `1.0`;
- `unmapped_notes`: `ignore` by default, or `error` for strict authoring.

Generated timestamps are rounded to the nearest integer millisecond with exact
halves rounded upward. Hold tick beat positions must resolve to whole MIDI ticks
at the source file's resolution. Ticks that collapse at millisecond precision
are omitted, guaranteeing `time_ms < tick_ms < end_ms` and strict ordering.

Run importer tests directly with:

```powershell
python -m unittest discover -s tools/chart_import/tests -v
```
