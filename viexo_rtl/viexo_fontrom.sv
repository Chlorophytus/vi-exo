// Crude Font ROM, BSD Spleen font :)
`timescale 1ns / 1ps
module viexo_fontrom
   (// Clock for AXI.
    input logic aclk,
    // 23.75MHz then we cross clocks.
    input logic pclk,
    input logic aresetn,
    input logic unsigned [11:0] x,
    input logic unsigned [11:0] y,
    input logic wen,
    input logic unsigned [7:0] wput_x,
    input logic unsigned [7:0] wput_y,
    input logic unsigned [7:0] wput_c,
    output logic unsigned [7:0] red,
    output logic unsigned [7:0] grn,
    output logic unsigned [7:0] blu);
    logic unsigned [11:0] r_char_final_pos = 12'h000;
    logic unsigned [7:0] char_data = 8'h00;
    logic unsigned [7:0] r_char_final_raster[240] = '{default:{8'h00}};
    logic unsigned [7:0] r_char_raster[240] = '{default:{8'h00}};
    logic r_char_currdata = 1'b0;
    always_ff@(posedge pclk or negedge aresetn) begin: viexo_fontrom_finalize_pos
        if(!aresetn)
            r_char_final_pos <= 12'h000;
        else 
            // Bit-level foolery. Don't try at home.
            r_char_final_pos <= {r_char_final_raster[((wput_y % 30) * 80) + (wput_x % 80)], y[3:0]};
    end: viexo_fontrom_finalize_pos
    
    for(genvar i = 0; i < 240; i++) begin: viexo_fontrom_putc
        always_ff@(posedge aclk or negedge aresetn) begin: viexo_fontrom_putc_cache
            if(!aresetn)
                r_char_raster[i] <= 8'h00;
            else if(wen & i == (((wput_y % 30) * 80) + (wput_x % 80)))
                r_char_raster[i] <= wput_c;
        end: viexo_fontrom_putc_cache
        
        always_ff@(posedge aclk or negedge aresetn) begin: viexo_fontrom_putc_now
            if(!aresetn)
                r_char_final_raster[i] <= 8'h00;
            else if(!wen)
                r_char_final_raster[i] <= r_char_raster[i];
        end: viexo_fontrom_putc_now
    end: viexo_fontrom_putc
    
    always_ff@(posedge pclk or negedge aresetn) begin: viexo_fontrom_currdata_shift
        if(!aresetn)
            r_char_currdata <= 1'b0;
        else unique case(x[2:0])
            3'd0: r_char_currdata <= char_data[7];
            3'd1: r_char_currdata <= char_data[6];
            3'd2: r_char_currdata <= char_data[5];
            3'd3: r_char_currdata <= char_data[4];
            3'd4: r_char_currdata <= char_data[3];
            3'd5: r_char_currdata <= char_data[2];
            3'd6: r_char_currdata <= char_data[1];
            3'd7: r_char_currdata <= char_data[0];
        endcase
    end: viexo_fontrom_currdata_shift
    xpm_memory_sprom #(
      .ADDR_WIDTH_A(12),              // DECIMAL
      .AUTO_SLEEP_TIME(0),           // DECIMAL
      .CASCADE_HEIGHT(0),            // DECIMAL
      .ECC_MODE("no_ecc"),           // String
      .MEMORY_INIT_FILE("spleen8x16.mem"),     // String
      .MEMORY_INIT_PARAM(""),       // String
      .MEMORY_OPTIMIZATION("true"),  // String
      .MEMORY_PRIMITIVE("auto"),     // String
      .MEMORY_SIZE(3072),            // DECIMAL
      .MESSAGE_CONTROL(0),           // DECIMAL
      .READ_DATA_WIDTH_A(8),        // DECIMAL
      .READ_LATENCY_A(0),            // DECIMAL
      .READ_RESET_VALUE_A("0"),      // String
      .RST_MODE_A("ASYNC"),           // String
      .SIM_ASSERT_CHK(0),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_MEM_INIT(1),              // DECIMAL
      .WAKEUP_TIME("disable_sleep")  // String
   )
   xpm_memory_sprom_inst (
      .dbiterra(),             // 1-bit output: Leave open.
      .douta(char_data),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .sbiterra(),             // 1-bit output: Leave open.
      .addra(r_char_final_pos),                   // ADDR_WIDTH_A-bit input: Address for port A read operations.
      .clka(pclk),                     // 1-bit input: Clock signal for port A.
      .ena(1'b1),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.

      .injectdbiterra(1'b0), // 1-bit input: Do not change from the provided value.
      .injectsbiterra(1'b0), // 1-bit input: Do not change from the provided value.
      .regcea(1'b1),                 // 1-bit input: Do not change from the provided value.
      .rsta(aresetn),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .sleep(1'b0)                    // 1-bit input: sleep signal to enable the dynamic power saving feature.
   );
   assign red = (r_char_currdata ? 8'hFF : 8'h00);
   assign grn = (r_char_currdata ? 8'hFF : 8'h00);
   assign blu = (r_char_currdata ? 8'hFF : 8'h00);
endmodule: viexo_fontrom