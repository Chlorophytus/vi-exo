#include "../include/viexo.hpp"

struct option long_options[] {
    {"vm_verbose", no_argument, nullptr, 'v'},
    {"vm_ticks", required_argument, nullptr, 't'},
    {nullptr, 0, nullptr, 0}
};

int main(int argc, char **argv) {
    // Init my args
    auto option_index = int();
    auto read_ticks = size_t(128);
    auto be_verbose = false;

    while(1) {
        auto c = getopt_long(argc, argv, "t:v", long_options, &option_index);
        if (c == -1) break;
        switch (c) {
            case 't': {
                std::sscanf(optarg, "%zu", &read_ticks);
                break;
            }
            case 'v': {
                std::printf("will verbosely execute\n");
                be_verbose = true;
                break;
            }
            default: break;
        }
    }

    // Now do Verilator's
	Verilated::commandArgs(argc, argv);
    auto device_under_test = std::make_unique<Vviexo_zynq>();
    auto mticks = size_t(32);
    auto mtick_repeating = true;

    for(auto i = 0x000; i < 0x100; i++) {
        device_under_test->aresetn = 0;
        device_under_test->aclk = 1;
        device_under_test->eval();
    }

    device_under_test->aresetn = 1;
    device_under_test->aclk = 0;
    device_under_test->eval();
    
    for(auto ticks = size_t(0); ticks < read_ticks; ticks++) {
        if(be_verbose) {
            std::printf("CLK[0x%zx / 0x%zx] symbol: %x\n",ticks, read_ticks, device_under_test->tmds);
        }
        device_under_test->aclk = 1;
		device_under_test->eval();
        device_under_test->aclk = 0;
		device_under_test->eval();
        if(mtick_repeating || be_verbose) {
            std::printf("CLK[0x%zx / 0x%zx] ==== ticked ====\n", ticks, read_ticks);
            mtick_repeating = false;
        } else if(ticks % mticks == 0) {
            std::printf("CLK[0x%zx / 0x%zx] message repeated 0x%zx times\n", ticks, read_ticks, mticks);
            mticks <<= 1;
        }
    }
    return EXIT_SUCCESS;
}