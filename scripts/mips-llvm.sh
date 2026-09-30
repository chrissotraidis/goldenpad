# Sourced by build-personal-ipa.sh and generate-recomp-inputs.sh.
#
# GoldenPad's N64 patches are compiled for MIPS with LLVM's clang and linked with
# lld's ld.lld; Apple's clang cannot target MIPS. goldenpad_find_mips_llvm sets
# GOLDENPAD_MIPS_CC and GOLDENPAD_MIPS_LD, trying in order: values already set,
# PadMint's LLVM (PADMINT_LLVM_ROOT, or PADFORGE_LLVM_ROOT from before the
# rename), then Homebrew's llvm and lld (any Homebrew prefix).
goldenpad_find_mips_llvm() {
  local root=${PADMINT_LLVM_ROOT:-${PADFORGE_LLVM_ROOT:-}} brew_llvm= brew_lld= candidate
  if command -v brew >/dev/null 2>&1; then
    brew_llvm=$(brew --prefix llvm 2>/dev/null || true)
    brew_lld=$(brew --prefix lld 2>/dev/null || true)
  fi
  if [ -z "${GOLDENPAD_MIPS_CC:-}" ]; then
    for candidate in ${root:+"$root/bin/clang"} ${brew_llvm:+"$brew_llvm/bin/clang"}; do
      if [ -x "$candidate" ]; then GOLDENPAD_MIPS_CC=$candidate; break; fi
    done
  fi
  if [ -z "${GOLDENPAD_MIPS_LD:-}" ]; then
    for candidate in ${root:+"$root/bin/ld.lld"} ${brew_lld:+"$brew_lld/bin/ld.lld"} \
      ${brew_llvm:+"$brew_llvm/bin/ld.lld"}; do
      if [ -x "$candidate" ]; then GOLDENPAD_MIPS_LD=$candidate; break; fi
    done
  fi
  GOLDENPAD_MIPS_CC=$(command -v "${GOLDENPAD_MIPS_CC:-}" 2>/dev/null || true)
  GOLDENPAD_MIPS_LD=$(command -v "${GOLDENPAD_MIPS_LD:-}" 2>/dev/null || true)
  if [ -z "$GOLDENPAD_MIPS_CC" ] || [ -z "$GOLDENPAD_MIPS_LD" ]; then
    echo "GoldenPad needs LLVM's clang and ld.lld to build its N64 patches (Apple's clang cannot target the N64)." >&2
    echo "Update PadMint, which downloads them for you, or install them with: brew install llvm lld" >&2
    return 1
  fi
  export GOLDENPAD_MIPS_CC GOLDENPAD_MIPS_LD
}
