# UI/UX Specification

Status: **Draft baseline**

## Layout model

- Logical design size: **720×1280**.
- Portrait only.
- Scale uniformly.
- Never crop gameplay or required UI.
- Extra viewport area may be filled by extending the background.
- Landscape mobile view shows a rotate-device overlay instead of gameplay.
- Reference art defines style; wireframes define approximate placement/z-order; current specs define behavior.

## Shared interaction rules

- Every pointer/touch control needs a visible pressed state.
- Critical actions must not depend on hover.
- Touch targets must be usable on phones.
- Keyboard focus must remain visible on menu screens.
- UI should use placeholders at final intended proportions until production art is connected.

## Start

Visual stack from references:

- Background.
- Logo.
- Left/right speakers.
- Speaker soundwaves.
- `VAI` button.

Behavior:

- `VAI` floats gently vertically.
- Woofer pulse and soundwave are beat-driven.
- Mouse/touch starts on release, not initial press.
- `Space`/`Enter` starts immediately.

## Character + table select

Until dedicated pixel wireframes exist, this screen uses the vertical composition
below with proportional, responsive sizing inside the 720×1280 logical canvas.

Vertical composition:

1. Back / Next.
2. Character + table preview.
3. Character track.
4. Table track.

Keyboard:

- Up/Down: focus track.
- Left/Right: previous/next item.
- Navigation controls remain keyboard-accessible.

Touch/pointer:

- Track arrows.
- Horizontal swipe over the selected track.

## Song + difficulty select

This screen uses proportional, responsive sizing inside the 720×1280 logical
canvas rather than fixed geometry not established by a wireframe.

- Vertical card queue.
- Focused card: 100% opacity.
- Non-focused cards: reduced opacity.
- Focused card controls preview audio.
- Title scrolls only when it overflows.
- Show artist, duration, BPM display, difficulties, selected difficulty, and personal high score.
- Next is disabled until difficulty is selected.

## Gameplay

From top to bottom, preserve the reference composition:

- Score area at top-left.
- Pause at top-right.
- Character and DJ table in the center.
- Combo/fire feedback around the table/character overlap region.
- 3×3 grid in the lower area.

Gameplay z-order must keep notes legible above pads and avoid character/table art covering required note feedback.

Countdown is centered and temporarily takes priority over gameplay feedback.

## Pause

A centered modal over paused gameplay:

- Master volume.
- Continue.
- Retry.
- Exit.

Continue/Retry use `3, 2, 1, VAI!` before active gameplay resumes.

## Results

Preserve the reference composition:

- Retry top-left.
- Exit top-right.
- Character + table.
- Grade/statistics panel.
- Rank.
- Score panel.

The current spec uses five judgment categories even if older artwork shows four.

When a personal high score is exceeded, show a `NEW RECORD` text treatment with
a short pulse animation. No separate icon or bespoke animation is required for
the MVP baseline.

## Mobile behavior

- True multitouch.
- A touch remains bound to the pad where it began until that finger lifts.
- Dragging over another pad never transfers the press.
- Browser/app focus loss auto-pauses.
- Returning to the game requires explicit resume and countdown.

## Still TBD

- Exact production-art geometry for screens not covered by existing wireframes.
- Final visual styling for the centered Pause modal.
