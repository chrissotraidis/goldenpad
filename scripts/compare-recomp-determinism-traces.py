#!/usr/bin/env python3
"""Compare two privacy-safe GoldenPad four-player determinism traces."""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import sys
from typing import Iterable


MAGIC = "GOLDENPAD_DETERMINISM_TRACE_V14"
REQUIRED_LOGICAL_FRAMES = {
    1, 120, 363, 603, 843, 963, 1083, 1323, 1443, 1563, 1683, 1743, 1770
}
Input = tuple[int, int, int]


@dataclasses.dataclass(frozen=True)
class Sample:
    poll: int
    match_frame: int
    vi: int
    clock_reads: int
    stable: bool
    memory_stable: bool
    inputs: tuple[Input, ...]
    players: int
    canonical_valid: bool
    active_match: bool
    menu: int
    stage: int
    pending: int
    canonical: str
    canonical_globals: str
    canonical_players: str
    canonical_props: str
    state_hash: str
    regions: tuple[str, ...]
    pages: tuple[str, ...]
    hotblocks: tuple[str, ...]


@dataclasses.dataclass(frozen=True)
class Trace:
    path: pathlib.Path
    header: str
    samples: tuple[Sample, ...]
    complete_poll: int | None


class TraceError(ValueError):
    pass


def _fields(line: str) -> dict[str, str]:
    return dict(token.split("=", 1) for token in line.split() if "=" in token)


def _inputs(value: str) -> tuple[Input, ...]:
    parsed = []
    for port in value.split(";"):
        buttons, stick_x, stick_y = port.split(",")
        parsed.append((int(buttons, 16), int(stick_x), int(stick_y)))
    return tuple(parsed)


def _sample(values: dict[str, str]) -> Sample:
    return Sample(
        poll=int(values["poll"]),
        match_frame=int(values.get("match_frame", "0")),
        vi=int(values["vi"]),
        clock_reads=int(values.get("clock_reads", "0")),
        stable=values["stable"] == "1",
        memory_stable=values.get("memory_stable", "0") == "1",
        inputs=_inputs(values["inputs"]),
        players=int(values["players"]),
        canonical_valid=values["canonical_valid"] == "1",
        active_match=values["active_match"] == "1",
        menu=int(values["menu"]),
        stage=int(values["stage"]),
        pending=int(values["pending"]),
        canonical=values["canonical"],
        canonical_globals=values["canonical_globals"],
        canonical_players=values["canonical_players"],
        canonical_props=values["canonical_props"],
        state_hash=values["hash"],
        regions=tuple(values["regions"].split(",")),
        pages=tuple(values.get("pages", "").split(",")),
        hotblocks=tuple(values.get("hotblocks", "").split(",")),
    )


def parse_trace(path: pathlib.Path) -> Trace:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as error:
        raise TraceError(f"cannot read {path}: {error}") from error
    if not lines or not lines[0].startswith(MAGIC + " "):
        raise TraceError(f"{path}: missing {MAGIC} header")

    samples: list[Sample] = []
    complete_poll: int | None = None
    seen_polls: set[int] = set()
    for line_number, line in enumerate(lines[1:], start=2):
        try:
            if line.startswith("COMPLETE "):
                complete_poll = int(_fields(line)["poll"])
                continue
            if not line.startswith("SAMPLE "):
                continue
            sample = _sample(_fields(line))
        except (KeyError, ValueError, IndexError) as error:
            raise TraceError(f"{path}:{line_number}: malformed record") from error
        if sample.poll in seen_polls:
            raise TraceError(f"{path}:{line_number}: duplicate poll {sample.poll}")
        if len(sample.inputs) != 4:
            raise TraceError(f"{path}:{line_number}: expected four controller inputs")
        if len(sample.regions) != 8:
            raise TraceError(f"{path}:{line_number}: expected eight region hashes")
        if sample.pages != ("",) and len(sample.pages) != 128:
            raise TraceError(f"{path}:{line_number}: expected 128 page hashes")
        if sample.hotblocks != ("",) and len(sample.hotblocks) != 64:
            raise TraceError(f"{path}:{line_number}: expected 64 hot-block hashes")
        seen_polls.add(sample.poll)
        samples.append(sample)
    if not samples:
        raise TraceError(f"{path}: trace has no samples")
    return Trace(path, lines[0], tuple(samples), complete_poll)


def _component_differences(left: Sample, right: Sample) -> list[str]:
    names = ("globals", "players", "props")
    left_hashes = (
        left.canonical_globals, left.canonical_players, left.canonical_props
    )
    right_hashes = (
        right.canonical_globals, right.canonical_players, right.canonical_props
    )
    return [name for name, a, b in zip(names, left_hashes, right_hashes) if a != b]


