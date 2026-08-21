// This bounded importer implements GoldenEye64Recomp's GEP1 conversion format
// for its pinned a787fe0d95e8278fcba5ba2d768fa6a606e75f55 input. It deliberately
// accepts only the exact supported retail and TLB-free hashes.
#include "xxHash/xxh3.h"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <vector>

namespace {
constexpr size_t kRetailROMSize = 0xC00000;
constexpr size_t kTLBFreeROMSize = 0xC11460;
constexpr size_t kMaximumPatchSize = 1024 * 1024;
constexpr uint64_t kRetailROMHash = UINT64_C(0x639ece0bc88c6e4a);
constexpr uint64_t kTLBFreeROMHash = UINT64_C(0xd49fb2a8d6d3bd65);

enum ImportResult : int32_t {
    ImportSucceeded = 0,
    ImportInvalidArguments = 1,
    ImportSourceReadFailed = 2,
    ImportUnsupportedHeader = 3,
    ImportUnsupportedROM = 4,
    ImportPatchReadFailed = 5,
    ImportPatchInvalid = 6,
    ImportOutputInvalid = 7,
    ImportOutputWriteFailed = 8,
};

void clearBytes(std::vector<uint8_t> &bytes) {
    volatile uint8_t *cursor = bytes.data();
    for (size_t index = 0; index < bytes.size(); ++index) {
        cursor[index] = 0;
    }
    bytes.clear();
}

struct SensitiveBytes {
    std::vector<uint8_t> value;
    ~SensitiveBytes() { clearBytes(value); }
};

bool readBoundedFile(const std::filesystem::path &path, size_t minimumSize,
                     size_t maximumSize, std::vector<uint8_t> &bytes,
                     bool *sizeRejected = nullptr) {
    if (sizeRejected != nullptr) {
        *sizeRejected = false;
    }
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    if (!input.good()) {
        return false;
    }
    const std::streamsize length = input.tellg();
    if (length < 0 || static_cast<uint64_t>(length) < minimumSize ||
        static_cast<uint64_t>(length) > maximumSize) {
        if (sizeRejected != nullptr) {
            *sizeRejected = true;
        }
        return false;
    }
    input.seekg(0, std::ios::beg);
    bytes.resize(static_cast<size_t>(length));
    return input.read(reinterpret_cast<char *>(bytes.data()), length).good();
}

bool normalizeROMByteOrder(std::vector<uint8_t> &bytes) {
    if (bytes.size() < 4) {
        return false;
    }
    if (bytes[0] == 0x80 && bytes[1] == 0x37 &&
        bytes[2] == 0x12 && bytes[3] == 0x40) {
        return true;
    }
    if (bytes[0] == 0x37 && bytes[1] == 0x80 &&
        bytes[2] == 0x40 && bytes[3] == 0x12) {
        if ((bytes.size() % 2) != 0) {
            return false;
        }
        for (size_t offset = 0; offset < bytes.size(); offset += 2) {
            std::swap(bytes[offset], bytes[offset + 1]);
        }
        return true;
    }
    if (bytes[0] == 0x40 && bytes[1] == 0x12 &&
        bytes[2] == 0x37 && bytes[3] == 0x80) {
        if ((bytes.size() % 4) != 0) {
            return false;
        }
        for (size_t offset = 0; offset < bytes.size(); offset += 4) {
            std::swap(bytes[offset], bytes[offset + 3]);
            std::swap(bytes[offset + 1], bytes[offset + 2]);
        }
        return true;
    }
    return false;
}

uint32_t readU32LE(const uint8_t *bytes) {
    return static_cast<uint32_t>(bytes[0]) |
        (static_cast<uint32_t>(bytes[1]) << 8) |
        (static_cast<uint32_t>(bytes[2]) << 16) |
        (static_cast<uint32_t>(bytes[3]) << 24);
}

bool appendCopy(const std::vector<uint8_t> &source, uint32_t sourceOffset,
                uint32_t length, size_t targetSize, std::vector<uint8_t> &output) {
    const size_t offset = sourceOffset;
    const size_t count = length;
    if (offset > source.size() || count > source.size() - offset ||
        output.size() > targetSize || count > targetSize - output.size()) {
        return false;
    }
    output.insert(output.end(), source.begin() + offset, source.begin() + offset + count);
    return true;
}

bool appendData(const std::vector<uint8_t> &patch, size_t &offset, uint32_t length,
                size_t targetSize, std::vector<uint8_t> &output) {
    const size_t count = length;
    if (offset > patch.size() || count > patch.size() - offset ||
        output.size() > targetSize || count > targetSize - output.size()) {
        return false;
    }
    output.insert(output.end(), patch.begin() + offset, patch.begin() + offset + count);
    offset += count;
    return true;
}

bool applyGEP1(const std::vector<uint8_t> &patch, const std::vector<uint8_t> &source,
               std::vector<uint8_t> &output) {
    if (patch.size() < 13 || patch[0] != 'G' || patch[1] != 'E' ||
        patch[2] != 'P' || patch[3] != '1') {
        return false;
    }
    const uint32_t sourceSize = readU32LE(patch.data() + 4);
    const uint32_t targetSize = readU32LE(patch.data() + 8);
    if (sourceSize != source.size() || sourceSize != kRetailROMSize ||
        targetSize != kTLBFreeROMSize) {
        return false;
    }

    output.clear();
    output.reserve(targetSize);
    size_t offset = 12;
    bool ended = false;
    while (offset < patch.size()) {
        const uint8_t operation = patch[offset++];
        if (operation == 0x00) {
            if (offset > patch.size() || 8 > patch.size() - offset) {
                return false;
            }
            const uint32_t sourceOffset = readU32LE(patch.data() + offset);
            const uint32_t length = readU32LE(patch.data() + offset + 4);
            offset += 8;
            if (!appendCopy(source, sourceOffset, length, targetSize, output)) {
                return false;
            }
        } else if (operation == 0x01) {
            if (offset > patch.size() || 4 > patch.size() - offset) {
                return false;
            }
            const uint32_t length = readU32LE(patch.data() + offset);
            offset += 4;
            if (!appendData(patch, offset, length, targetSize, output)) {
                return false;
            }
        } else if (operation == 0xFF) {
            ended = true;
            break;
        } else {
            return false;
        }
    }
    return ended && offset == patch.size() && output.size() == targetSize;
}

bool writeFile(const std::filesystem::path &path, const std::vector<uint8_t> &bytes) {
    std::ofstream output(path, std::ios::binary | std::ios::trunc);
    if (!output.good()) {
        return false;
    }
    output.write(reinterpret_cast<const char *>(bytes.data()),
                 static_cast<std::streamsize>(bytes.size()));
    output.close();
    return output.good();
}
}

