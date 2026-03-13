#!/usr/bin/env python3

from pathlib import Path
import sys

PATTERNS = [
    ("Model container fallback", "Failed to create ModelContainer"),
    ("Background publish", "Publishing changes from background threads"),
    ("ModelContext unbound", "ModelContext: Unbinding from the main queue"),
]


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: log_audit.py <log-path> [<log-path> ...]", file=sys.stderr)
        return 1

    print("### Runtime log audit")
    print("| Log | Model container fallback | Background publish | ModelContext unbound |")
    print("| --- | ---: | ---: | ---: |")

    for raw_path in sys.argv[1:]:
        path = Path(raw_path)
        text = path.read_text() if path.exists() else ""
        counts = [text.count(pattern) for _, pattern in PATTERNS]
        print(
            f"| `{path.name}` | {counts[0]} | {counts[1]} | {counts[2]} |"
        )

    print("")
    print("- These counts are informational for now and are not yet CI-failing gates.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
