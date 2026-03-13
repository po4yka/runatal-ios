#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/TranslationCuration/source/translation"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Missing source dataset directory: $SOURCE_DIR" >&2
  exit 1
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <ios-output-dir> [android-output-dir]" >&2
  exit 1
fi

copy_dataset() {
  local target_dir="$1"
  mkdir -p "$target_dir"
  rm -f "$target_dir"/*.json
  cp "$SOURCE_DIR"/*.json "$target_dir"/
  echo "Exported translation dataset to $target_dir"
}

copy_dataset "$1"

if [[ $# -eq 2 ]]; then
  copy_dataset "$2"
fi