def compare(left: Trace, right: Trace) -> tuple[int, list[str]]:
    if left.header != right.header:
        return 2, ["ERROR: trace headers differ; probe contracts are incompatible"]
    if left.complete_poll is None or right.complete_poll is None:
        return 2, ["INCONCLUSIVE: one or both traces lack a completion marker"]
    if left.complete_poll != right.complete_poll:
        return 2, ["INCONCLUSIVE: completion polls differ"]

    left_active = {sample.match_frame: sample for sample in left.samples if sample.active_match}
    right_active = {sample.match_frame: sample for sample in right.samples if sample.active_match}
    common_frames = sorted(left_active.keys() & right_active.keys())
    missing_required = sorted(REQUIRED_LOGICAL_FRAMES - set(common_frames))
    if missing_required:
        return 2, [
            "INCONCLUSIVE: shared logical-frame coverage misses required input edges",
            f"  missing logical frames: {missing_required}",
        ]

    active_compared = 0
    unstable = 0
    full_memory_noise = 0
    active_hashes: set[str] = set()
    max_players = 0
    for match_frame in common_frames:
        a = left_active[match_frame]
        b = right_active[match_frame]
        if a.inputs != b.inputs:
            return 2, [f"ERROR: four-port input stream differs at match frame {match_frame}"]
        max_players = max(max_players, a.players, b.players)
        if not a.canonical_valid or not b.canonical_valid:
            return 2, [f"INCONCLUSIVE: canonical state invalid at match frame {match_frame}"]
        if not a.stable or not b.stable:
            unstable += 1
            continue
        active_compared += 1
        active_hashes.add(a.canonical)
        if a.canonical != b.canonical:
            return 1, [
                f"DIVERGED: first canonical gameplay mismatch at match frame {match_frame}",
                f"  host polls: {a.poll} vs {b.poll}",
                f"  VI/clock reads: {a.vi}/{a.clock_reads} vs {b.vi}/{b.clock_reads}",
                f"  menu/stage/pending: {a.menu}/{a.stage}/{a.pending} vs "
                f"{b.menu}/{b.stage}/{b.pending}",
                f"  source-owned components: {_component_differences(a, b)}",
                f"  canonical hashes: {a.canonical} vs {b.canonical}",
            ]
        if a.state_hash != b.state_hash:
            full_memory_noise += 1

    if max_players != 4:
        return 2, [f"INCONCLUSIVE: stock match never exposed four players (max={max_players})"]
    if active_compared == 0:
        return 2, [
            "INCONCLUSIVE: no stable source-owned samples from an active match",
            f"  unstable active samples: {unstable}",
        ]
    if len(active_hashes) < 2:
        return 2, ["INCONCLUSIVE: canonical gameplay state never changed"]

    messages = [
        f"PASS: {active_compared} canonical four-player gameplay samples match "
        f"through logical frame {common_frames[-1]}",
        f"  both independent runs completed at host poll {left.complete_poll}",
        f"  controlled gameplay produced {len(active_hashes)} distinct canonical states",
        f"  full-RDRAM noise differed at {full_memory_noise} matching gameplay samples",
    ]
    if unstable:
        messages.append(f"WARNING: excluded {unstable} unstable canonical samples")
    return 0, messages


def _sample_line(poll: int, canonical: str, *, active: int = 1) -> str:
    regions = ",".join([canonical] * 8)
    return (
        f"SAMPLE poll={poll} match_frame={poll} vi={poll} stable=1 memory_stable=1 "
        "inputs=0000,0,0;0000,0,0;0000,0,0;0000,0,0 "
        f"players=4 canonical_valid=1 active_match={active} "
        f"menu=11 stage=22 pending=22 canonical={canonical} "
        f"canonical_globals={canonical} canonical_players={canonical} "
        f"canonical_props={canonical} hash={canonical} regions={regions}"
    )


def self_test() -> int:
    header = f"{MAGIC} script=stock-four-player-fixed-delay-v8 max_poll=16000"

    def make_trace(name: str, lines: Iterable[str]) -> Trace:
        samples = tuple(_sample(_fields(line)) for line in lines if line.startswith("SAMPLE"))
        return Trace(pathlib.Path(name), header, samples, 16000)

    matching_lines = [
        _sample_line(frame, "bb" if frame == 1770 else "aa")
        for frame in sorted(REQUIRED_LOGICAL_FRAMES)
    ]
    diverged_lines = [
        _sample_line(frame, "cc" if frame == 1770 else "aa")
        for frame in sorted(REQUIRED_LOGICAL_FRAMES)
    ]
    a = make_trace("a", matching_lines)
    b = make_trace("b", matching_lines)
    diverged = make_trace("c", diverged_lines)
    inactive = make_trace("d", [_sample_line(1, "aa", active=0)])
    if compare(a, b)[0] != 0:
        print("self-test failed: matching active traces", file=sys.stderr)
        return 1
    if compare(a, diverged)[0] != 1:
        print("self-test failed: canonical divergence", file=sys.stderr)
        return 1
    if compare(inactive, inactive)[0] != 2:
        print("self-test failed: inactive trace", file=sys.stderr)
        return 1
    print("GoldenPad four-player canonical comparator self-test: PASS")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("trace_a", nargs="?", type=pathlib.Path)
    parser.add_argument("trace_b", nargs="?", type=pathlib.Path)
    parser.add_argument("--self-test", action="store_true")
    arguments = parser.parse_args()
    if arguments.self_test:
        return self_test()
    if arguments.trace_a is None or arguments.trace_b is None:
        parser.error("TRACE_A and TRACE_B are required unless --self-test is used")
    try:
        status, messages = compare(
            parse_trace(arguments.trace_a), parse_trace(arguments.trace_b)
        )
    except TraceError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    for message in messages:
        print(message)
    return status


if __name__ == "__main__":
    raise SystemExit(main())
