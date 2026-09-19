# Codex Instructions

Status: **Persistent project instructions**

## Before changing code

1. Read `README.md`.
2. Read the specs relevant to the task.
3. Read related ADRs.
4. Check `docs/current-work.md`.

## Source of truth

Precedence:

1. Current specs.
2. Accepted ADRs.
3. Wireframes for layout/z-order.
4. Reference art for visual direction.
5. Original historical design document.

If sources conflict, follow the higher source and report the conflict.

Never restore the legacy name **Baile dos Amigos**.

## Do not invent

If a behavior is marked TBD and implementation requires a decision:

- stop at the smallest safe boundary;
- record the blocker in `docs/current-work.md`;
- ask for a product decision.

Do not silently choose product behavior.

## Technical baseline

- Godot 4.7.2 stable.
- GDScript only.
- Compatibility renderer.
- Web/itch.io primary.
- 720×1280 portrait logical layout.
- Song clock authoritative.
- Runtime charts are JSON with absolute millisecond timing.

## Implementation style

- Prefer the simplest maintainable Godot-native solution.
- Avoid speculative abstraction.
- Avoid singletons unless state truly crosses scenes.
- Keep gameplay rules testable outside visual animation where practical.
- Keep visual timing derived from gameplay/song state, never the reverse.
- Data-drive songs, characters, tables, and difficulties.

## Validation

After relevant changes:

- run project/headless validation;
- run applicable tests;
- report what was and was not validated;
- never claim Web/mobile behavior was tested if it was not.

## Documentation discipline

When an accepted behavioral/architectural decision changes:

- update the relevant spec;
- add/update an ADR when the reason matters long-term;
- keep `current-work.md` temporary and concise.

Do not turn temporary implementation notes into permanent product requirements.

## Local development environment

On the primary Windows development environment:

- `godot` is available directly from the terminal through `PATH`.
- Expected version: Godot `4.7.2.stable`.
- Verify with `godot --version` before relying on the CLI.
- Prefer `godot` directly instead of searching for or hard-coding an executable path.

Do not assume the same PATH configuration exists in CI or on contributor machines.
