// Crude TMDS transmitter
`timescale 1ns / 1ps
module viexo_zynq
   (// HAS to be 237.5MHz
    input wire tclk,
    // HAS to be 23.75MHz
    input wire pclk,
    // MMIO SIGNALLING
    input wire aclk,
    input wire aresetn,
    input wire [12:0] wen_addr,
    input wire [7:0] wch,
    
    output wire hdmi_tx_clk_n,
    output wire hdmi_tx_clk_p,
    output wire [2:0] hdmi_tx_d_n,
    output wire [2:0] hdmi_tx_d_p,
    output wire [3:0] led);
    wire hblank;
    wire vblank;    
    wire hsync;
    wire vsync;
    wire [2:0] tmds;
    wire [11:0] x;
    wire [11:0] y;
    wire [7:0] ctl_r;
    wire [7:0] ctl_g;
    wire [7:0] ctl_b;
    assign led[0] = 1'b1;
    assign led[1] = wen_addr[12];
    assign led[3:2] = 2'b00;
    viexo_fontrom r(
        .aclk(aclk),
        .pclk(pclk),
        .aresetn(aresetn),
        .x(x),
        .y(y),
        .wen(wen_addr[12]),
        .wputhere(wen_addr[11:0]),
        .wput_c(wch),
        .red(ctl_r),
        .grn(ctl_g),
        .blu(ctl_b)
    );
    viexo_paint p(
        .aclk(pclk),
        .aresetn(aresetn),
        .hblank(hblank),
        .vblank(vblank),
        .x(x),
        .y(y),
        .hsync(hsync),
        .vsync(vsync));
    viexo_tmds t0(
        .aclk(tclk),
        .aresetn(aresetn),
        .c({vsync, ~hsync}),
        .d(ctl_b),
        .de(~(hblank | vblank)),
        .channel(tmds[0]));
    viexo_tmds t1(
        .aclk(tclk),
        .aresetn(aresetn),
        .c(2'b00),
        .d(ctl_g),
        .de(~(hblank | vblank)),
        .channel(tmds[1]));
    viexo_tmds t2(
        .aclk(tclk),
        .aresetn(aresetn),
        .c(2'b00),
        .d(ctl_r),
        .de(~(hblank | vblank)),
        .channel(tmds[2]));
        
    for(genvar i = 0; i < 3; i = i + 1) begin
       OBUFDS #(
          .IOSTANDARD("TMDS_33") // Specify the output I/O standard
       ) OBUFDS_t (
          .O(hdmi_tx_d_p[i]),     // Diff_p output (connect directly to top-level port)
          .OB(hdmi_tx_d_n[i]),   // Diff_n output (connect directly to top-level port)
          .I(tmds[i])      // Buffer input
       );
    end
    
    OBUFDS #(
      .IOSTANDARD("TMDS_33") // Specify the output I/O standard
    ) OBUFDS_t (
      .O(hdmi_tx_clk_p),     // Diff_p output (connect directly to top-level port)
      .OB(hdmi_tx_clk_n),   // Diff_n output (connect directly to top-level port)
      .I(pclk)      // Buffer input
    );
endmodule