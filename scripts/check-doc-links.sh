#!/usr/bin/env bash
set -euo pipefail

failed=0

while IFS= read -r file; do
  while IFS= read -r target; do
    case "$target" in
      http://*|https://*|mailto:*|\#*|'') continue ;;
    esac

    target="${target%%#*}"
    target="${target#<}"
    target="${target%>}"
    resolved="$(dirname "$file")/$target"

    if [[ ! -e "$resolved" ]]; then
      echo "broken local link: $file -> $target" >&2
      failed=1
    fi
  done < <(sed -nE 's/.*\]\(([^)]+)\).*/\1/p' "$file")
done < <(find . -name '*.md' -not -path './build/*' -not -path './.git/*' | sort)

exit "$failed"

