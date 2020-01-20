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
    input logic unsigned [11:0] wputhere,
    input logic unsigned [7:0] wput_c,
    output logic unsigned [7:0] red,
    output logic unsigned [7:0] grn,
    output logic unsigned [7:0] blu);
    wire logic unsigned [127:0] r_char_data;
    wire logic unsigned [7:0] r_char_pos;
    logic unsigned [11:0] r_curr_i_cursor = 12'h000;
    logic r_char_currdata = 1'b0;
    
    always_ff@(posedge pclk or negedge aresetn) begin: viexo_fontrom_put_cursor
        if(!aresetn)
            r_curr_i_cursor <= 12'h000;
        else
            r_curr_i_cursor <= (((y >> 4) * 80) + (x >> 3));
    end: viexo_fontrom_put_cursor
    
       xpm_memory_spram #(
          .ADDR_WIDTH_A(12),              // DECIMAL
          .AUTO_SLEEP_TIME(0),           // DECIMAL
          .BYTE_WRITE_WIDTH_A(8),       // DECIMAL
          .CASCADE_HEIGHT(0),            // DECIMAL
          .ECC_MODE("no_ecc"),           // String
          .MEMORY_INIT_FILE("none"),     // String
          .MEMORY_INIT_PARAM("0"),       // String
          .MEMORY_OPTIMIZATION("true"),  // String
          .MEMORY_PRIMITIVE("block"),     // String
          .MEMORY_SIZE(19200),            // DECIMAL
          .MESSAGE_CONTROL(0),           // DECIMAL
          .READ_DATA_WIDTH_A(8),        // DECIMAL
          .READ_LATENCY_A(1),            // DECIMAL
          .READ_RESET_VALUE_A("00"),      // String
          .RST_MODE_A("SYNC"),           // String
          .SIM_ASSERT_CHK(0),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
          .USE_MEM_INIT(1),              // DECIMAL
          .WAKEUP_TIME("disable_sleep"), // String
          .WRITE_DATA_WIDTH_A(8),       // DECIMAL
          .WRITE_MODE_A("read_first")    // String
       )
       xpm_memory_spram_inst (
          .dbiterra(),             // 1-bit output: Status signal to indicate double bit error occurrence
                                           // on the data output of port A.
    
          .douta(r_char_pos),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
          .sbiterra(),             // 1-bit output: Status signal to indicate single bit error occurrence
                                           // on the data output of port A.
    
          .addra(wen ? wputhere : r_curr_i_cursor),                   // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
          .clka(aclk),                     // 1-bit input: Clock signal for port A.
          .dina(wput_c),                     // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
          .ena(1'b1),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                           // cycles when read or write operations are initiated. Pipelined
                                           // internally.
    
          .injectdbiterra(1'b0), // 1-bit input: Controls double bit error injection on input data when
                                           // ECC enabled (Error injection capability is not available in
                                           // "decode_only" mode).
    
          .injectsbiterra(1'b0), // 1-bit input: Controls single bit error injection on input data when
                                           // ECC enabled (Error injection capability is not available in
                                           // "decode_only" mode).
    
          .regcea(1'b1),                 // 1-bit input: Clock Enable for the last register stage on the output
                                           // data path.
    
          .rsta(!aresetn),                     // 1-bit input: Reset signal for the final port A output register stage.
                                           // Synchronously resets output port douta to the value specified by
                                           // parameter READ_RESET_VALUE_A.
    
          .sleep(1'b0),                   // 1-bit input: sleep signal to enable the dynamic power saving feature.
          .wea(wen)                        // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                           // for port A input data port dina. 1 bit wide when word-wide writes are
                                           // used. In byte-wide write configurations, each bit controls the
                                           // writing one byte of dina to address addra. For example, to
                                           // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                           // is 32, wea would be 4'b0010.
    
       );
    
    always_ff@(posedge pclk or negedge aresetn) begin: viexo_fontrom_putc_shift
        if(!aresetn)
            r_char_currdata <= 1'b0;
        else if(!wen)
            r_char_currdata <= r_char_data[(128 - ((y % 16) << 3)) + (8 - (x % 8))];
    end: viexo_fontrom_putc_shift
    
    xpm_memory_sprom #(
      .ADDR_WIDTH_A(8),              // DECIMAL
      .AUTO_SLEEP_TIME(0),           // DECIMAL
      .CASCADE_HEIGHT(0),            // DECIMAL
      .ECC_MODE("no_ecc"),           // String
      .MEMORY_INIT_FILE("spleen8x16.final.mem"),     // String
      .MEMORY_INIT_PARAM(""),       // String
      .MEMORY_OPTIMIZATION("true"),  // String
      .MEMORY_PRIMITIVE("auto"),     // String
      .MEMORY_SIZE(24576),            // DECIMAL
      .MESSAGE_CONTROL(0),           // DECIMAL
      .READ_DATA_WIDTH_A(128),        // DECIMAL
      .READ_LATENCY_A(0),            // DECIMAL
      .READ_RESET_VALUE_A("0"),      // String
      .RST_MODE_A("SYNC"),           // String
      .SIM_ASSERT_CHK(0),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_MEM_INIT(1),              // DECIMAL
      .WAKEUP_TIME("disable_sleep")  // String
   )
   xpm_memory_sprom_inst (
      .dbiterra(),             // 1-bit output: Leave open.
      .douta(r_char_data),                   // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .sbiterra(),             // 1-bit output: Leave open.
      .addra(r_char_pos),                   // ADDR_WIDTH_A-bit input: Address for port A read operations.
      .clka(pclk),                     // 1-bit input: Clock signal for port A.
      .ena(1'b1),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read operations are initiated. Pipelined internally.

      .injectdbiterra(1'b0), // 1-bit input: Do not change from the provided value.
      .injectsbiterra(1'b0), // 1-bit input: Do not change from the provided value.
      .regcea(1'b1),                 // 1-bit input: Do not change from the provided value.
      .rsta(!aresetn),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .sleep(1'b0)                    // 1-bit input: sleep signal to enable the dynamic power saving feature.
   );
   assign red = (!r_char_currdata ? 8'hFF : 8'h00);
   assign grn = (!r_char_currdata ? 8'hFF : 8'h00);
   assign blu = 8'h00;
endmodule: viexo_fontrom