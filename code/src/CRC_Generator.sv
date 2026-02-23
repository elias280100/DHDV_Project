`timescale 1ns/1ps
module CRC32 (
    input clk,
    input reset,
    input [7:0] data_in,
    input valid,

    output [31:0] crc_out
);

    logic [31:0] crc;
    logic [31:0] crc_prev;
    logic [31:0] crc_next;

    parameter bit [31:0] POLY = 32'h04C11DB7;     //Ethernet 32 Polynomial
    parameter bit [31:0] final_crc = 32'hffffffff;

    always_ff @(posedge clk) begin
        if (reset) begin
            crc <= 32'h0;
        end
        else begin
            if (valid) begin
                crc <= crc_next;
            end
        end
    end

    assign crc_out = crc ^ final_crc;

    generate;
        always_comb begin
            crc_next = crc;
            crc_prev = crc;
            for (int i = 0; i < 8; i++) begin
                crc_next[0] = crc_prev[31] ^ data_in[7 - i];
                for (int j = 1; j < 31; j++) begin
                    if (POLY[j] == 1) begin
                    crc_next[j] = crc_prev[j - 1] ^ crc_prev[31] ^ data_in[7 - 1];
                    end 
                    else begin
                        crc_next[j] = crc_prev[j - 1];
                    end
                end
                crc_prev = crc_next;
            end
        end
    endgenerate

endmodule
