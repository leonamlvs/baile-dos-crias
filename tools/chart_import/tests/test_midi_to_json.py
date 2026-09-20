from __future__ import annotations

import json
import struct
import tempfile
import unittest
from decimal import Decimal
from fractions import Fraction
from pathlib import Path

from tools.chart_import.midi_to_json import (
    ImportConfig,
    ImporterError,
    TempoEvent,
    TempoMap,
    chart_json,
    convert_midi,
    load_config,
    parse_midi_bytes,
    run,
    validate_chart,
)


def vlq(value: int) -> bytes:
    if value < 0:
        raise ValueError("VLQ value cannot be negative")
    result = [value & 0x7F]
    value >>= 7
    while value:
        result.append(0x80 | (value & 0x7F))
        value >>= 7
    return bytes(reversed(result))


def track(events: list[tuple[int, bytes]]) -> bytes:
    payload = bytearray()
    previous_tick = 0
    for absolute_tick, event in events:
        payload += vlq(absolute_tick - previous_tick)
        payload += event
        previous_tick = absolute_tick
    payload += b"\x00\xFF\x2F\x00"
    return b"MTrk" + struct.pack(">I", len(payload)) + payload


def midi_file(tracks: list[bytes], ticks_per_quarter: int = 480, midi_format: int | None = None) -> bytes:
    if midi_format is None:
        midi_format = 0 if len(tracks) == 1 else 1
    header = b"MThd" + struct.pack(">IHHH", 6, midi_format, len(tracks), ticks_per_quarter)
    return header + b"".join(tracks)


def note_on(pitch: int, velocity: int = 100, channel: int = 0) -> bytes:
    return bytes((0x90 | channel, pitch, velocity))


def note_off(pitch: int, channel: int = 0) -> bytes:
    return bytes((0x80 | channel, pitch, 0))


def tempo(microseconds_per_quarter: int) -> bytes:
    return b"\xFF\x51\x03" + microseconds_per_quarter.to_bytes(3, "big")


def config(unmapped: str = "ignore", threshold: Fraction = Fraction(1, 2), ticks: Fraction = Fraction(1)) -> ImportConfig:
    return ImportConfig({pitch: pitch - 35 for pitch in range(36, 45)}, threshold, ticks, unmapped)


