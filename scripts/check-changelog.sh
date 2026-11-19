#!/usr/bin/env bash
# Checks the changelog fragments in changelog.d/.
#
#   scripts/check-changelog.sh            validate the name and content of every fragment
#   scripts/check-changelog.sh <base>     also require a new fragment since <base>
#
# A fragment is changelog.d/<issue>.<type>.md, where <issue> is the number of
# the issue the change implements and <type> is one of the types below. See
# changelog.d/README.md.
set -euo pipefail

types="added changed deprecated removed fixed security"
dir="changelog.d"
status=0

cd "$(git rev-parse --show-toplevel)"

for path in "$dir"/*; do
	[ -e "$path" ] || continue
	name="$(basename "$path")"
	case "$name" in
	README.md | .gitkeep) continue ;;
	esac
	if [[ ! "$name" =~ ^([1-9][0-9]*)\.([a-z]+)(\.[0-9]+)?\.md$ ]]; then
		echo "error: $path: name must be <issue>.<type>.md or <issue>.<type>.<n>.md"
		status=1
		continue
	fi
	type="${BASH_REMATCH[2]}"
	if [[ " $types " != *" $type "* ]]; then
		echo "error: $path: type \"$type\" is not one of: $types"
		status=1
	fi
	if ! grep -q '[^[:space:]]' "$path"; then
		echo "error: $path: fragment is empty"
		status=1
	fi
	if grep -q '^#' "$path"; then
		echo "error: $path: fragment must not contain headings"
		status=1
	fi
done

if [ $# -ge 1 ]; then
	base="$1"
	added="$(git diff --name-only --diff-filter=AR "$base"...HEAD -- "$dir" | grep -v -e '/README\.md$' -e '/\.gitkeep$' || true)"
	if [ -z "$added" ]; then
		echo "error: no changelog fragment added since $base."
		echo "Add changelog.d/<issue>.<type>.md, or label the pull request \"no changelog\""
		echo "when the change does not affect operators or the exchange (docs, CI, refactors)."
		status=1
	else
		echo "fragments added:"
		echo "$added"
	fi
fi

if [ "$status" -eq 0 ]; then
	echo "changelog fragments: ok"
fi
exit "$status"
