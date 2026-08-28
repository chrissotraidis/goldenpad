#!/usr/bin/env python3
"""Compare common canonical LAN checksum samples from two runtime logs."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


CHECKSUM = re.compile(
    r"checksum frame=(\d+) canonical=([0-9a-f]+) "
    r"globals=([0-9a-f]+) players=([0-9a-f]+) props=([0-9a-f]+)"
)


def samples(path: Path) -> dict[int, tuple[str, str, str, str]]:
    found: dict[int, tuple[str, str, str, str]] = {}
    for line in path.read_text(errors="replace").splitlines():
        match = CHECKSUM.search(line)
        if match:
            frame = int(match.group(1))
            found[frame] = tuple(match.groups()[1:])  # type: ignore[assignment]
    if not found:
        raise SystemExit(f"No LAN checksum samples found in {path}")
    return found


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("first", type=Path)
    parser.add_argument("second", type=Path)
    parser.add_argument("--minimum-frame", type=int, default=0)
    parser.add_argument("--maximum-frame", type=int)
    args = parser.parse_args()

    first = samples(args.first)
    second = samples(args.second)
    common = sorted(first.keys() & second.keys())
    if args.maximum_frame is not None:
        common = [frame for frame in common if frame <= args.maximum_frame]
    if not common:
        raise SystemExit("The logs contain no common checksum frames")
    for frame in common:
        if first[frame] != second[frame]:
            raise SystemExit(
                f"LAN checksum mismatch at frame {frame}: "
                f"{first[frame][0]} != {second[frame][0]}"
            )
    last = common[-1]
    if last < args.minimum_frame:
        raise SystemExit(
            f"Matching samples stop at frame {last}; "
            f"minimum required is {args.minimum_frame}"
        )
    print(
        f"LAN checksum logs: PASS {len(common)} common samples "
        f"through frame {last}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
