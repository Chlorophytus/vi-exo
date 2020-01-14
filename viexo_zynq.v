// Crude TMDS transmitter
`timescale 1ns / 1ps
module viexo_zynq
   (// HAS to be 237.5MHz
    input wire tclk,
    // HAS to be 23.75MHz
    input wire pclk,
    // AXI SIGNALLING (HAS to be AXI bus speed, but we will use CDC tactics)
    input wire aclk,
    input wire aresetn,
    input wire [31:0] awaddr,
    input wire [2:0] awsize,
    input wire [7:0] awlen,
    input wire [1:0] awburst,
    input wire awvalid,
    output wire awready,
    input wire [31:0] wdata,
    input wire wvalid,
    output wire wready,
    input wire wlast,
    output wire [1:0] bresp,
    output wire bvalid,
    input wire bready,
    
    output wire hdmi_tx_clk_n,
    output wire hdmi_tx_clk_p,
    output wire [2:0] hdmi_tx_d_n,
    output wire [2:0] hdmi_tx_d_p);
    wire hblank;
    wire vblank;    
    wire hsync;
    wire vsync;
    wire [2:0] tmds;
    viexo_paint p(
        .aclk(pclk),
        .aresetn(aresetn),
        .hblank(hblank),
        .vblank(vblank),
        .hsync(hsync),
        .vsync(vsync));
    viexo_tmds t0(
        .aclk(tclk),
        .aresetn(aresetn),
        .c({vsync, ~hsync}),
        .d(8'h00),
        .de(~(hblank | vblank)),
        .channel(tmds[0]));
    viexo_tmds t1(
        .aclk(tclk),
        .aresetn(aresetn),
        .c(2'b00),
        .d(8'h00),
        .de(~(hblank | vblank)),
        .channel(tmds[1]));
    viexo_tmds t2(
        .aclk(tclk),
        .aresetn(aresetn),
        .c(2'b00),
        .d(8'h00),
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