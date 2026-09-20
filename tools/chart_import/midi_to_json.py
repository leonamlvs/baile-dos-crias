#!/usr/bin/env python3
"""Convert a Standard MIDI File into a Baile dos Crias chart-v1 JSON file.

The importer intentionally uses only Python's standard library. It reads an
existing MIDI file; live MIDI devices and capture are outside its scope.
"""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from dataclasses import dataclass
from decimal import Decimal
from fractions import Fraction
from pathlib import Path
from typing import Any, Iterable, Sequence


DEFAULT_TEMPO_US_PER_QUARTER = 500_000
STABLE_ID = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


class ImporterError(ValueError):
    """An actionable authoring or MIDI-format error."""


@dataclass(frozen=True)
class NoteEvent:
    tick: int
    track: int
    order: int
    channel: int
    pitch: int
    is_on: bool


@dataclass(frozen=True)
class TempoEvent:
    tick: int
    track: int
    order: int
    microseconds_per_quarter: int


@dataclass(frozen=True)
class MidiData:
    ticks_per_quarter: int
    note_events: tuple[NoteEvent, ...]
    tempo_events: tuple[TempoEvent, ...]


@dataclass(frozen=True)
class ImportConfig:
    note_to_pad: dict[int, int]
    hold_threshold_beats: Fraction
    hold_tick_beats: Fraction
    unmapped_notes: str


@dataclass(frozen=True)
class NoteSpan:
    start_tick: int
    end_tick: int
    track: int
    order: int
    pitch: int
    pad: int


class TempoMap:
    def __init__(self, ticks_per_quarter: int, events: Iterable[TempoEvent]) -> None:
        self.ticks_per_quarter = ticks_per_quarter
        self.events = tuple(sorted(events, key=lambda item: (item.tick, item.track, item.order)))

    def microseconds_at(self, tick: int | Fraction) -> Fraction:
        target = Fraction(tick)
        if target < 0:
            raise ImporterError("MIDI tick positions cannot be negative.")
        current_tick = Fraction(0)
        elapsed = Fraction(0)
        tempo = DEFAULT_TEMPO_US_PER_QUARTER
        for event in self.events:
            event_tick = Fraction(event.tick)
            if event_tick > target:
                break
            elapsed += (event_tick - current_tick) * tempo / self.ticks_per_quarter
            current_tick = event_tick
            tempo = event.microseconds_per_quarter
        elapsed += (target - current_tick) * tempo / self.ticks_per_quarter
        return elapsed

    def milliseconds_at(self, tick: int | Fraction) -> int:
        milliseconds = self.microseconds_at(tick) / 1000
        # All positions are non-negative. Round exact halves upward explicitly,
        # avoiding platform or Python-version-specific floating-point behavior.
        return (2 * milliseconds.numerator + milliseconds.denominator) // (2 * milliseconds.denominator)


def _read_vlq(data: bytes, offset: int, limit: int) -> tuple[int, int]:
    value = 0
    for _ in range(4):
        if offset >= limit:
            raise ImporterError("Unexpected end of MIDI variable-length value.")
        byte = data[offset]
        offset += 1
        value = (value << 7) | (byte & 0x7F)
        if byte < 0x80:
            return value, offset
    raise ImporterError("MIDI variable-length value exceeds four bytes.")


def parse_midi_bytes(data: bytes) -> MidiData:
    if len(data) < 14 or data[:4] != b"MThd":
        raise ImporterError("Input is not a Standard MIDI File (missing MThd header).")
    header_length = struct.unpack_from(">I", data, 4)[0]
    if header_length < 6 or 8 + header_length > len(data):
        raise ImporterError("MIDI header length is invalid.")
    midi_format, track_count, division = struct.unpack_from(">HHH", data, 8)
    if midi_format not in (0, 1):
        raise ImporterError("Only Standard MIDI File format 0 or 1 is supported.")
    if track_count == 0 or (midi_format == 0 and track_count != 1):
        raise ImporterError("MIDI track count is invalid for its format.")
    if division & 0x8000:
        raise ImporterError("SMPTE time division is unsupported; use ticks-per-quarter-note MIDI.")
    if division == 0:
        raise ImporterError("MIDI ticks per quarter note must be positive.")

    note_events: list[NoteEvent] = []
    tempo_events: list[TempoEvent] = []
    offset = 8 + header_length
    for track_index in range(track_count):
        if offset + 8 > len(data) or data[offset : offset + 4] != b"MTrk":
            raise ImporterError(f"Missing MTrk chunk for track {track_index}.")
        track_length = struct.unpack_from(">I", data, offset + 4)[0]
        track_start = offset + 8
        track_end = track_start + track_length
        if track_end > len(data):
            raise ImporterError(f"Track {track_index} extends beyond the MIDI file.")
        _parse_track(data, track_start, track_end, track_index, note_events, tempo_events)
        offset = track_end
    if offset != len(data):
        raise ImporterError("Unexpected data follows the declared MIDI tracks.")
    return MidiData(division, tuple(note_events), tuple(tempo_events))


