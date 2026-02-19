typedef enum {
    IDLE, 
    PREAMBLE, 
    SFD, 
    MAC_DEST, 
    MAC_SOURCE, 
    LENGTH, 
    PAYLOAD, 
    PAD, 
    FCS
    } State;

module Ethernet_frame_gen (
    input clk,
    input reset,
    input start,
    input [47:0] MAC_dest_addr,
    input [47:0] MAC_source_addr,
    input [15:0] ethernet_type,
    input [10:0] payload_length,
    input [7:0] payload [0:1499],       //1500 Bytes

    output reg [7:0] tx_data,
    output reg frame_done,

); 

    reg [2:0] cnt_preamble;
    reg [2:0] cnt_MAC_dest;
    reg [2:0] cnt_MAC_source;

    always_ff @(posedge clock) begin
            if (reset == 1'b1) begin
                state <= idle;
            end 
            else begin
                state <= next_state;
            end
        end


    always_comb begin : FSM
        case (state)
            IDLE begin
                tx_data <= 8'd0;
                if (start == 1'b0) begin
                    next_state <= PREAMBLE;
                end
            end

            PREAMBLE begin 
                tx_data <= 8'h55;               //alternating pattern of binary 56 ones and zeroes
                cnt_preamble++;
                if (cnt_preamble == 6) begin
                    next_state <= SFD;
                end
            end

            SFD begin
                tx_data <= 8'hAB;           //Standard 10101011
                next_state <= MAC_DEST;
            end


            
        endcase
    end

endmodule
