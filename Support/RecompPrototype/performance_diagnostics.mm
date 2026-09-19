#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <mach/mach.h>
#include <sys/sysctl.h>
#include <sys/resource.h>
#include <cstring>
#include <os/log.h>
#include <array>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <deque>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <sstream>
#include <thread>
#include "performance_diagnostics.h"
#include "performance_statistics.hpp"

extern "C" void goldenpad_diagnostics_refresh();
extern "C" void goldenpad_diagnostics_graphics(int32_t *, int32_t *, int32_t *, float *);

namespace {
using Clock=std::chrono::steady_clock;
constexpr size_t queueLimit=256, lineLimit=896, logLimit=4*1024*1024;
constexpr std::array<const char *,12> names={"display_list","screen_submit","gpu_command","gpu_completion_latency","drawable_wait","fence_wait","pipeline_create","present_complete_interval","texture_create","texture_upload","input_poll_interval","present_wait"};
struct State {
    std::mutex mutex;
    std::condition_variable cv;
    std::deque<std::string> lines;
    std::array<goldenpad::Distribution,12> samples{};
    std::array<uint64_t,7> progress{}, previous{};
    int active=0,stage=-1,menu=-1;
    uint32_t width=0,height=0;
    std::string summary="No completed performance window yet.";
    std::atomic<uint64_t> dropped{0};
    std::atomic<bool> started{false};
    bool enabled=true;
    uint64_t requestedFlush=0, completedFlush=0;
    Clock::time_point epoch=Clock::now();
    std::string path;
};
// Process-lifetime state: callbacks can outlive runtime shutdown. No atexit race.
State &state() { static auto *s=new State; return *s; }
uint64_t milliseconds() { return std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now()-state().epoch).count(); }
std::string stamp(const std::string &line) { return "t_ms="+std::to_string(milliseconds())+" "+line; }
void writeLines(const std::string &path, const std::deque<std::string> &lines) {
    if(lines.empty()) return;
    std::error_code error;
    auto bytes=std::filesystem::file_size(path,error);
    if(error) bytes=0;
    std::ofstream out(path,std::ios::app);
    for(const auto &line:lines) {
        if(bytes+line.size()+1>logLimit) {
            out.close();
            const auto segment=path+".1";
            std::filesystem::remove(segment,error); error.clear();
            std::filesystem::rename(path,segment,error);
            out.open(path,std::ios::trunc); bytes=0;
        }
        out<<line<<'\n'; bytes+=line.size()+1;
        os_log_debug(OS_LOG_DEFAULT, "%{private}s", line.c_str());
    }
    out.flush();
    if(!out) os_log_error(OS_LOG_DEFAULT,"GoldenPad diagnostic file write failed");
}
// Sample only this process. Export fixed categories, never thread names or IDs.
std::string threadCPU() {
    thread_act_array_t threads=nullptr; mach_msg_type_number_t count=0;
    if(task_threads(mach_task_self(),&threads,&count)!=KERN_SUCCESS) return " thread_cpu=unavailable";
    std::array<uint64_t,5> usage{};
    for(mach_msg_type_number_t i=0;i<count;++i) {
        thread_extended_info_data_t info{}; auto size=static_cast<mach_msg_type_number_t>(THREAD_EXTENDED_INFO_COUNT);
        if(thread_info(threads[i],THREAD_EXTENDED_INFO,(thread_info_t)&info,&size)==KERN_SUCCESS && !(info.pth_flags&TH_FLAGS_IDLE)) {
            info.pth_name[MAXTHREADNAMESIZE-1]=0;
            const char *name=info.pth_name;
            size_t group=4;
            if(!strcmp(name,"GE game")) group=0;
            else if(!strcmp(name,"Gfx Thread")) group=1;
            else if(!strcmp(name,"SP Task Thread")) group=2;
            else if(!strcmp(name,"VI Thread")) group=3;
            usage[group]+=std::max(info.pth_cpu_usage,0);
        }
        mach_port_deallocate(mach_task_self(),threads[i]);
    }
    vm_deallocate(mach_task_self(),reinterpret_cast<vm_address_t>(threads),sizeof(thread_t)*count);
    std::ostringstream out; constexpr const char *labels[]={"game","gfx","rsp","vi","other"};
    for(size_t i=0;i<usage.size();++i) out<<" "<<labels[i]<<"_cpu_sample_pct="<<usage[i]*100/TH_USAGE_SCALE;
    return out.str();
}
void worker() {
    auto &s=state(); auto previousTime=Clock::now();
    goldenpad::StallWindow stall;
    uint64_t previousCPU=0;
    while(true) {
        @autoreleasepool {
            std::deque<std::string> lines;
            std::array<goldenpad::Distribution,12> samples{};
            std::array<uint64_t,7> current{};
            int active,stage,menu; uint64_t flush;
            const auto now=Clock::now();
            bool summarize=now-previousTime>=std::chrono::seconds(2);
            if(summarize) goldenpad_diagnostics_refresh();
            {
                std::unique_lock lock(s.mutex);
                s.cv.wait_for(lock,std::chrono::milliseconds(250),[&]{return s.requestedFlush>s.completedFlush;});
                lines.swap(s.lines); flush=s.requestedFlush;
                active=s.active; stage=s.stage; menu=s.menu; current=s.progress;
                if(summarize) { samples=s.samples; s.samples={}; }
            }
            if(summarize && s.enabled) {
                auto elapsed=std::chrono::duration_cast<std::chrono::milliseconds>(now-previousTime).count();
                std::ostringstream out;
                out<<"perf window_ms="<<elapsed<<" active="<<active<<" stage="<<stage<<" menu="<<menu;
                constexpr const char *keys[]={"dl","vi_calls","screen_submits","audio_rendered","audio_dropped","audio_underruns"};
                for(size_t i=0;i<6;++i) out<<" "<<keys[i]<<"_delta="<<goldenpad::delta(current[i],s.previous[i]);
                out<<" gpu_sample_stride="<<(getenv("GOLDENPAD_PERF_FULL_GPU")?1:16);
                out<<" audio_queued="<<current[6]<<" dropped_events="<<s.dropped.exchange(0);
                struct rusage usage{};
                if(getrusage(RUSAGE_SELF,&usage)==0) {
                    const uint64_t cpu=(usage.ru_utime.tv_sec+usage.ru_stime.tv_sec)*1000000ULL+usage.ru_utime.tv_usec+usage.ru_stime.tv_usec;
                    if(previousCPU && elapsed>0) out<<" process_cpu_pct="<<goldenpad::delta(cpu,previousCPU)/(elapsed*10);
                    previousCPU=cpu;
                }
                int32_t resolution=0, msaa=0, filter=0; float scale=0;
                goldenpad_diagnostics_graphics(&resolution,&msaa,&filter,&scale);
                out<<" active_resolution_mode="<<resolution<<" active_msaa="<<msaa<<" active_three_point="<<filter<<" render_scale="<<scale;
                out<<threadCPU();
                out<<" thermal="<<(long)NSProcessInfo.processInfo.thermalState<<" low_power="<<NSProcessInfo.processInfo.lowPowerModeEnabled;
                task_vm_info_data_t vm{}; mach_msg_type_number_t count=TASK_VM_INFO_COUNT;
                if(task_info(mach_task_self(),TASK_VM_INFO,(task_info_t)&vm,&count)==KERN_SUCCESS) out<<" footprint_mib="<<vm.phys_footprint/(1024*1024);
                { std::lock_guard lock(s.mutex); out<<" drawable="<<s.width<<"x"<<s.height; s.summary=out.str(); }
                lines.push_back(stamp(out.str()));
                const bool advanced=current[0]!=s.previous[0]||current[2]!=s.previous[2];
                if(stall.update(milliseconds(),active&&(current[0]||current[1]),advanced)) lines.push_back(stamp("stall no_render_progress_ms>=10000 (suspension excluded; not a crash diagnosis)"));
                s.previous=current;
                for(size_t i=0;i<samples.size();++i) if(samples[i].count) {
                    const auto &v=samples[i];
                    std::ostringstream row; row<<"timing kind="<<names[i]<<" n="<<v.count<<" mean_us="<<v.totalUs/v.count<<" p95_upper_us="<<v.p95UpperUs()<<" max_us="<<v.maxUs<<" value_sum="<<v.value;
                    lines.push_back(stamp(row.str()));
                }
                previousTime=now;
            }
            writeLines(s.path,lines);
            { std::lock_guard lock(s.mutex); s.completedFlush=flush; }
            s.cv.notify_all();
        }
    }
}
}
extern "C" void goldenpad_diagnostics_sample(uint32_t kind,uint64_t ns,uint64_t value) {
    auto &s=state(); if(!s.started.load(std::memory_order_acquire)||!s.enabled||kind>=names.size()) return;
    std::unique_lock lock(s.mutex,std::try_to_lock);
    if(!lock.owns_lock()) { ++s.dropped; return; }
    s.samples[kind].add(ns,value);
}
extern "C" void goldenpad_diagnostics_progress(uint64_t dl,uint64_t vi,uint64_t submitted,uint64_t rendered,uint64_t dropped,uint64_t underruns,uint64_t queued,int32_t active,int32_t stage,int32_t menu) {
    auto &s=state(); std::unique_lock lock(s.mutex,std::try_to_lock);
    if(!lock.owns_lock()) { ++s.dropped; return; }
    s.progress={dl,vi,submitted,rendered,dropped,underruns,queued}; s.active=active; s.stage=stage; s.menu=menu;
}
void goldenpad_diagnostics_event(const char *event,const char *detail) {
    auto &s=state();
    std::unique_lock lock(s.mutex,std::try_to_lock);
    if(!lock.owns_lock()||s.lines.size()>=queueLimit) { ++s.dropped; return; }
    std::string line=std::string("[GoldenPadRecomp] ")+event+": "+detail;
    if(line.size()>lineLimit) line.resize(lineLimit);
    for(auto &c:line) if(c=='\n'||c=='\r') c=' ';
    s.lines.push_back(stamp(line));
}
extern "C" void goldenpad_diagnostics_start(const char *path) {
    auto &s=state(); if(s.started.load()) return;
    s.path=path;
    // Developer matched-control switch; no user data or gameplay state changes.
    s.enabled=getenv("GOLDENPAD_PERF_DISABLED")==nullptr;
    s.started.store(true,std::memory_order_release);
    std::thread(worker).detach();
    goldenpad_diagnostics_event("diagnostics","schema=2 durations=wall_us counters_are_not_unique_game_fps");
    @autoreleasepool {
        auto bundle=NSBundle.mainBundle;
        NSString *source=[NSString stringWithContentsOfURL:[bundle URLForResource:@"BuildIdentity" withExtension:@"txt"] encoding:NSUTF8StringEncoding error:nil];
        NSString *session=[NSString stringWithFormat:@"id=%@ utc=%@ version=%@ build=%@ source=%@",
            NSUUID.UUID.UUIDString, [[[NSISO8601DateFormatter alloc] init] stringFromDate:NSDate.date],
            [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown",
            [bundle objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"unknown", source ?: @"unavailable"];
        goldenpad_diagnostics_event("session", session.UTF8String);
    }
}
extern "C" void goldenpad_diagnostics_flush() {
    auto &s=state(); if(!s.started.load()) return;
    std::unique_lock lock(s.mutex); auto sequence=++s.requestedFlush; s.cv.notify_all();
    s.cv.wait_for(lock,std::chrono::milliseconds(750),[&]{return s.completedFlush>=sequence;});
}

extern "C" int goldenpad_diagnostics_enabled() { auto &s=state(); return s.started.load(std::memory_order_acquire)&&s.enabled; }
extern "C" void goldenpad_diagnostics_surface(uint32_t width,uint32_t height) {
    auto &s=state(); std::unique_lock lock(s.mutex,std::try_to_lock); if(!lock.owns_lock()) return; s.width=width; s.height=height;
}
extern "C" const char *goldenpad_diagnostics_summary() {
    static thread_local std::string result; auto &s=state(); std::lock_guard lock(s.mutex);
    result=s.started.load()?s.summary:"No game session started in this process; previous logs describe earlier sessions."; return result.c_str();
}