def _parse_track(
    data: bytes,
    offset: int,
    limit: int,
    track_index: int,
    note_events: list[NoteEvent],
    tempo_events: list[TempoEvent],
) -> None:
    absolute_tick = 0
    running_status: int | None = None
    order = 0
    while offset < limit:
        delta, offset = _read_vlq(data, offset, limit)
        absolute_tick += delta
        if offset >= limit:
            raise ImporterError(f"Track {track_index} ends before an event status byte.")
        next_byte = data[offset]
        if next_byte & 0x80:
            status = next_byte
            offset += 1
            if status < 0xF0:
                running_status = status
        else:
            if running_status is None:
                raise ImporterError(f"Track {track_index} uses running status before a channel status.")
            status = running_status

        if status == 0xFF:
            running_status = None
            if offset >= limit:
                raise ImporterError(f"Track {track_index} has a truncated meta event.")
            meta_type = data[offset]
            offset += 1
            length, offset = _read_vlq(data, offset, limit)
            end = offset + length
            if end > limit:
                raise ImporterError(f"Track {track_index} has a truncated meta-event payload.")
            payload = data[offset:end]
            offset = end
            if meta_type == 0x51:
                if length != 3:
                    raise ImporterError("Set Tempo meta events must contain exactly three bytes.")
                tempo = int.from_bytes(payload, "big")
                if tempo <= 0:
                    raise ImporterError("MIDI tempo must be positive.")
                tempo_events.append(TempoEvent(absolute_tick, track_index, order, tempo))
            order += 1
            if meta_type == 0x2F:
                if offset != limit:
                    raise ImporterError(f"Track {track_index} contains data after End of Track.")
                return
            continue

        if status in (0xF0, 0xF7):
            running_status = None
            length, offset = _read_vlq(data, offset, limit)
            offset += length
            if offset > limit:
                raise ImporterError(f"Track {track_index} has a truncated SysEx event.")
            order += 1
            continue
        if status >= 0xF0:
            raise ImporterError(f"Unsupported MIDI system status 0x{status:02X} in track {track_index}.")

        message = status & 0xF0
        channel = status & 0x0F
        data_length = 1 if message in (0xC0, 0xD0) else 2
        if offset + data_length > limit:
            raise ImporterError(f"Track {track_index} has a truncated channel event.")
        first = data[offset]
        second = data[offset + 1] if data_length == 2 else 0
        if first & 0x80 or second & 0x80:
            raise ImporterError(f"Track {track_index} channel-event data bytes must be below 128.")
        offset += data_length
        if message == 0x90:
            note_events.append(NoteEvent(absolute_tick, track_index, order, channel, first, second > 0))
        elif message == 0x80:
            note_events.append(NoteEvent(absolute_tick, track_index, order, channel, first, False))
        order += 1

    raise ImporterError(f"Track {track_index} is missing an End of Track meta event.")


def load_config(path: Path) -> ImportConfig:
    try:
        with path.open("r", encoding="utf-8") as handle:
            source = json.load(handle, parse_float=Decimal)
    except json.JSONDecodeError as error:
        raise ImporterError(f"Configuration JSON is malformed: {error.msg}.") from error
    except OSError as error:
        raise ImporterError(f"Could not read configuration: {error}.") from error
    if not isinstance(source, dict):
        raise ImporterError("Configuration root must be an object.")
    raw_mapping = source.get("note_to_pad")
    if not isinstance(raw_mapping, dict):
        raise ImporterError("Configuration requires a note_to_pad object.")
    note_to_pad: dict[int, int] = {}
    for raw_pitch, raw_pad in raw_mapping.items():
        try:
            pitch = int(raw_pitch)
        except (TypeError, ValueError) as error:
            raise ImporterError(f"MIDI pitch '{raw_pitch}' is not an integer.") from error
        if str(pitch) != str(raw_pitch) or not _is_int(raw_pad):
            raise ImporterError("note_to_pad keys and values must be integers.")
        pad = int(raw_pad)
        if pitch < 0 or pitch > 127 or pad < 1 or pad > 9:
            raise ImporterError("MIDI pitches must be 0..127 and logical pads must be 1..9.")
        note_to_pad[pitch] = pad
    if len(note_to_pad) != 9 or set(note_to_pad.values()) != set(range(1, 10)):
        raise ImporterError("note_to_pad must map exactly nine distinct pitches bijectively to pads 1..9.")

    threshold = _positive_fraction(source.get("hold_threshold_beats", Decimal("0.5")), "hold_threshold_beats")
    tick_interval = _positive_fraction(source.get("hold_tick_beats", Decimal("1")), "hold_tick_beats")
    unmapped = source.get("unmapped_notes", "ignore")
    if unmapped not in ("ignore", "error"):
        raise ImporterError("unmapped_notes must be either 'ignore' or 'error'.")
    return ImportConfig(note_to_pad, threshold, tick_interval, str(unmapped))


