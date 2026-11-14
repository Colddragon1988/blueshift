#!/bin/sh
# Copies the addon itself, and nothing else from this repository, into a WoW AddOns folder:
#   tools/install.sh "/path/to/World of Warcraft/_forever_/Interface/AddOns"
set -e

addons=$1
if [ -z "$addons" ] || [ ! -d "$addons" ]; then
	echo "usage: $0 <path to Interface/AddOns>" >&2
	exit 1
fi

src=$(cd "$(dirname "$0")/.." && pwd)
dest=$addons/BlueShift

# Only ever replace a folder that is this addon
if [ -e "$dest" ] && [ ! -f "$dest/BlueShift.toc" ]; then
	echo "$dest exists but is not the BlueShift addon" >&2
	exit 1
fi

rm -rf "$dest"
mkdir -p "$dest"
cp "$src/BlueShift.toc" "$src/BlueShift.lua" "$dest/"
echo "Installed BlueShift $(sed -n 's/^## Version: //p' "$src/BlueShift.toc") to $dest"
