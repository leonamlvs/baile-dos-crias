# Content Structure

Status: **Authoritative MVP baseline; explicit TBD items remain open**

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

`preview_start_ms` is optional and defaults to `0`. It must be a non-negative
integer before both the declared song duration and decoded audio end. Song
Select loops 15 seconds from that timestamp with 250 ms fades.

Runtime audio must load as an `AudioStream` with a finite positive duration.
Every chart note must start before both the declared and decoded audio endpoint;
a Hold may end exactly at that endpoint but not after it.

## Characters

```text
content/characters/
  character-id/
    metadata.json
    assets/
```

Character choice is cosmetic in the MVP.

Character metadata requires a stable `id` and non-empty `name`. An optional
`visual` path is relative to the character directory and replaces the geometric
fallback in the shared presentation slot.

## DJ tables

```text
content/tables/
  table-id/
    metadata.json
    assets/
```

Table choice is cosmetic in the MVP.

Table metadata requires a stable `id` and non-empty `name`. An optional `visual`
path is relative to the table directory and replaces the geometric fallback in
the shared presentation slot.

## Current source material

Locally referenced Start track:

`BASE DE FUNK 150 BPM  INSTRUMENTAL  USO LIVRE 03 Prod DIL34N.mp3`

Current gameplay reference:

`DJ André Marques Hero - O jogo (128 kbps).mp3`

Neither a descriptive filename nor local availability proves redistribution
rights. `content/release-content.json` is the release inventory for Start audio,
song audio, charts, and shipped visuals. Every shipped entry must have a path,
kind, attribution, license, evidence, a package-content marker, `cleared: true`, and
`include_in_release: true`. The project-code license decision is recorded
separately in the same inventory. The current undecided/pending values are
intentional release blockers and must only be changed from owner-supplied
evidence.

## IDs

Use stable lowercase kebab-case IDs independent from displayed titles.

Never use display text as a save-data or chart foreign key.
