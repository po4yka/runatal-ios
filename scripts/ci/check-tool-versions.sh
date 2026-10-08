#!/usr/bin/env bash

set -euo pipefail

check_version() {
  local tool="$1"
  local expected="$2"
  shift 2

  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing $tool. Install the project tools with 'brew bundle install'." >&2
    return 1
  fi

  local actual
  actual=$("$@" | awk 'NR == 1 { print $NF }')
  if [[ "$actual" != "$expected" ]]; then
    echo "$tool $expected is required; found $actual. Update the tool and its checked version together." >&2
    return 1
  fi
  echo "$tool $actual"
}

if [[ $# -eq 0 ]]; then
  set -- needle swiftformat swiftlint xcodegen
fi

for tool in "$@"; do
  case "$tool" in
    needle) check_version needle 0.25.1 needle version ;;
    swiftformat) check_version swiftformat 0.63.1 swiftformat --version ;;
    swiftlint) check_version swiftlint 0.65.1 swiftlint version ;;
    xcodegen) check_version xcodegen 2.46.0 xcodegen --version ;;
    *) echo "Unknown project tool: $tool" >&2; exit 1 ;;
  esac
done
