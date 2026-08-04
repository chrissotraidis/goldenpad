#include "gui/rt64_file_dialog.h"

namespace RT64 {
    std::atomic<bool> FileDialog::isOpen = false;

    void FileDialog::initialize() {}
    void FileDialog::finish() {}

    std::filesystem::path FileDialog::getDirectoryPath() {
        return {};
    }

    std::filesystem::path FileDialog::getOpenFilename(const std::vector<FileFilter> &filters) {
        (void)filters;
        return {};
    }

    std::filesystem::path FileDialog::getSaveFilename(const std::vector<FileFilter> &filters) {
        (void)filters;
        return {};
    }
}
