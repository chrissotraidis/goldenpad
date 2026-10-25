#include <iostream>
#include <sstream>
#include "recompiler/generator.h"

int main() {
    N64Recomp::Context context;
    std::ostringstream output;
    N64Recomp::CGenerator generator(output);
    for (const char* name : {"sprintf", "sprintf_recomp", "ordinary_game_callback"}) {
        if (!context.add_reference_symbol(name, N64Recomp::SectionAbsolute, 0x80000000, true)) return 1;
        N64Recomp::SymbolReference reference;
        if (!context.find_reference_symbol(name, reference)) return 2;
        generator.emit_function_call_reference_symbol(context, reference.section_index, reference.symbol_index, 0);
    }
    if (output.str() != "sprintf_recomp(rdram, ctx);\nsprintf_recomp(rdram, ctx);\nordinary_game_callback(rdram, ctx);\n") {
        std::cerr << "Patch reference names no longer match the base generator\n";
        return 3;
    }
    std::cout << "Patch reference names match the base generator\n";
}
