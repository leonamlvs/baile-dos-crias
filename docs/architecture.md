# Architecture

Status: **Authoritative MVP baseline; explicit TBD items remain open**

## Principles

- Prefer simple Godot-native composition over framework-heavy architecture.
- Keep gameplay rules independent from visuals where practical.
- Cross-scene state may use AutoLoads; scene-local behavior stays scene-local.
- Data-driven content: do not hard-code the only MVP song/character/table.
- Specs are authoritative; do not invent behavior to fill a TBD.

## Proposed project shape

```text
project.godot
scenes/
  start/
  character_select/
  song_select/
  gameplay/
  results/
  shared/
scripts/
  gameplay/
  input/
  audio/
  save/
  data/
content/
  songs/
  characters/
  tables/
tools/
  chart_import/
tests/
```

## AutoLoads

Keep the global set small:

- `GameState` — runtime current character/table selection, then song,
  difficulty, and transition context as later screens require. Cosmetic selection
  is not persisted by save-v1.
- `AudioManager` — menu/preview/gameplay audio ownership and master volume.
- `SaveManager` — local save, high scores, settings, import/export.
- `ScreenRouter` — navigation and scene transitions only. It MUST NOT own product state,
  audio, save data, gameplay rules, or screen-local behavior.

Do not add more global managers without a demonstrated cross-scene need.

## Gameplay scene

Suggested responsibility split:

```text
Gameplay
├── CharacterView
├── TableView
├── HUD
├── Countdown
├── PauseOverlay
├── PadGrid
├── InputRouter
├── ChartPlayer
├── NoteController
└── ScoreTracker
```

Responsibilities:

- `InputRouter`: converts physical sources into nine logical pad states.
- `ChartPlayer`: exposes chart events against authoritative song time.
- `NoteController`: note lifecycle and visual state.
- `ScoreTracker`: judgments, score, accuracy, combo, miss streak, rank inputs.
- `HUD`: presentation only.
- `PauseOverlay`: pause commands/settings.
- `Gameplay`: coordinates session lifecycle, not every individual rule.

## Data boundaries

Runtime chart JSON is parsed/validated before gameplay begins.

`RuntimeChartParser` returns normalized chart dictionaries or actionable errors.
It validates schema version, content IDs, note ordering, field types, Tap/Hold
shape, unique note IDs, pad range, and strict Hold tick bounds before a
`ChartPlayer` accepts the chart.

Content metadata is loaded independently from audio and chart data.

Save data is versioned and independent from runtime scene files.

## Session lifecycle

A retry MUST start a clean gameplay session: no previous note state, score, combo, timers, or input-held state may leak into the new run.

Exiting gameplay discards unfinished run statistics.

## Web safety

Avoid dependencies unavailable in Godot Web export or Compatibility renderer.

Use browser-specific JavaScript only behind a small adapter, primarily for backup file import/export.
