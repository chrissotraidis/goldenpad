#pragma once
#include <algorithm>
#include <array>
#include <cstdint>
namespace goldenpad {
// Fixed buckets: reported percentile is the bucket upper bound, not an exact percentile.
struct Distribution {
    static constexpr std::array<uint64_t, 14> limitsUs = {100,250,500,1000,2000,4000,8000,16000,25000,33000,50000,100000,250000,1000000};
    uint64_t count=0, totalUs=0, maxUs=0, value=0;
    std::array<uint64_t, 15> bins{};
    void add(uint64_t ns, uint64_t extra=0) {
        const auto us=ns/1000;
        ++count; totalUs+=us; maxUs=std::max(maxUs,us); value+=extra;
        ++bins[std::lower_bound(limitsUs.begin(),limitsUs.end(),us)-limitsUs.begin()];
    }
    uint64_t p95UpperUs() const {
        if (!count) return 0;
        uint64_t cumulative=0, target=count-count/20;
        for (size_t i=0;i<bins.size();++i) {
            cumulative+=bins[i];
            if (cumulative>=target) return i<limitsUs.size()?limitsUs[i]:maxUs;
        }
        return maxUs;
    }
};
inline uint64_t delta(uint64_t now,uint64_t before) { return now>=before?now-before:0; }
struct StallWindow {
    uint64_t lastProgressMs=0;
    bool reported=false;
    bool update(uint64_t nowMs, bool active, bool progressed) {
        if (!active || progressed || !lastProgressMs) { lastProgressMs=nowMs; reported=false; return false; }
        if (!reported && nowMs-lastProgressMs>=10000) { reported=true; return true; }
        return false;
    }
};
}
