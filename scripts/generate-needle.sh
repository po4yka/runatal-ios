#!/bin/sh

set -eu

if command -v needle >/dev/null 2>&1; then
  NEEDLE_BIN="$(command -v needle)"
else
  echo "needle CLI not found. Install it with 'brew install needle'." >&2
  exit 1
fi

if [ -n "${SRCROOT:-}" ]; then
  ROOT_DIR="$SRCROOT"
else
  ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

export SOURCEKIT_LOGGING=0

"$NEEDLE_BIN" generate \
  "$ROOT_DIR/RunicQuotes/DI/App/AppNeedleGenerated.swift" \
  "$ROOT_DIR/RunicQuotes" \
  --exclude-paths \
  "/RunicQuotesWidget/" \
  "/RunicQuotesTests/" \
  "/RunicQuotesUITests/" \
  "/RunicQuotesWidgetTests/" \
  "/AppNeedleGenerated.swift" \
  "/WidgetNeedleGenerated.swift"

"$NEEDLE_BIN" generate \
  "$ROOT_DIR/RunicQuotesWidget/DI/WidgetNeedleGenerated.swift" \
  "$ROOT_DIR/RunicQuotesWidget" \
  "$ROOT_DIR/RunicQuotes/Models" \
  "$ROOT_DIR/RunicQuotes/Data" \
  "$ROOT_DIR/RunicQuotes/Utilities" \
  "$ROOT_DIR/RunicQuotes/DI/Shared" \
  --exclude-paths \
  "/RunicQuotes/App/" \
  "/RunicQuotes/Views/" \
  "/RunicQuotes/ViewModels/" \
  "/RunicQuotes/DI/App/" \
  "/AppNeedleGenerated.swift" \
  "/WidgetNeedleGenerated.swift"
