#!/usr/bin/env bash
# Build a personal, unsigned GoldenPad IPA from your own US retail GoldenEye 007 ROM.
#
# Chains the maintained steps in docs/SOURCE_MAINTENANCE.md: pinned sources,
# private TLB-free conversion, N64Recomp generation, runtime and RT64 archives,
# the iOS app, and the existing package checks. Everything derived from the ROM
# stays under --work, which Git ignores. The result is personal: never publish it.
set -euo pipefail

usage() {
  echo 'Usage: build-personal-ipa.sh --rom YOUR_ROM --output PERSONAL.ipa [--work DIR]' >&2
  exit 2
}

repo_root=$(cd "$(dirname "$0")/.." && pwd)
rom=
output=
work="$repo_root/build-personal"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --rom) [ "$#" -ge 2 ] || usage; rom=$2; shift 2 ;;
    --output) [ "$#" -ge 2 ] || usage; output=$2; shift 2 ;;
    --work) [ "$#" -ge 2 ] || usage; work=$2; shift 2 ;;
    *) usage ;;
  esac
done
[ -n "$rom" ] && [ -n "$output" ] || usage
[ -f "$rom" ] || { echo "ROM not found: $rom" >&2; exit 1; }
command -v xdelta3 >/dev/null || { echo 'xdelta3 is required (brew install xdelta)' >&2; exit 1; }
mkdir -p "$work"
work=$(cd "$work" && pwd)

echo '== Pinned sources'
"$repo_root/scripts/bootstrap-sources.sh"

echo '== Private TLB-free conversion'
normalized="$work/GoldenEye_retail.z64"
tlbfree="$work/GoldenEye_TLBFREE.z64"
python3 - "$rom" "$normalized" <<'PY'
import hashlib, sys
data = open(sys.argv[1], "rb").read()
if len(data) != 12 * 1024 * 1024:
    sys.exit("The ROM is not the 12 MiB US retail GoldenEye 007 dump.")
out = bytearray(data)
head = data[:4]
if head == b"\x80\x37\x12\x40":
    pass
elif head == b"\x37\x80\x40\x12":
    out[0::2], out[1::2] = data[1::2], data[0::2]
elif head == b"\x40\x12\x37\x80":
    out[0::4], out[1::4], out[2::4], out[3::4] = data[3::4], data[2::4], data[1::4], data[0::4]
else:
    sys.exit("Unrecognized N64 ROM byte order.")
if hashlib.sha1(out).hexdigest() != "abe01e4aeb033b6c0836819f549c791b26cfde83":
    sys.exit("The ROM is not the supported US retail revision (SHA-1 mismatch).")
open(sys.argv[2], "wb").write(out)
PY
xdelta3 -d -f -s "$normalized" "$repo_root/vendor/goldeneye/vanilla_to_tlbfree.xdelta" "$tlbfree"
[ "$(shasum -a 256 "$tlbfree" | awk '{print $1}')" = 7ec491ee3164851d0995e3e8ad19999df5e3028be6ba3729c4ac16c31a9c0959 ] || {
  echo 'TLB-free conversion produced an unexpected image.' >&2; exit 1; }

echo '== Generated inputs (N64Recomp)'
generated="$work/generated"
if [ ! -f "$generated/.personal-build-complete" ]; then
  if [ -e "$generated" ]; then
    mv "$generated" "$generated.incomplete.$(date +%Y%m%d%H%M%S)"
  fi
  "$repo_root/scripts/generate-recomp-inputs.sh" "$tlbfree" "$generated"
  touch "$generated/.personal-build-complete"
fi

echo '== Runtime and RT64 archives'
"$repo_root/scripts/build-recomp-runtime.sh" iphoneos
GOLDENPAD_RT64_ARTIFACT_DIR="$repo_root/build-rt64-ios" "$repo_root/scripts/verify-rt64-ios-static.sh"

echo '== iOS app'
"$repo_root/scripts/build-recomp-apple.sh" ios "$generated"
app="$repo_root/build-maintained-ios/Release-iphoneos/GoldenPadRecompPrototype.app"
[ -d "$app" ] || { echo "The build did not produce $app" >&2; exit 1; }

echo '== Package'
GOLDENPAD_RECOMP_APP="$app" GOLDENPAD_RELEASE_NAME=personal \
  GOLDENPAD_RECOMP_REFERENCE_SOURCE_DIR="$generated" \
  "$repo_root/scripts/package-recomp-prototype-ipa.sh"
mkdir -p "$(dirname "$output")"
cp "$repo_root/dist/GoldenPad-personal-unsigned.ipa" "$output"
echo "Personal IPA (do not publish): $output"
