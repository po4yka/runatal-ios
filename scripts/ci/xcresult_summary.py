#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: xcresult_summary.py <xcresult-path> <title>", file=sys.stderr)
        return 1

    xcresult_path = Path(sys.argv[1])
    title = sys.argv[2]

    result = subprocess.run(
        [
            "xcrun",
            "xcresulttool",
            "get",
            "test-results",
            "summary",
            "--path",
            str(xcresult_path),
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    summary = json.loads(result.stdout)
    duration = summary["finishTime"] - summary["startTime"]

    print(f"### {title}")
    print(f"- Result: {summary['result']}")
    print(f"- Total tests: {summary.get('totalTestCount', 0)}")
    print(f"- Passed: {summary['passedTests']}")
    print(f"- Failed: {summary['failedTests']}")
    print(f"- Skipped: {summary['skippedTests']}")
    print(f"- Duration: {duration:.1f}s")

    invalid_frames = [
        warning["message"]
        for warning in summary.get("runtimeWarnings", [])
        if "Invalid frame dimension" in warning["message"]
    ]
    print(f"- Invalid frame warnings: {len(invalid_frames)}")
    if invalid_frames:
        print(
            f"{title}: {len(invalid_frames)} invalid frame runtime warning(s)",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
