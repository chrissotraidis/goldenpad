#!/usr/bin/env python3
"""Compare two GoldenPad offline determinism traces.

The trace contains no ROM bytes or raw game memory. It contains controller
inputs, counters, menu/stage metadata, and XXH3 hashes only.
"""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import sys
from typing import Iterable


MAGIC = "GOLDENPAD_DETERMINISM_TRACE_V1"


@dataclasses.dataclass(frozen=True)
class Sample:
    poll: int
    vi: int
    clock_reads: int
    stable: bool
    buttons: int
    stick_x: int
    stick_y: int
    menu: int
    stage: int
    pending: int
    state_hash: str
    regions: tuple[str, ...]
    pages: tuple[str, ...]
    hotblocks: tuple[str, ...]

    @property
    def input_identity(self) -> tuple[int, int, int]:
        return (self.buttons, self.stick_x, self.stick_y)


@dataclasses.dataclass(frozen=True)
class Trace:
    path: pathlib.Path
    header: str
    samples: tuple[Sample, ...]
    complete_poll: int | None


class TraceError(ValueError):
    pass


def _fields(line: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for token in line.split():
        if "=" not in token:
            continue
        key, value = token.split("=", 1)
        result[key] = value
    return result


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
        if line.startswith("COMPLETE "):
            values = _fields(line)
            try:
                complete_poll = int(values["poll"])
            except (KeyError, ValueError) as error:
                raise TraceError(f"{path}:{line_number}: invalid completion marker") from error
            continue
        if not line.startswith("SAMPLE "):
            continue
        values = _fields(line)
        try:
            poll = int(values["poll"])
            input_parts = values["input"].split(",")
            regions = tuple(values["regions"].split(","))
            pages = tuple(values.get("pages", "").split(","))
            hotblocks = tuple(values.get("hotblocks", "").split(","))
            sample = Sample(
                poll=poll,
                vi=int(values["vi"]),
                clock_reads=int(values.get("clock_reads", "0")),
                stable=values["stable"] == "1",
                buttons=int(input_parts[0], 16),
                stick_x=int(input_parts[1]),
                stick_y=int(input_parts[2]),
                menu=int(values["menu"]),
                stage=int(values["stage"]),
                pending=int(values["pending"]),
                state_hash=values["hash"],
                regions=regions,
                pages=pages,
                hotblocks=hotblocks,
            )
        except (KeyError, ValueError, IndexError) as error:
            raise TraceError(f"{path}:{line_number}: malformed sample") from error
        if poll in seen_polls:
            raise TraceError(f"{path}:{line_number}: duplicate poll {poll}")
        if len(sample.regions) != 8:
            raise TraceError(f"{path}:{line_number}: expected 8 region hashes")
        if sample.pages != ("",) and len(sample.pages) != 128:
            raise TraceError(f"{path}:{line_number}: expected 128 page hashes")
        if sample.hotblocks != ("",) and len(sample.hotblocks) != 64:
            raise TraceError(f"{path}:{line_number}: expected 64 hot-block hashes")
        seen_polls.add(poll)
        samples.append(sample)

    if not samples:
        raise TraceError(f"{path}: trace has no samples")
    return Trace(path=path, header=lines[0], samples=tuple(samples), complete_poll=complete_poll)


def differing_regions(left: Sample, right: Sample) -> list[int]:
    return [
        index
        for index, (left_hash, right_hash) in enumerate(zip(left.regions, right.regions))
        if left_hash != right_hash
    ]


def differing_pages(left: Sample, right: Sample) -> list[int]:
    if left.pages == ("",) or right.pages == ("",):
        return []
    return [
        index
        for index, (left_hash, right_hash) in enumerate(zip(left.pages, right.pages))
        if left_hash != right_hash
    ]


def differing_hotblocks(left: Sample, right: Sample) -> list[str]:
    if left.hotblocks == ("",) or right.hotblocks == ("",):
        return []
    hot_pages = (2, 5, 6, 59)
    result: list[str] = []
    for index, (left_hash, right_hash) in enumerate(
        zip(left.hotblocks, right.hotblocks)
    ):
        if left_hash == right_hash:
            continue
        page = hot_pages[index // 16]
        block = index % 16
        start = page * 64 * 1024 + block * 4 * 1024
        result.append(f"0x{0x80000000 + start:08x}")
    return result


def compare(left: Trace, right: Trace) -> tuple[int, list[str]]:
    messages: list[str] = []
    if left.header != right.header:
        return 2, ["ERROR: trace headers differ; build/probe contracts are incompatible"]
    if left.complete_poll is None or right.complete_poll is None:
        return 2, ["INCONCLUSIVE: one or both traces lack a completion marker"]
    if left.complete_poll != right.complete_poll:
        return 2, [
            "INCONCLUSIVE: completion polls differ "
            f"({left.complete_poll} vs {right.complete_poll})"
        ]

    left_by_poll = {sample.poll: sample for sample in left.samples}
    right_by_poll = {sample.poll: sample for sample in right.samples}
    if left_by_poll.keys() != right_by_poll.keys():
        missing_left = sorted(right_by_poll.keys() - left_by_poll.keys())
        missing_right = sorted(left_by_poll.keys() - right_by_poll.keys())
        return 2, [
            "INCONCLUSIVE: sampled poll sets differ "
            f"missing-left={missing_left[:8]} missing-right={missing_right[:8]}"
        ]

    unstable = 0
    compared = 0
    for poll in sorted(left_by_poll):
        left_sample = left_by_poll[poll]
        right_sample = right_by_poll[poll]
        if left_sample.input_identity != right_sample.input_identity:
            return 2, [
                f"ERROR: input stream differs at poll {poll}: "
                f"{left_sample.input_identity} vs {right_sample.input_identity}"
            ]
        if left_sample.clock_reads != right_sample.clock_reads:
            return 2, [
                f"ERROR: deterministic clock reads differ at poll {poll}: "
                f"{left_sample.clock_reads} vs {right_sample.clock_reads}"
            ]
        if not left_sample.stable or not right_sample.stable:
            unstable += 1
            continue
        compared += 1
        if left_sample.state_hash != right_sample.state_hash:
            regions = differing_regions(left_sample, right_sample)
            pages = differing_pages(left_sample, right_sample)
            hotblocks = differing_hotblocks(left_sample, right_sample)
            return 1, [
                f"DIVERGED: first stable mismatch at poll {poll}",
                f"  VI counts: {left_sample.vi} vs {right_sample.vi}",
                "  menu/stage/pending: "
                f"{left_sample.menu}/{left_sample.stage}/{left_sample.pending} vs "
                f"{right_sample.menu}/{right_sample.stage}/{right_sample.pending}",
                f"  differing 1 MiB RDRAM regions: {regions}",
                f"  differing 64 KiB RDRAM pages: {pages}",
                f"  differing 4 KiB hot blocks: {hotblocks}",
                f"  hashes: {left_sample.state_hash} vs {right_sample.state_hash}",
            ]

    if compared == 0:
        return 2, [
            f"INCONCLUSIVE: no stable samples were comparable; unstable={unstable}"
        ]
    messages.append(
        f"PASS: {compared} stable samples match through poll {left.complete_poll}"
    )
    if unstable:
        messages.append(
            f"WARNING: {unstable} samples were unstable within a run and were excluded"
        )
    return 0, messages


def _sample_line(poll: int, state_hash: str, *, stable: int = 1) -> str:
    regions = ",".join([state_hash] * 8)
    return (
        f"SAMPLE poll={poll} vi={poll} stable={stable} input=0000,0,0 "
        f"menu=0 stage=90 pending=90 hash={state_hash} regions={regions}"
    )


def self_test() -> int:
    header = (
        f"{MAGIC} base_bytes=8388608 region_bytes=1048576 regions=8 "
        "script=fixed-menu-dam-v1 max_poll=3600"
    )

    def make_trace(name: str, lines: Iterable[str]) -> Trace:
        samples: list[Sample] = []
        complete: int | None = None
        for line in lines:
            if line.startswith("COMPLETE"):
                complete = int(_fields(line)["poll"])
                continue
            values = _fields(line)
            parts = values["input"].split(",")
            samples.append(
                Sample(
                    poll=int(values["poll"]),
                    vi=int(values["vi"]),
                    clock_reads=int(values.get("clock_reads", "0")),
                    stable=values["stable"] == "1",
                    buttons=int(parts[0], 16),
                    stick_x=int(parts[1]),
                    stick_y=int(parts[2]),
                    menu=int(values["menu"]),
                    stage=int(values["stage"]),
                    pending=int(values["pending"]),
                    state_hash=values["hash"],
                    regions=tuple(values["regions"].split(",")),
                    pages=tuple(values.get("pages", "").split(",")),
                    hotblocks=tuple(values.get("hotblocks", "").split(",")),
                )
            )
        return Trace(path=pathlib.Path(name), header=header, samples=tuple(samples), complete_poll=complete)

    matching = make_trace("a", [_sample_line(1, "aa"), "COMPLETE poll=3600"])
    matching_b = make_trace("b", [_sample_line(1, "aa"), "COMPLETE poll=3600"])
    diverged = make_trace("c", [_sample_line(1, "bb"), "COMPLETE poll=3600"])
    unstable = make_trace("d", [_sample_line(1, "aa", stable=0), "COMPLETE poll=3600"])
    if compare(matching, matching_b)[0] != 0:
        print("self-test failed: matching traces did not pass", file=sys.stderr)
        return 1
    if compare(matching, diverged)[0] != 1:
        print("self-test failed: divergence was not detected", file=sys.stderr)
        return 1
    if compare(unstable, matching_b)[0] != 2:
        print("self-test failed: unstable trace was not inconclusive", file=sys.stderr)
        return 1
    print("GoldenPad determinism trace comparator self-test: PASS")
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
        left = parse_trace(arguments.trace_a)
        right = parse_trace(arguments.trace_b)
        status, messages = compare(left, right)
    except TraceError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    for message in messages:
        print(message)
    return status


if __name__ == "__main__":
    raise SystemExit(main())
