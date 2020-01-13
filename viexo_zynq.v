// Crude TMDS transmitter
`timescale 1ns / 1ps
module viexo_zynq
   (input wire aclk,
    input wire pclk,
    input wire aresetn,
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
        .aclk(aclk),
        .aresetn(aresetn),
        .c({vsync, ~hsync}),
        .d(8'h00),
        .de(~(hblank | vblank)),
        .channel(tmds[0]));
    viexo_tmds t1(
        .aclk(aclk),
        .aresetn(aresetn),
        .c(2'b00),
        .d(8'h00),
        .de(~(hblank | vblank)),
        .channel(tmds[1]));
    viexo_tmds t2(
        .aclk(aclk),
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