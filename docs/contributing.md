# Contributing

Status: **Current contribution policy**

Baile dos Crias is intended to accept reviewed GitHub pull requests for code, songs, charts, and characters.

## General rules

- Read relevant specs before changing behavior.
- Do not silently redefine gameplay rules.
- If a change conflicts with a spec, update/approve the spec decision first.
- Keep PRs focused.
- Add or update tests for deterministic behavior.
- Validate Web compatibility.

## Code

- Godot 4.7.2.
- GDScript.
- Compatibility renderer.
- Prefer simple Godot-native solutions.
- Avoid new global managers/dependencies without clear need.

## Songs

A song contribution should keep its files inside one song folder and include:

- metadata;
- redistributable audio;
- difficulty charts;
- source MIDI when available;
- license/attribution information required for redistribution.

Do not submit audio without the right to redistribute it. Add every release file
to `content/release-content.json`; release validation rejects missing,
incomplete, uncleared, or non-included inventory entries.

The repository's project-code license and third-party/content licenses are
separate decisions. Do not infer either one from the other or from a filename.

## Charts

Preferred workflow:

`MIDI/MPC performance → importer → JSON → playtest`

Commit source MIDI when it is part of the authoring workflow.

Generated JSON must pass chart validation.

## Characters/tables

MVP treats these as cosmetic skins. New content must not add gameplay advantages unless a future spec explicitly changes that rule.

## Pull requests

PR description should state:

- what changed;
- which spec/issue it implements;
- how it was tested;
- any intentional spec change or remaining limitation.
