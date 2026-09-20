# Save Data Specification

Status: **Draft baseline**

## Persistence model

MVP uses local Godot `user://` persistence. On Web this is browser-local storage/IndexedDB behavior.

No account sync or itch.io cloud save is required.

## Persisted data

At minimum:

- master volume;
- personal high score per `song_id + difficulty`;

Character/table selection is runtime `GameState` only in the MVP and is not
persisted. Accuracy, max combo, rank, and judgment counts are session-result
data only. Adding either later requires an explicit save-schema migration.

Save-v1 stores only:

```json
{
  "format": "baile-dos-crias-save",
  "version": 1,
  "settings": { "master_volume": 1.0 },
  "scores": {
    "song-id": { "easy": 0, "normal": 0 }
  }
}
```

`master_volume` is within `0.0..1.0`; score values are non-negative integers.

## High score

High score is scoped to:

`(song_id, difficulty)`

Song selection displays the saved personal score for the currently selected difficulty.

Never played: display `0`.

## Portable backup

Provide:

- **Export Data**
- **Import Data**

Export produces a versioned JSON file, e.g.:

`baile-dos-crias-save-v1.json`

Conceptual shape:

```json
{
  "format": "baile-dos-crias-save",
  "version": 1,
  "exported_at": "ISO-8601 timestamp",
  "settings": {},
  "selection": {},
  "scores": {}
}
```

`exported_at` is export metadata only and is not required in the local save
file. Export uses UTC and the filename `baile-dos-crias-save-v1.json`.

Web export may use a small JavaScript bridge adapter to trigger browser download/file selection.

The Start screen exposes these actions through a subordinate `Data` control.
Its centered placeholder modal offers `Export Data`, `Import Data`, and `Close`.
After file selection, only a valid candidate advances to a separate
`Replace` / `Cancel` confirmation state.

## Import rules

Before replacing local data:

1. Parse as JSON.
2. Validate `format` and `version`.
3. Validate structure/types/ranges.
4. Reject malformed/unsupported data.
5. Ask for explicit replacement confirmation.
6. Replace local save only after confirmation.
7. Persist the imported result.

Import is **replace**, not merge, in the MVP.

The save service validates into a pending candidate first. Only a later explicit
confirmation may persist and replace the active save; cancelling or rejecting a
candidate leaves active data unchanged.

## Load failures

- Missing save: use in-memory defaults until a user-driven change is saved.
- Malformed or structurally invalid save: rename it to a unique timestamped
  `.invalid` backup, report an actionable diagnostic, and use in-memory
  defaults. Do not immediately write defaults.
- Well-formed save with an unsupported version: preserve it unchanged, report
  the unsupported version, and use in-memory defaults. Do not immediately write
  defaults.

A user-driven setting/high-score change, confirmed import, or future explicit
reset may persist a new save after a load failure.

## Trust model

The player may edit their own exported JSON. MVP does not attempt anti-cheat protection.

If online competitive leaderboards are added later, imported/local data must never be trusted as server-authoritative score evidence.

## Versioning

Save migrations must be explicit.

Never silently interpret an unknown future save version as the current schema.
