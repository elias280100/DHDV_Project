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
    logic [3:0] debug;

    parameter bit [31:0] POLY = 32'h04C11DB7;     //Ethernet 32 Polynomial
    //parameter bit [31:0] POLY = 32'hEDB88320;     //Ethernet 32 Polynomial reflected
    parameter bit [31:0] final_crc = 32'h00000000;
    parameter bit [31:0] init= 32'hffffffff;
    

    always_ff @(posedge clk) begin
        if (reset) begin
            crc <= init;
            
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
                crc_next[0] = crc_prev[31] ^ data_in[7 - i];            //just if MSB == 1 data is xored with Poly -> information stored in crc_next[0]
                for (int j = 1; j < 32; j++) begin
                    if (POLY[j] == 1) begin                             //crc_next xored whenever Poly == 1
                    crc_next[j] = crc_prev[j - 1] ^ crc_prev[31] ^ data_in[7 - i];
                    end 
                    else begin                                          //just normal shift
                        crc_next[j] = crc_prev[j - 1];
                    end
                end
                crc_prev = crc_next;
            end
            
        end
    endgenerate

endmodule
