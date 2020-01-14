// AXI4 slave
`timescale 1ns / 1ps

// AWBURST==2'b00 FIXED
// AWBURST==2'b01 INCR
// AWBURST==2'b10 WRAP

// BRESP  ==2'b00 OKAY
// BRESP  ==2'b10 SLVERR (Slave error)
// 0x0000_0000: ADDRESS SPACE - VRAM
//             reserved (zero page)
// 0x0000_0100: CGRAM
// 0x0000_0200: CGRAM
//             reserved
// 0x0000_FFFF: ADDRESS SPACE - VRAM
module viexo_axi4
   (// Clock for AXI.
    input logic aclk,
    input logic aresetn,
    input logic unsigned [31:0] awaddr,
    input logic unsigned [2:0] awsize,
    input logic unsigned [7:0] awlen,
    input logic unsigned [1:0] awburst,
    input logic awvalid,
    output logic awready,
    input logic unsigned [31:0] wdata,
    input logic wvalid,
    output logic wready,
    input logic wlast,
    output logic unsigned [1:0] bresp,
    output logic bvalid,
    input logic bready);
    logic unsigned [7:0] r_len = 8'h00;
    logic unsigned [1:0] r_burst = 2'b00;
    logic unsigned [7:0] r_did_it = 8'h00;
    logic unsigned [7:0] r_maxsize = 8'h00;
    logic r_aready = 1'b1;
    logic r_wenable = 1'b0;
    logic r_ready = 1'b0;
    logic r_bvalid = 1'b0;
    logic unsigned [15:0] r_realsaddr = 16'h0000;
    logic unsigned [7:0] r_offset = 8'h00;
    // A lot of VRAM is needed, as I will probably extend this to a vector processor of sorts
    logic unsigned [7:0] r_vram[65536] = '{default:{8'h00}};
    // AW ATTRIBUTES
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn | !awvalid)
            r_aready <= 1'b1;
        else if(awvalid & r_aready)
            r_aready <= 1'b0;
    end
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn)
            r_burst <= 2'b00;
        else if(awvalid & r_aready)
            r_burst <= awburst;
    end
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn)
            r_len <= 8'h00;
        else if(awvalid & r_aready)
            r_len <= awlen;
    end
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn)
            r_maxsize <= 8'h00;
        else if(awvalid & r_aready) begin
            unique case(awsize)
                3'b000: r_maxsize <= 8'h01;
                3'b001: r_maxsize <= 8'h02;
                3'b010: r_maxsize <= 8'h04;
                3'b011: r_maxsize <= 8'h08;
                3'b100: r_maxsize <= 8'h10;
                3'b101: r_maxsize <= 8'h20;
                3'b110: r_maxsize <= 8'h40;
                3'b111: r_maxsize <= 8'h80;
            endcase
        end
    end
    // ADDRESSING
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn)
            r_realsaddr <= 16'h0000;
        else if(awvalid & r_aready)
            r_realsaddr <= awaddr[15:0];
    end
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn)
            r_offset <= 8'h00;
        else if(wvalid & r_ready & (r_did_it < r_maxsize)) begin
            priority casez(r_burst)
            // FIXED
                2'b00: r_offset <= 8'h00;
            // INCR
                2'b01: begin
                    if(r_offset < r_maxsize)
                        r_offset <= r_offset + 8'h01;
                end
            // WRAP
                2'b1z: begin
                    if(r_offset < r_maxsize)
                        r_offset <= r_offset + 8'h01;
                    else
                        r_offset <= 8'h00;
                end
            endcase
        end
    end
    // W ATTRIBUTES
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn | wlast)
            r_wenable <= 1'b0;
        else
            r_wenable <= r_ready;
    end
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn)
            r_did_it <= 8'h00;
        else if(wvalid & r_ready & (r_did_it < r_maxsize))
            r_did_it <= r_did_it + 8'h01;
    end
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn | wlast)
            r_ready <= 1'b0;
        else if(wvalid)
            r_ready <= 1'b1;
    end
    // B ATTRIBUTES
    always_ff@(posedge aclk or negedge aresetn) begin
        if(!aresetn | bready)
            r_bvalid <= 1'b0;
        else if(wvalid)
            r_bvalid <= 1'b1;
    end
endmodule: viexo_axi4