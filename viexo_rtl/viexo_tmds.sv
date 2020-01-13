// Crude TMDS transmitter
`timescale 1ns / 1ps
module viexo_tmds
   (input logic aclk,
    input logic aresetn,
    // SEE: TMDS Protocol
    // Data Enable
    input logic de,

    // Control Signalling
    input logic unsigned [1:0] c,

    // Data
    input logic unsigned [7:0] d,

    // A TMDS encode lane
    output logic channel);
    // Declare as a 12-bit so we can cram it into a few LUT6s
    logic signed [11:0] r_cnt = 12'h0000;
    logic unsigned [1:0] r_chkpopcnt = 2'b00;
    logic unsigned [9:0] r_q_out = 10'b00000_00000;
    logic unsigned [9:0] r_which_onehot = 10'b00000_00001;
    // Also we need a PopCount for the TMDS bitdata
    logic unsigned [2:0] r_popcnt_input = 3'b000;
    logic signed [2:0] r_popcnt_qmp = 3'b000;
    logic signed [2:0] r_popcnt_qmn = 3'b000;
    logic unsigned [8:0] r_q_m = 9'b0000_00000;
    logic r_channel = 1'b0;
    // ------------------------
    // CONTROL FLOW LOGIC
    // ------------------------
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_tmds_popcnt_input
        if(!aresetn)
            r_popcnt_input <= 3'b000;
        else if(r_which_onehot[0])
            r_popcnt_input <= {1'b0, ({1'b0, d[7]} + {1'b0, d[6]})} +
                              {1'b0, ({1'b0, d[5]} + {1'b0, d[4]})} +
                              {1'b0, ({1'b0, d[3]} + {1'b0, d[2]})} + 
                              {1'b0, ({1'b0, d[1]} + {1'b0, d[0]})};
    end: viexo_tmds_popcnt_input
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_tmds_popcnt_qmp
        if(!aresetn)
            r_popcnt_qmp <= 3'b000;
        else if(r_which_onehot[8])
            r_popcnt_qmp <=  {1'b0, ({1'b0, r_q_m[7]} + {1'b0, r_q_m[6]})} +
                            {1'b0, ({1'b0, r_q_m[5]} + {1'b0, r_q_m[4]})} +
                            {1'b0, ({1'b0, r_q_m[3]} + {1'b0, r_q_m[2]})} + 
                            {1'b0, ({1'b0, r_q_m[1]} + {1'b0, r_q_m[0]})};
    end: viexo_tmds_popcnt_qmp
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_tmds_popcnt_qmn
        if(!aresetn)
            r_popcnt_qmn <= 3'b000;
        else if(r_which_onehot[8])
            r_popcnt_qmn <= {1'b0, ({1'b0, ~r_q_m[7]} + {1'b0, ~r_q_m[6]})} +
                            {1'b0, ({1'b0, ~r_q_m[5]} + {1'b0, ~r_q_m[4]})} +
                            {1'b0, ({1'b0, ~r_q_m[3]} + {1'b0, ~r_q_m[2]})} + 
                            {1'b0, ({1'b0, ~r_q_m[1]} + {1'b0, ~r_q_m[0]})};
    end: viexo_tmds_popcnt_qmn
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_tmds_check_popcnts
        if(!aresetn)
            r_chkpopcnt <= 2'b00;
        else if(r_which_onehot[1])
            r_chkpopcnt <= {((r_cnt == signed'(12'h000)) | (r_popcnt_qmp == r_popcnt_qmn)),
                            ((r_cnt > signed'(12'h000)) & (r_popcnt_qmp > r_popcnt_qmn)) | ((r_cnt < signed'(12'h000)) & (r_popcnt_qmn > r_popcnt_qmp))};
    end: viexo_tmds_check_popcnts
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_tmds_airfry_qm
        if(!aresetn)
            r_q_out <= 10'b00000_00000;
        else if(r_which_onehot[9]) begin
            if(de)
                if(r_chkpopcnt[1])
                    r_q_out <= {~r_q_m[8], r_q_m[8], (r_q_m[8] ? r_q_m[7:0] : ~r_q_m[7:0])};
                else if(r_chkpopcnt[0])
                    r_q_out <= {1'b1, r_q_m[8], ~r_q_m[7:0]};
                else
                    r_q_out <= {1'b0, r_q_m[8:0]};
            else unique case(c)
                2'b00: r_q_out <= 10'b0010101011;
                2'b01: r_q_out <= 10'b1101010100;
                2'b10: r_q_out <= 10'b0010101010;
                2'b11: r_q_out <= 10'b1101010101;
            endcase
        end
    end: viexo_tmds_airfry_qm
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_tmds_nofeed_qm
        if(!aresetn)
            r_q_m <= 9'b0000_00000;
        else if(r_which_onehot[7]) begin
            if(((r_popcnt_input == 3'h4) & ~d[0]) | (r_popcnt_input > 3'h4))
                r_q_m <= {
                    d[0],
                    d[1] ~^ d[0],
                    d[2] ~^ d[1],
                    d[3] ~^ d[2],
                    d[4] ~^ d[3],
                    d[5] ~^ d[4],
                    d[6] ~^ d[5],
                    d[7] ~^ d[6],
                    1'b0
                };
            else
                r_q_m <= {
                    d[0],
                    d[1] ^ d[0],
                    d[2] ^ d[1],
                    d[3] ^ d[2],
                    d[4] ^ d[3],
                    d[5] ^ d[4],
                    d[6] ^ d[5],
                    d[7] ^ d[6],
                    1'b1
                };
        end
    end: viexo_tmds_nofeed_qm
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_tmds_count_and_breathe
        if(!aresetn | ~de)
            r_cnt <= 12'h000;
        else if(r_which_onehot[9]) begin
            if(r_chkpopcnt[1])
                if(r_q_m[8])
                    r_cnt <= r_cnt + ({9'h000, r_popcnt_qmp} - {9'h000, r_popcnt_qmn});
                else
                    r_cnt <= r_cnt + ({9'h000, r_popcnt_qmn} - {9'h000, r_popcnt_qmp});
            else
                if(r_chkpopcnt[0])
                    r_cnt <= r_cnt - (r_q_m[8] ? 12'h000 : 12'h002) + ({9'h000, r_popcnt_qmp} - {9'h000, r_popcnt_qmn});
                else
                    r_cnt <= r_cnt + (r_q_m[8] ? 12'h002 : 12'h000) + ({9'h000, r_popcnt_qmn} - {9'h000, r_popcnt_qmp});
        end
    end: viexo_tmds_count_and_breathe
    // ------------------------
    // ONE HOT MASTER
    // ------------------------
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_tmds_onehot_encoder
        if(!aresetn | r_which_onehot[9])
            r_which_onehot <= 10'b00000_00001;
        else
            r_which_onehot <= r_which_onehot << 1;
    end: viexo_tmds_onehot_encoder
    always_ff@(posedge aclk or negedge aresetn) begin: viexo_tmds_onehot_master
        if(!aresetn)
            r_channel <= 1'b0;
        else priority casez(r_which_onehot)
            10'b00000_00001: r_channel <= r_q_out[0];
            10'b00000_0001z: r_channel <= r_q_out[1];
            10'b00000_001zz: r_channel <= r_q_out[2];
            10'b00000_01zzz: r_channel <= r_q_out[3];
            10'b00000_1zzzz: r_channel <= r_q_out[4];
            10'b00001_zzzzz: r_channel <= r_q_out[5];
            10'b0001z_zzzzz: r_channel <= r_q_out[6];
            10'b001zz_zzzzz: r_channel <= r_q_out[7];
            10'b01zzz_zzzzz: r_channel <= r_q_out[8];
            10'b1zzzz_zzzzz: r_channel <= r_q_out[9];
        endcase
    end: viexo_tmds_onehot_master
    assign channel = r_channel;
endmodule: viexo_tmds