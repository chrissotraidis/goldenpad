#include "../Support/RecompPrototype/performance_diagnostics.h"
#include "../Support/RecompPrototype/performance_statistics.hpp"
#include <cassert>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <thread>
#include <vector>
extern "C" void goldenpad_diagnostics_refresh() {
    goldenpad_diagnostics_progress(10,20,15,30,0,0,64,1,1,14);
}
extern "C" void goldenpad_diagnostics_graphics(int32_t *r,int32_t *m,int32_t *f,float *s) { *r=0;*m=0;*f=0;*s=1; }
int main(int argc,char **argv) {
    assert(argc==2);
    goldenpad::Distribution d;
    for(int i=0;i<95;++i) d.add(1000000);
    for(int i=0;i<5;++i) d.add(100000000);
    assert(d.count==100 && d.p95UpperUs()==1000 && d.maxUs==100000);
    assert(goldenpad::delta(2,3)==0);
    goldenpad::StallWindow stall;
    assert(!stall.update(1000,true,true));
    assert(!stall.update(10999,true,false));
    assert(stall.update(11000,true,false));
    assert(!stall.update(12000,true,false));
    assert(!stall.update(50000,false,false));
    assert(!stall.update(51000,true,false));
    assert(stall.update(60000,true,false));
    const std::string path=argv[1];
    goldenpad_diagnostics_start(path.c_str());
    const auto start=std::chrono::steady_clock::now();
    std::vector<std::thread> workers;
    for(int i=0;i<4;++i) workers.emplace_back([] { for(int n=0;n<100000;++n) goldenpad_diagnostics_sample(0,1000000,0); });
    for(auto &t:workers)t.join();
    auto duration=std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now()-start).count();
    goldenpad_diagnostics_event("runtime","test\nline");
    std::this_thread::sleep_for(std::chrono::milliseconds(2500));
    goldenpad_diagnostics_flush();
    std::ifstream file(path);std::string text((std::istreambuf_iterator<char>(file)),{});
    assert(text.find("t_ms=")!=std::string::npos);
    assert(text.find("timing kind=display_list")!=std::string::npos);
    assert(text.find("runtime: test line")!=std::string::npos);
    // Force real file rotation, not a mock. Two segments stay individually bounded.
    const std::string message(850,'x');
    for(int batch=0;batch<30;++batch) {
        for(int i=0;i<240;++i) goldenpad_diagnostics_event("runtime",message.c_str());
        goldenpad_diagnostics_flush();
    }
    assert(std::filesystem::file_size(path)<=4*1024*1024);
    assert(std::filesystem::exists(path+".1"));
    assert(std::filesystem::file_size(path+".1")<=4*1024*1024);
    std::cout<<"PASS histogram, stalls, concurrent hooks, timestamped worker logs, bounded rotation; 400000 hooks wall_us="<<duration<<"\n";
}
