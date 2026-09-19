# Product Specification

Status: **Draft baseline**

## Product

**Baile dos Crias** is a Brazilian funk rhythm game inspired by arcade rhythm games and pad-based music hardware. The player acts as a DJ and hits notes on a 3×3 grid styled after MPC sample pads.

Primary target: **Web on itch.io**, portrait-first and mobile-friendly.

The project is intended to accept GitHub contributions for code, features, songs, charts, and characters.

## MVP

The MVP MUST include:

- Start screen.
- Character + DJ table selection.
- Song + difficulty selection.
- Gameplay.
- Pause flow.
- Result screen for success or failure.
- One character.
- One DJ table.
- One playable song.
- Two difficulties: `easy`, `normal`.
- Tap and Hold notes.
- Keyboard, numpad, mouse, touch, and multitouch input.
- Local save plus manual backup export/import.

The data model MUST already support multiple characters, tables, songs, and difficulties.

## Main flow

`Start ↔ Character/Table Select ↔ Song/Difficulty Select → Gameplay → Results`

From Results:

- Retry → Gameplay.
- Exit → Song/Difficulty Select.

From Pause:

- Continue → `3, 2, 1, VAI!` → resume.
- Retry → restart song → countdown.
- Exit → discard current run → Song/Difficulty Select.

## Start screen

Must contain:

- Current **Baile dos Crias** logo.
- `VAI` start button with subtle vertical floating animation.
- Two speakers.
- Woofer pulse on beat.
- Expanding/fading soundwave on beat.

Start actions:

- Mouse/touch: visual pressed feedback; activate only on release.
- Keyboard: `Space` or `Enter`.

Confirmed start-screen track:

`BASE DE FUNK 150 BPM  INSTRUMENTAL  USO LIVRE 03 Prod DIL34N.mp3`

## Character + table selection

Must provide:

- Back and Next navigation.
- Selected character + table preview in the same composition used during gameplay.
- Character carousel/track: thumbnail + name.
- Table carousel/track: thumbnail + name.
- Up/Down selects which track has keyboard focus.
- Left/Right changes the focused selection.
- Pointer/touch arrows change selection.
- Horizontal swipe over a track may change selection.

Only one character and one table ship in the MVP, but selection logic must not be hard-coded to one item.

## Song + difficulty selection

Must provide:

- Vertical song-card queue.
- Focused card at full opacity; other cards reduced.
- Focused song plays a preview.
- Card: title + artist.
- Long title scrolls horizontally; short title remains static.
- Information: available difficulties, duration, BPM display, personal high score.
- Back always enabled.
- Next enabled only after choosing a difficulty.

`High Score` means the player's best score for the selected **song + difficulty**. Never played: `0`.

The preview start timestamp comes from song metadata and defaults to `0`. The
focused song loops a 15-second preview with 250 ms fade-in and fade-out.

## Gameplay

Sequence:

1. Load selected chart/content.
2. Show `3, 2, 1, VAI!`.
3. Start song.
4. Play until song end or 50 consecutive MISS judgments.
5. Show Results.

Pause button remains at the top-right.

Losing browser/app focus MUST auto-pause gameplay.

## Results

Must show:

- Character in the established composition.
- Counts for `PERFECT`, `GREAT`, `GOOD`, `BAD`, `MISS`.
- Rank `S/A/B/C/D/F`.
- Maximum positive combo.
- Final score.
- New-record feedback when applicable.
- Retry and Exit navigation.

New-record feedback uses `NEW RECORD` text with a short pulse animation for the
MVP baseline.

## Out of MVP

- Online accounts/cloud saves.
- Online leaderboards.
- Server-authoritative scores.
- Automatic chart generation directly from audio.
- Automatic multi-difficulty chart generation.
- More than one shipped character/table/song.
