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

    output logic [7:0] tx_data,
    output logic frame_done,

); 

    logic [2:0] cnt_preamble;
    logic [2:0] cnt_MAC_dest;
    logic [2:0] cnt_MAC_source;
    logic [10:0] cnt_payload;      //max 1500 Bytes Payload
    logic [10:0] MAX_payload;       //max value of payload (= payload_lentgh)

    always_ff @(posedge clock) begin
            if (reset == 1'b1) begin
                state <= idle;
            end 
            else begin
                state <= next_state;
            end
        end


    always_comb begin : FSM_ethernet_frame
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
                if (cnt_preamble == 3'b110) begin
                    cnt_preamble <= 3'b0;
                    next_state <= SFD;
                end
            end

            SFD begin
                tx_data <= 8'hAB;           //Standard 10101011
                next_state <= MAC_DEST;
            end

            MAC_DEST begin                              //was passiert mit ungenutzten states? was ist standard hierfür?
                case (cnt_MAC_dest) //das hier vllt auch ohne case und wie unten bei payload machen 
                    3'b000: tx_data <= MAC_dest_addr[47:40];
                    3'b001: tx_data <= MAC_dest_addr[39:32];
                    3'b010: tx_data <= MAC_dest_addr[31:24];
                    3'b011: tx_data <= MAC_dest_addr[23:16];
                    3'b100: tx_data <= MAC_dest_addr[15:8];
                    3'b101: tx_data <= MAC_dest_addr[7:0];
                    default tx_data <= 'x';
                endcase
                cnt_MAC_dest++;
                if (cnt_MAC_dest == 3'b101) begin
                    cnt_MAC_dest <= 3'b000;
                    next_state <= MAC_DEST;
                end
            end

            MAC_SOURCE begin                              //was passiert mit ungenutzten states? was ist standard hierfür?
                case (cnt_MAC_source) 
                    3'b000: tx_data <= MAC_source_addr[47:40];
                    3'b001: tx_data <= MAC_source_addr[39:32];
                    3'b010: tx_data <= MAC_source_addr[31:24];
                    3'b011: tx_data <= MAC_source_addr[23:16];
                    3'b100: tx_data <= MAC_source_addr[15:8];
                    3'b101: tx_data <= MAC_source_addr[7:0];
                    default tx_data <= 'x';
                endcase
                MAC_source_addr++;
                if (MAC_source_addr == 3'b101) begin
                    cnt_MAC_source <= 3'b000;
                    next_state <= LENGTH;
                end
            end

            LENGTH begin        //was mache ich hier?
                MAX_payload <= payload_length;
                next_state <= PAYLOAD;
            end

            PAYLOAD begin
                tx_data <= payload[(MAX_payload - cnt_payload*8) : ((MAX_payload - cnt_payload*8) -8)];
                if (cnt_payload == 11'h5DB) begin           //counter = 1499
                    cnt_payload <= 11'b0;
                    next_state <= PAD;
                end
                else begin
                    cnt_payload++;
                end
            end

            PAD begin               //Minimum Größe von 64 bytes sicherstellen
                if (MAX_payload < 11'd6) begin
                    //Padding
                    tx_data <= 8'h00;
                end
                


            
        endcase
    end

endmodule
