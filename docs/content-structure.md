# Content Structure

Status: **Draft baseline**

## Goals

- Keep each song self-contained.
- Make GitHub contributions easy to review.
- Keep authoring sources separate from runtime data.
- Avoid root-level asset clutter.
- Load valid contributed content independently: invalid metadata produces an
  actionable diagnostic and is excluded without blocking unrelated valid items.

## Songs

Recommended structure:

```text
content/songs/
  song-id/
    metadata.json
    audio.ogg
    preview.ogg              # optional dedicated 15-second preview asset
    source/
      easy.mid
      normal.mid
    charts/
      easy.json
      normal.json
```

If the shipped Web build uses another supported audio format, filenames may differ; folder responsibilities must remain the same.

## Song metadata

Minimum conceptual fields:

```json
{
  "id": "song-id",
  "title": "Song Title",
  "artist": "Artist",
  "duration_ms": 60000,
  "bpm_display": "150",
  "audio": "audio.ogg",
  "preview_start_ms": 0,
  "difficulties": ["easy", "normal"]
}
```

`bpm_display` is UI metadata only; runtime charts do not depend on it.

`preview_start_ms` is optional and defaults to `0`. Song Select loops 15 seconds
from that timestamp with 250 ms fades. Optional future fields may include
attribution, license, cover art, and tempo description.

## Characters

```text
content/characters/
  character-id/
    metadata.json
    assets/
```

Character choice is cosmetic in the MVP.

Character metadata requires a stable `id` and non-empty `name`. Presentation
asset paths are optional metadata in M1.

## DJ tables

```text
content/tables/
  table-id/
    metadata.json
    assets/
```

Table choice is cosmetic in the MVP.

Table metadata requires a stable `id` and non-empty `name`. Presentation asset
paths are optional metadata in M1.

## Current source material

Confirmed Start track:

`BASE DE FUNK 150 BPM  INSTRUMENTAL  USO LIVRE 03 Prod DIL34N.mp3`

Current gameplay reference:

`DJ André Marques Hero - O jogo (128 kbps).mp3`

The gameplay reference is not automatically approved for public redistribution. Distribution rights must be confirmed before shipping.

## IDs

Use stable lowercase kebab-case IDs independent from displayed titles.

Never use display text as a save-data or chart foreign key.
