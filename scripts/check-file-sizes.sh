#!/usr/bin/env bash
set -euo pipefail

readonly limit=250
failed=0

while IFS= read -r file; do
  case "$file" in
    ./build/*|./.git/*) continue ;;
    *.idr|*.md|*.sh|*.yml|*.yaml|*.nix|*.ipkg|./Makefile) ;;
    *) continue ;;
  esac

  lines="$(wc -l < "$file")"
  if (( lines > limit )); then
    printf 'file exceeds %d lines: %s (%d)\n' "$limit" "$file" "$lines" >&2
    failed=1
  fi
done < <(find . -type f | sort)

exit "$failed"
