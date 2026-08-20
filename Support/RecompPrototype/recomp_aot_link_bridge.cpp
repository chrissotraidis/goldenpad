#include "funcs.h"
#include "recomp.h"
#include "librecomp/rsp.hpp"

extern RspUcodeFunc aspMain;
gpr get_entrypoint_address();

extern "C" uint32_t goldenpad_recomp_aot_entrypoint_address() {
    const auto entrypoint = get_entrypoint_address();
    auto *const cpu_entrypoint = &recomp_entrypoint;
    auto *const rsp_entrypoint = &aspMain;
    (void)cpu_entrypoint;
    (void)rsp_entrypoint;
    return static_cast<uint32_t>(entrypoint);
}
