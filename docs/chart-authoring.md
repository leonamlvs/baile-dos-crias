# Chart Authoring

Status: **Draft baseline**

## Goal

A contributor must be able to create a chart by performing it on an MPC/MIDI controller instead of typing every note manually.

The MVP importer is a deterministic Python CLI that reads an existing MIDI file
and writes runtime JSON. Live MIDI capture is out of scope.

## Pipeline

```text
song + MIDI performance
        ↓
deterministic importer
        ↓
validation / preview
        ↓
runtime JSON
```

MIDI is kept as editable source material when available. JSON is what the game loads.

## MIDI mapping

Importer configuration maps nine MIDI notes/pitches to logical pads `1..9`.

The mapping MUST be configurable; do not hard-code one controller model.

MIDI tempo changes MUST be respected when converting musical timing to absolute milliseconds.

## Tap vs Hold

Default authoring rule:

- Short MIDI note → Tap.
- Long MIDI note → Hold.

Use a configurable threshold expressed in beats, not a fixed millisecond value.

Initial default: `0.5 beat`.

This threshold is importer configuration, not a gameplay invariant, and may be tuned after real MPC tests.

## Hold ticks

Importer converts beat positions into explicit `ticks_ms` in the runtime chart.

This keeps runtime scoring independent from tempo-map interpretation.

Generated Hold ticks MUST satisfy `time_ms < tick_ms < end_ms`. The initial Hold
judgment and exact Hold end are not sustain ticks.

## Difficulty

MVP ships `easy` and `normal`.

Each difficulty may have its own MIDI source and generated JSON.

Future tooling may derive easier charts from a denser chart, but automatic difficulty generation is out of MVP.

## Automatic audio analysis

Direct `audio → playable chart` generation is a future tool.

It must not block the MVP or be mixed into the deterministic MIDI converter.

## Contributor workflow

1. Add/confirm song metadata and audio.
2. Record or edit MIDI chart.
3. Run importer.
4. Validate generated JSON.
5. Playtest.
6. Commit source MIDI plus runtime JSON when MIDI source exists.

The importer is a Python CLI. Its MIDI parsing dependency and invocation are
defined when M5 is implemented. It MUST produce identical JSON for identical
MIDI, configuration, and metadata inputs.
