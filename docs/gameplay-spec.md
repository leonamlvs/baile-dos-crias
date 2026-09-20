# Gameplay Specification

Status: **Authoritative MVP baseline; explicit TBD items remain open**

## Grid

Nine logical pads:

```text
7 8 9
4 5 6
1 2 3
```

Multiple lanes may be active simultaneously. A Hold may overlap Tap notes on other lanes.

## Authoritative timing

All note state and judgment MUST use the authoritative song clock, never accumulated frame delta.

Visual size is representation only; it MUST NOT determine score.

For a note:

`delta_ms = input_time_ms - hit_time_ms`

Judgment windows are symmetric for early and late input.

| Judgment | `abs(delta_ms)` | Base points |
|---|---:|---:|
| PERFECT | ≤ 50 ms | 100 |
| GREAT | ≤ 100 ms | 75 |
| GOOD | ≤ 150 ms | 50 |
| BAD | ≤ 220 ms | 10 |
| MISS | > 220 ms / no valid input | 0 |

## Tap

- Spawns visually at the absolute center of its pad.
- Expands proportionally.
- Reaches the intended full pad size exactly at `hit_time_ms`.
- Requires a new logical `pressed` transition.
- A pad already held cannot hit a Tap until it is released and pressed again.
- Visual: transparent fill, white stroke, matching pad shape.

## Hold

- Appears from the pad center like a Tap.
- When it reaches target size, its internal progress bar rises bottom-to-top until the Hold ends.
- Fill opacity increases during the Hold but remains translucent enough to see later notes.
- No stroke.

Initial state:

- A normal press within the judgment window receives BAD–PERFECT using the same timing table.
- If the logical pad is already held when the Hold reaches its hit time, the initial Hold judgment is PERFECT.
- Pre-holding is intentionally allowed.

During Hold:

- Each chart-defined beat/tick while held = PERFECT.
- Each chart-defined beat/tick while not held = MISS.
- The player may release and resume during the same Hold.
- Hold ticks count as normal judgments for score, accuracy, combo, result statistics, and miss streak.

## Combo and multiplier

Only `GOOD`, `GREAT`, and `PERFECT` build positive combo.

`BAD` or `MISS` immediately breaks positive combo.

Hold PERFECT ticks build combo.

| Positive combo | Multiplier |
|---:|---:|
| 0–9 | ×1 |
| 10–19 | ×2 |
| 20–29 | ×4 |
| 30–39 | ×6 |
| 40+ | ×8 |

The judgment that reaches a threshold uses the new multiplier; e.g. combo 10 scores at ×2.

Score per judgment:

`base_points × current_multiplier`

Multiplier never exceeds ×8.

At ×8, show the fire animation behind the combo counter. Combo, multiplier, and fire disappear when the positive combo breaks.

## Consecutive MISS streak

- `MISS` increments `miss_streak`.
- Any non-MISS judgment resets `miss_streak` to `0`.
- Display the active MISS streak positively as `1` through `50`.
- At `50`, end the run as failure.
- The MISS streak never creates a score multiplier.

## Accuracy

Accuracy is independent of combo multiplier:

`accuracy = earned_base_points / (100 × judgment_count) × 100`

Hold ticks are included in `judgment_count`.

## Rank

| Rank | Rule |
|---|---|
| S | Accuracy ≥ 95% and every judgment is PERFECT or GREAT |
| A | Accuracy ≥ 90% |
| B | Accuracy ≥ 80% |
| C | Accuracy ≥ 70% |
| D | Accuracy ≥ 60% |
| F | Accuracy < 60% |

S therefore requires a very high PERFECT share and no GOOD/BAD/MISS judgments.

## Completion

Success: reach the end of the song without reaching 50 consecutive MISS judgments.

Failure: reach 50 consecutive MISS judgments.

Both outcomes lead to Results.