def _positive_fraction(value: Any, field: str) -> Fraction:
    if isinstance(value, bool) or not isinstance(value, (int, Decimal)):
        raise ImporterError(f"{field} must be a positive number.")
    fraction = Fraction(value)
    if fraction <= 0:
        raise ImporterError(f"{field} must be greater than zero.")
    return fraction


def _pair_notes(midi: MidiData, config: ImportConfig) -> list[NoteSpan]:
    mapped_events = [event for event in midi.note_events if event.pitch in config.note_to_pad]
    if config.unmapped_notes == "error":
        unmapped = sorted({event.pitch for event in midi.note_events if event.pitch not in config.note_to_pad})
        if unmapped:
            raise ImporterError(f"MIDI contains unmapped note pitches: {', '.join(map(str, unmapped))}.")
    active: dict[tuple[int, int, int], NoteEvent] = {}
    spans: list[NoteSpan] = []
    for event in sorted(mapped_events, key=lambda item: (item.tick, item.track, item.order)):
        key = (event.track, event.channel, event.pitch)
        if event.is_on:
            if key in active:
                raise ImporterError(
                    f"Overlapping note-on events for pitch {event.pitch}, channel {event.channel}, track {event.track}."
                )
            active[key] = event
            continue
        start = active.pop(key, None)
        if start is None:
            raise ImporterError(
                f"Note-off without note-on for pitch {event.pitch}, channel {event.channel}, track {event.track}."
            )
        if event.tick <= start.tick:
            raise ImporterError(f"Mapped MIDI note {event.pitch} must have positive duration.")
        spans.append(
            NoteSpan(start.tick, event.tick, start.track, start.order, start.pitch, config.note_to_pad[start.pitch])
        )
    if active:
        event = min(active.values(), key=lambda item: (item.track, item.order))
        raise ImporterError(
            f"Note-on without note-off for pitch {event.pitch}, channel {event.channel}, track {event.track}."
        )
    return sorted(spans, key=lambda item: (item.start_tick, item.track, item.order, item.pad))


def convert_midi(midi: MidiData, config: ImportConfig, song_id: str, difficulty: str) -> dict[str, Any]:
    if not STABLE_ID.fullmatch(song_id):
        raise ImporterError("song_id must be a stable lowercase kebab-case ID.")
    if not STABLE_ID.fullmatch(difficulty):
        raise ImporterError("difficulty must be a stable lowercase kebab-case ID.")
    interval_ticks = config.hold_tick_beats * midi.ticks_per_quarter
    if interval_ticks.denominator != 1:
        raise ImporterError("hold_tick_beats must resolve to a whole MIDI tick at this file's resolution.")
    threshold_ticks = config.hold_threshold_beats * midi.ticks_per_quarter
    tempo_map = TempoMap(midi.ticks_per_quarter, midi.tempo_events)
    notes: list[dict[str, Any]] = []
    for index, span in enumerate(_pair_notes(midi, config), start=1):
        start_ms = tempo_map.milliseconds_at(span.start_tick)
        end_ms = tempo_map.milliseconds_at(span.end_tick)
        note: dict[str, Any] = {
            "id": f"n{index:04d}",
            "time_ms": start_ms,
            "pad": span.pad,
            "type": "tap",
        }
        if span.end_tick - span.start_tick >= threshold_ticks:
            if end_ms <= start_ms:
                raise ImporterError(f"Hold n{index:04d} rounds to a non-positive millisecond duration.")
            note["type"] = "hold"
            note["end_ms"] = end_ms
            tick_values: list[int] = []
            tick_position = Fraction(span.start_tick) + interval_ticks
            while tick_position < span.end_tick:
                tick_ms = tempo_map.milliseconds_at(tick_position)
                if start_ms < tick_ms < end_ms and (not tick_values or tick_ms > tick_values[-1]):
                    tick_values.append(tick_ms)
                tick_position += interval_ticks
            note["ticks_ms"] = tick_values
        notes.append(note)
    chart = {"version": 1, "song_id": song_id, "difficulty": difficulty, "notes": notes}
    validate_chart(chart)
    return chart