extern "C" int32_t goldenpad_recomp_import_rom(const char *sourcePath,
                                                 const char *patchPath,
                                                 const char *outputPath) {
    if (sourcePath == nullptr || patchPath == nullptr || outputPath == nullptr) {
        return ImportInvalidArguments;
    }

    SensitiveBytes source;
    bool sourceSizeRejected = false;
    if (!readBoundedFile(std::filesystem::path(sourcePath), kRetailROMSize,
                         kTLBFreeROMSize, source.value, &sourceSizeRejected)) {
        return sourceSizeRejected ? ImportUnsupportedROM : ImportSourceReadFailed;
    }
    if (!normalizeROMByteOrder(source.value)) {
        return ImportUnsupportedHeader;
    }

    const uint64_t sourceHash = XXH3_64bits(source.value.data(), source.value.size());
    SensitiveBytes converted;
    if (sourceHash == kTLBFreeROMHash && source.value.size() == kTLBFreeROMSize) {
        converted.value = source.value;
    } else {
        if (sourceHash != kRetailROMHash || source.value.size() != kRetailROMSize) {
            return ImportUnsupportedROM;
        }
        std::vector<uint8_t> patch;
        if (!readBoundedFile(std::filesystem::path(patchPath), 13,
                             kMaximumPatchSize, patch)) {
            return ImportPatchReadFailed;
        }
        const bool applied = applyGEP1(patch, source.value, converted.value);
        clearBytes(patch);
        if (!applied) {
            return ImportPatchInvalid;
        }
    }

    if (converted.value.size() != kTLBFreeROMSize ||
        XXH3_64bits(converted.value.data(), converted.value.size()) != kTLBFreeROMHash) {
        return ImportOutputInvalid;
    }
    if (!writeFile(std::filesystem::path(outputPath), converted.value)) {
        return ImportOutputWriteFailed;
    }
    return ImportSucceeded;
}