class MidiImporterTests(unittest.TestCase):
    def test_tap_hold_threshold_and_strict_ticks(self) -> None:
        source = midi_file(
            [
                track(
                    [
                        (0, note_on(36)),
                        (239, note_off(36)),
                        (480, note_on(37)),
                        (720, note_off(37)),
                        (960, note_on(38)),
                        (1920, note_off(38)),
                    ]
                )
            ]
        )
        chart = convert_midi(parse_midi_bytes(source), config(), "test-song", "normal")
        self.assertEqual([note["type"] for note in chart["notes"]], ["tap", "hold", "hold"])
        self.assertEqual(chart["notes"][1]["ticks_ms"], [])
        self.assertEqual(chart["notes"][2]["time_ms"], 1000)
        self.assertEqual(chart["notes"][2]["end_ms"], 2000)
        self.assertEqual(chart["notes"][2]["ticks_ms"], [1500])

    def test_variable_tempo_map_changes_absolute_milliseconds(self) -> None:
        source = midi_file(
            [
                track([(0, tempo(500_000)), (480, tempo(1_000_000))]),
                track([(0, note_on(36)), (960, note_off(36))]),
            ]
        )
        chart = convert_midi(parse_midi_bytes(source), config(), "tempo-song", "easy")
        note = chart["notes"][0]
        self.assertEqual(note["end_ms"], 1500)
        self.assertEqual(note["ticks_ms"], [500])
        fixture_path = Path(__file__).parents[3] / "tests/fixtures/chart_import/expected-variable-tempo.json"
        self.assertEqual(chart, json.loads(fixture_path.read_text(encoding="utf-8")))

    def test_chords_retain_deterministic_track_order(self) -> None:
        source = midi_file(
            [
                track([(0, note_on(37)), (120, note_off(37))]),
                track([(0, note_on(36)), (120, note_off(36))]),
            ]
        )
        first = convert_midi(parse_midi_bytes(source), config(), "chord-song", "normal")
        second = convert_midi(parse_midi_bytes(source), config(), "chord-song", "normal")
        self.assertEqual(first, second)
        self.assertEqual([note["pad"] for note in first["notes"]], [2, 1])
        self.assertEqual([note["id"] for note in first["notes"]], ["n0001", "n0002"])

    def test_running_status_and_zero_velocity_note_off(self) -> None:
        # Second event omits 0x90 and uses velocity zero as note-off.
        source = midi_file([track([(0, note_on(36)), (120, bytes((36, 0)))])])
        chart = convert_midi(parse_midi_bytes(source), config(), "running-status", "easy")
        self.assertEqual(len(chart["notes"]), 1)
        self.assertEqual(chart["notes"][0]["type"], "tap")

    def test_unmapped_policy_is_explicit(self) -> None:
        source = midi_file([track([(0, note_on(60)), (120, note_off(60)), (240, note_on(36)), (360, note_off(36))])])
        ignored = convert_midi(parse_midi_bytes(source), config("ignore"), "mapped-song", "easy")
        self.assertEqual(len(ignored["notes"]), 1)
        with self.assertRaisesRegex(ImporterError, "unmapped note pitches: 60"):
            convert_midi(parse_midi_bytes(source), config("error"), "mapped-song", "easy")

    def test_pairing_errors_are_actionable(self) -> None:
        overlap = midi_file([track([(0, note_on(36)), (10, note_on(36)), (20, note_off(36)), (30, note_off(36))])])
        with self.assertRaisesRegex(ImporterError, "Overlapping note-on"):
            convert_midi(parse_midi_bytes(overlap), config(), "bad-song", "easy")
        dangling = midi_file([track([(0, note_on(36))])])
        with self.assertRaisesRegex(ImporterError, "without note-off"):
            convert_midi(parse_midi_bytes(dangling), config(), "bad-song", "easy")

    def test_rounding_is_integer_and_half_up(self) -> None:
        tempo_map = TempoMap(480, [TempoEvent(0, 0, 0, 500_000)])
        self.assertEqual(tempo_map.milliseconds_at(Fraction(12, 25)), 1)
        self.assertEqual(tempo_map.milliseconds_at(480), 500)

    def test_hold_tick_resolution_must_be_representable(self) -> None:
        source = midi_file([track([(0, note_on(36)), (480, note_off(36))])], ticks_per_quarter=100)
        with self.assertRaisesRegex(ImporterError, "whole MIDI tick"):
            convert_midi(parse_midi_bytes(source), config(ticks=Fraction(1, 3)), "test-song", "easy")

    def test_configuration_requires_a_nine_pad_bijection(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "config.json"
            path.write_text(json.dumps({"note_to_pad": {"36": 1}}), encoding="utf-8")
            with self.assertRaisesRegex(ImporterError, "exactly nine"):
                load_config(path)

    def test_cli_output_is_deterministic_and_valid(self) -> None:
        source = midi_file([track([(0, note_on(36)), (120, note_off(36))])])
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            midi_path = root / "source.mid"
            config_path = root / "config.json"
            output_a = root / "a.json"
            output_b = root / "b.json"
            midi_path.write_bytes(source)
            config_path.write_text(
                json.dumps(
                    {
                        "note_to_pad": {str(pitch): pitch - 35 for pitch in range(36, 45)},
                        "hold_threshold_beats": 0.5,
                        "hold_tick_beats": 1,
                    }
                ),
                encoding="utf-8",
            )
            common = [str(midi_path), "", "--config", str(config_path), "--song-id", "cli-song", "--difficulty", "normal"]
            args_a = list(common)
            args_a[1] = str(output_a)
            args_b = list(common)
            args_b[1] = str(output_b)
            self.assertEqual(run(args_a), 0)
            self.assertEqual(run(args_b), 0)
            self.assertEqual(output_a.read_bytes(), output_b.read_bytes())
            validate_chart(json.loads(output_a.read_text(encoding="utf-8")))

    def test_empty_or_malformed_midi_is_rejected(self) -> None:
        with self.assertRaisesRegex(ImporterError, "missing MThd"):
            parse_midi_bytes(b"not midi")
        empty = midi_file([track([])])
        with self.assertRaisesRegex(ImporterError, "at least one note"):
            convert_midi(parse_midi_bytes(empty), config(), "empty-song", "easy")

    def test_runtime_validator_rejects_tick_at_hold_end(self) -> None:
        chart = {
            "version": 1,
            "song_id": "test-song",
            "difficulty": "normal",
            "notes": [
                {
                    "id": "n0001",
                    "time_ms": 100,
                    "pad": 1,
                    "type": "hold",
                    "end_ms": 200,
                    "ticks_ms": [200],
                }
            ],
        }
        with self.assertRaisesRegex(ImporterError, "time_ms < tick_ms < end_ms"):
            validate_chart(chart)

    def test_json_serialization_has_stable_format(self) -> None:
        source = midi_file([track([(0, note_on(36)), (120, note_off(36))])])
        chart = convert_midi(parse_midi_bytes(source), config(), "json-song", "easy")
        rendered = chart_json(chart)
        self.assertTrue(rendered.endswith("\n"))
        self.assertEqual(rendered, chart_json(chart))


if __name__ == "__main__":
    unittest.main()