def validate_chart(chart: Any) -> None:
    if not isinstance(chart, dict):
        raise ImporterError("Chart root must be an object.")
    if chart.get("version") != 1 or isinstance(chart.get("version"), bool):
        raise ImporterError("Chart version must be integer 1.")
    if not isinstance(chart.get("song_id"), str) or not STABLE_ID.fullmatch(chart["song_id"]):
        raise ImporterError("Chart song_id is invalid.")
    if not isinstance(chart.get("difficulty"), str) or not STABLE_ID.fullmatch(chart["difficulty"]):
        raise ImporterError("Chart difficulty is invalid.")
    notes = chart.get("notes")
    if not isinstance(notes, list) or not notes:
        raise ImporterError("Runtime charts must contain at least one note.")
    ids: set[str] = set()
    previous_time = -1
    for index, note in enumerate(notes):
        if not isinstance(note, dict):
            raise ImporterError(f"notes[{index}] must be an object.")
        note_id = note.get("id")
        if not isinstance(note_id, str) or not note_id or note_id in ids:
            raise ImporterError(f"notes[{index}].id must be non-empty and unique.")
        ids.add(note_id)
        time_ms = note.get("time_ms")
        pad = note.get("pad")
        if not _is_int(time_ms) or time_ms < 0 or time_ms < previous_time:
            raise ImporterError("Note times must be non-negative integers in non-decreasing order.")
        previous_time = time_ms
        if not _is_int(pad) or pad < 1 or pad > 9:
            raise ImporterError(f"notes[{index}].pad must be an integer from 1 through 9.")
        note_type = note.get("type")
        if note_type == "tap":
            if "end_ms" in note or "ticks_ms" in note:
                raise ImporterError("Tap notes must not contain Hold-only fields.")
        elif note_type == "hold":
            end_ms = note.get("end_ms")
            ticks = note.get("ticks_ms")
            if not _is_int(end_ms) or end_ms <= time_ms or not isinstance(ticks, list):
                raise ImporterError("Hold end_ms/ticks_ms fields are invalid.")
            previous_tick = time_ms
            for tick_ms in ticks:
                if not _is_int(tick_ms) or tick_ms <= previous_tick or tick_ms >= end_ms:
                    raise ImporterError("Hold ticks must satisfy time_ms < tick_ms < end_ms and increase strictly.")
                previous_tick = tick_ms
        else:
            raise ImporterError(f"notes[{index}].type must be 'tap' or 'hold'.")


def chart_json(chart: dict[str, Any]) -> str:
    validate_chart(chart)
    return json.dumps(chart, ensure_ascii=False, indent=2, separators=(",", ": ")) + "\n"


def _is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_midi", type=Path, help="Existing Standard MIDI File (.mid).")
    parser.add_argument("output_json", type=Path, help="Destination chart JSON, or '-' for stdout.")
    parser.add_argument("--config", required=True, type=Path, help="Importer configuration JSON.")
    parser.add_argument("--song-id", required=True, help="Stable song metadata ID.")
    parser.add_argument("--difficulty", required=True, help="Stable difficulty ID.")
    return parser


def run(argv: Sequence[str] | None = None) -> int:
    parser = build_argument_parser()
    args = parser.parse_args(argv)
    try:
        config = load_config(args.config)
        try:
            midi_bytes = args.input_midi.read_bytes()
        except OSError as error:
            raise ImporterError(f"Could not read MIDI input: {error}.") from error
        chart = convert_midi(parse_midi_bytes(midi_bytes), config, args.song_id, args.difficulty)
        rendered = chart_json(chart)
        if str(args.output_json) == "-":
            sys.stdout.write(rendered)
        else:
            args.output_json.parent.mkdir(parents=True, exist_ok=True)
            args.output_json.write_text(rendered, encoding="utf-8", newline="\n")
    except (ImporterError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    return 0


def main() -> None:
    raise SystemExit(run())


if __name__ == "__main__":
    main()
