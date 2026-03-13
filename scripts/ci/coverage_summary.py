#!/usr/bin/env python3

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: coverage_summary.py <summary-json> <title>", file=sys.stderr)
        return 1

    summary_path = Path(sys.argv[1])
    title = sys.argv[2]
    data = json.loads(summary_path.read_text())["data"][0]["totals"]

    print(f"### {title}")
    for key in ("lines", "functions", "regions", "branches"):
        metric = data[key]
        covered = metric["covered"]
        count = metric["count"]
        percent = (covered / count * 100.0) if count else 100.0
        label = key.capitalize()
        print(f"- {label}: {covered}/{count} ({percent:.1f}%)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
