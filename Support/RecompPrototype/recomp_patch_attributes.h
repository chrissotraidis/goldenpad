#pragma once

#include "recomp.h"

// Upstream Clang marks every generated function weak. Xcode sorts object paths,
// so two weak definitions can select the unpatched original depending on where
// the private inputs live. Only the patch translation unit gets strong symbols;
// generated originals keep their upstream weak attributes.
#if defined(__clang__)
#undef RECOMP_FUNC
#define RECOMP_FUNC __attribute__((noinline))
#endif
