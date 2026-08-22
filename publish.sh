#!/usr/bin/env bash
# Create a GMA file and publish it to the Steam Workshop.
# Linux replacement for publish.cmd. Uses fastgmad because this GMod install
# is the Windows/Proton build and has no native gmad/gmpublish binaries.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

FASTGMAD_VERSION="${FASTGMAD_VERSION:-v0.2.1}"
FASTGMAD_DIR="${FASTGMAD_DIR:-$HOME/.local/share/fastgmad}"
FASTGMAD_URL="https://github.com/WilliamVenner/fastgmad/releases/download/${FASTGMAD_VERSION}/fastgmad_linux.zip"

usage() {
	echo "Usage: $0 [-m|-message|-msg \"change notes\"]" >&2
	exit 1
}

CHANGES=""
case "${1:-}" in
	"" ) ;;
	-m | -message | -msg )
		if [[ -z "${2:-}" ]]; then
			echo "Expected a changelog message after $1" >&2
			usage
		fi
		CHANGES="$2"
		;;
	-h | --help ) usage ;;
	* ) usage ;;
esac

if ! command -v jq >/dev/null; then
	echo "jq is required to read addon.json" >&2
	exit 1
fi

ID="$(jq -r '.id // empty' addon.json)"
if [[ -z "$ID" ]]; then
	echo "No ID found in addon.json" >&2
	exit 1
fi

ensure_fastgmad() {
	if [[ -x "$FASTGMAD_DIR/fastgmad" ]]; then
		return
	fi

	if ! command -v curl >/dev/null || ! command -v unzip >/dev/null; then
		echo "curl and unzip are required to download fastgmad" >&2
		exit 1
	fi

	echo "Downloading fastgmad ${FASTGMAD_VERSION}..."
	mkdir -p "$FASTGMAD_DIR"
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' RETURN
	curl -fsSL "$FASTGMAD_URL" -o "$tmp/fastgmad.zip"
	unzip -o -q "$tmp/fastgmad.zip" -d "$FASTGMAD_DIR"
	chmod +x "$FASTGMAD_DIR/fastgmad"
}

ensure_fastgmad

export LD_LIBRARY_PATH="$FASTGMAD_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
FASTGMAD="$FASTGMAD_DIR/fastgmad"

# Upload the addon folder, not a .gma path. On Linux, fastgmad symlinks a
# .gma into its staging dir and Steam's uploader skips that, leaving file_size=0
# and downloads fail with k_EResultNoMatch (42). A folder upload writes a real GMA.
echo "Publishing workshop item ${ID}..."
if [[ -n "$CHANGES" ]]; then
	"$FASTGMAD" update -id "$ID" -addon "$ROOT" -changes "$CHANGES" -noprogress
else
	"$FASTGMAD" update -id "$ID" -addon "$ROOT" -noprogress
fi

echo "Done."
echo "https://steamcommunity.com/sharedfiles/filedetails/?id=${ID}"
