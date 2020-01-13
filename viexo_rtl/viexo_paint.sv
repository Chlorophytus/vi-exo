// Crude paintbuffer
`timescale 1ns / 1ps
module viexo_paint
   (input logic aclk,
    input logic aresetn,
    output logic hblank,
    output logic hsync,
    output logic vblank,
    output logic vsync,
    output logic unsigned [11:0] x,
    output logic unsigned [11:0] y);
    logic unsigned [11:0] r_x = 12'h000;
    logic unsigned [11:0] r_y = 12'h000;
    logic r_vblank = 1'b0;
    logic r_hblank = 1'b0;
    logic r_hsync = 1'b0;
    logic r_vsync = 1'b0;
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_paint_x
        if(!aresetn | r_x > 12'd800)
            r_x <= 12'h000;
        else
            r_x <= r_x + 12'h001;
    end: viexo_paint_x
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_paint_hblank
        if(!aresetn | ~|r_x)
            r_hblank <= 1'b0;
        else if(r_x == 12'd640)
            r_hblank <= 1'b1;
    end: viexo_paint_hblank    
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_paint_hsync
        if(!aresetn | r_x == 12'd720)
            r_hsync <= 1'b0;
        else if(r_x == 12'd664)
            r_hsync <= 1'b1;
    end: viexo_paint_hsync

    always_ff@(posedge aclk or negedge aresetn) begin: viexo_paint_y
        if(!aresetn | r_y > 12'd500)
            r_y <= 12'h000;
        else if(~|r_x)
            r_y <= r_y + 12'h001;
    end: viexo_paint_y
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_paint_vblank
        if(!aresetn | ~|r_y)
            r_vblank <= 1'b0;
        else if(r_y == 12'd480)
            r_vblank <= 1'b1;
    end: viexo_paint_vblank
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_paint_vsync
        if(!aresetn | r_y == 12'd487)
            r_vsync <= 1'b0;
        else if(r_y == 12'd483)
            r_vsync <= 1'b1;
    end: viexo_paint_vsync
    
    assign x = r_x;
    assign y = r_y;
    assign vblank = r_vblank;
    assign vsync = r_vsync;
    assign hblank = r_hblank;
    assign hsync = r_hsync;
endmodule: viexo_paint