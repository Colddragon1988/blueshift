#!/bin/sh
# Builds dist/BlueShift-<version>.zip holding just the addon folder, ready to upload to CurseForge:
#   tools/package.sh
set -e

src=$(cd "$(dirname "$0")/.." && pwd)
version=$(sed -n 's/^## Version: //p' "$src/BlueShift.toc" | tr -d '\r')
zip=$src/dist/BlueShift-$version.zip

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
"$src/tools/install.sh" "$tmp" >/dev/null

mkdir -p "$src/dist"
rm -f "$zip"
(cd "$tmp" && python3 -I -m zipfile -c "$zip" BlueShift)
echo "Built $zip"
