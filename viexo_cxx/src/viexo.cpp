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
    #if 0
	Verilated::commandArgs(argc, argv);
    auto device_under_test = std::make_unique<Vblackjack_fpga>();
    auto mticks = size_t(32);
    auto mtick_repeating = true;

    for(auto i = 0x00000; i < 0x10000; i++) {
        device_under_test->aresetn = 0;
        device_under_test->halt = 0;
        device_under_test->aclk = 1;
        device_under_test->eval();
    }
    device_under_test->aresetn = 0;
    device_under_test->halt = 0;
    device_under_test->aclk = 1;
    device_under_test->eval();

    device_under_test->aresetn = 1;
    device_under_test->aclk = 0;
    device_under_test->data_i = 0x0000;
    device_under_test->eval();
    
    for(auto ticks = size_t(0); ticks < read_ticks; ticks++) {
        if(be_verbose) {
            std::printf("CLK[0x%zx / 0x%zx] (CU) ZR=0x%4.0x G1=0x%4.0x G2=0x%4.0x G3=0x%4.0x\n",
                ticks, read_ticks, device_under_test->rZR, device_under_test->rG1,
                device_under_test->rG2, device_under_test->rG3);
            std::printf("CLK[0x%zx / 0x%zx] (CU) G4=0x%4.0x G5=0x%4.0x G6=0x%4.0x G7=0x%4.0x\n",
                ticks, read_ticks, device_under_test->rG4, device_under_test->rG5,
                device_under_test->rG6, device_under_test->rG7);
            std::printf("CLK[0x%zx / 0x%zx] (CU) G8=0x%4.0x G9=0x%4.0x AC=0x%4.0x CN=0x%4.0x\n",
                ticks, read_ticks, device_under_test->rG8, device_under_test->rG9,
                device_under_test->rAC, device_under_test->rCN);
            std::printf("CLK[0x%zx / 0x%zx] (CU) PT=0x%4.0x LR=0x%4.0x FL=0x%4.0x PC=0x%4.0x\n",
                ticks, read_ticks, device_under_test->rPT, device_under_test->rLR,
                device_under_test->rFL, device_under_test->rPC);
            std::printf("CLK[0x%zx / 0x%zx] (ALU) AC=0x%4.0x CN=0x%4.0x\n",
                ticks, read_ticks, device_under_test->rAC, device_under_test->rCN);
            std::printf("CLK[0x%zx / 0x%zx] >> OUT 0x%4.0x\n", ticks, read_ticks, device_under_test->data_o);
            std::printf("CLK[0x%zx / 0x%zx] >> PSTATE 0x%4.0x\n", ticks, read_ticks, device_under_test->pstate);
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
    #endif
    return EXIT_SUCCESS;
}