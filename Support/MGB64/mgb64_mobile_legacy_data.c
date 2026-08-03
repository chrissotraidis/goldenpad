#include <stdint.h>

/* Native data formerly emitted by matching-target assembly or the desktop
 * compatibility unit. These are game constants/ROM offsets, not media. */
float D_80051D30 = 1.0471976f;
float D_80051D34 = -0.87266463f;
float D_80051D38 = 0.87266463f;
float D_80051D3C = 1.0471976f;
float D_80051D40 = -0.87266463f;
float D_80051D44 = 6.2831855f;
float D_80051D48 = 6.2831855f;
float D_80051D4C = 6.2831855f;
float D_80051D50 = 6.2831855f;
float D_80051D54 = 6.2831855f;
uint32_t unknown2 = UINT32_C(0x002a4d50);

int goldenpad_mgb64_mobile_legacy_data_probe(void) {
    return D_80051D30 == 1.0471976f && D_80051D34 == -0.87266463f &&
           D_80051D54 == 6.2831855f && unknown2 == UINT32_C(0x002a4d50);
}
