`timescale 1 ps / 1 ps
typedef enum {
    IDLE, 
    PREAMBLE, 
    SFD, 
    MAC_DEST, 
    MAC_SOURCE,
    TYPE, 
    LENGTH, 
    PAYLOAD, 
    PAD, 
    FCS,
    IPG
    } State;


//Ethernet 2
module Ethernet_frame_gen (
    input clk,
    input reset,
    input start,
    // input [47:0] MAC_dest_addr,
    // input [47:0] MAC_source_addr,
    // input [15:0] ethernet_type,
    input [7:0] MAC_dest_addr [5:0],        //6 Bytes
    input [7:0] MAC_source_addr [5:0],      //6 Bytes
    input [7:0] ethernet_type [1:0],        //2 Bytes
    input [10:0] payload_length,
    input [7:0] payload [1499:0],       //1500 Bytes

    //CRC Generator
    input logic [7:0] CRC32_crc[3:0],       //4 Bytes
    output logic [7:0] CRC32_data,
    output logic CRC32_valid,

    output logic [7:0] tx_data,
    output logic tx_valid,
    //brauche ich ein tx_valid?
    output logic frame_done

); 
    //Counter
    logic [2:0] cnt_preamble;
    logic [2:0] cnt_MAC_dest;
    logic [2:0] cnt_MAC_source;
    logic cnt_ethernet_type;
    logic [10:0] cnt_payload;      //max 1500 Bytes Payload
    logic [5:0] cnt_pad;
    logic [1:0] cnt_fcs;
    logic [3:0] cnt_ipg;

    logic [10:0] MAX_payload;       //max value of payload (= payload_lentgh)

    State state, next_state;

    always_ff @(posedge clk) begin
            if (reset == 1'b1) begin
                state <= IDLE;
                cnt_ethernet_type <= 1'b0;
                cnt_fcs <= 2'b00;
                cnt_ipg <= 4'b0000;
                cnt_MAC_dest <= 6'b000000;
                cnt_MAC_source <= 6'b000000;
                cnt_pad <= 6'b000000;
                cnt_payload <= 11'b00000000000;
                cnt_preamble <= 3'b000;
            end 
            else begin
                state <= next_state;
                //counter PREAMBLE
                if (state == PREAMBLE) begin
                    cnt_preamble++;
                end
                else if (next_state == PREAMBLE) begin
                    cnt_preamble <= 3'b000;;
                end
                //counter MAC Dest
                if (state == MAC_DEST) begin
                    cnt_MAC_dest++;
                end
                else if (next_state == MAC_DEST) begin
                    cnt_MAC_dest <= 6'b000000;;
                end
                //counter MAC Source
                if (state == MAC_SOURCE) begin
                    cnt_MAC_source++;
                end
                else if (next_state == MAC_SOURCE) begin
                    cnt_MAC_source <= 6'b000000;;
                end
                //counter TYPE
                if (state == TYPE) begin
                    cnt_ethernet_type++;
                end
                else if (next_state == TYPE) begin
                    cnt_ethernet_type <= 1'b0;
                end
                //counter PAYLOAD
                if (state == PAYLOAD) begin
                    cnt_payload++;
                end
                else if (next_state == PAYLOAD) begin
                    cnt_payload <= 11'b00000000000;
                end
                //counter PAD
                if (state == PAD) begin
                    cnt_pad++;
                end
                else if (next_state == PAD) begin
                    cnt_pad <= 6'b000000;
                end
                //counter FCS
                if (state == FCS) begin
                    cnt_fcs++;
                end
                else if (next_state == FCS) begin
                    cnt_fcs <= 2'b00;
                end
                //counter IPG
                if (state == IPG) begin
                    cnt_ipg++;
                end
                else if (next_state == IPG) begin
                    cnt_ipg <= 4'b0000;
                end
            end
        end


    always_comb begin : FSM_ethernet_frame
        case (state)
            IDLE: begin
                tx_valid <= 1'b0;
                CRC32_valid <= 1'b0;
                tx_data <= 8'd0;
                frame_done <= 1'b0;
                if (start == 1'b1) begin
                    next_state <= PREAMBLE;
                end
            end

            PREAMBLE: begin 
                //start <= 1'b0;      //hier zurücksetzen?
                tx_valid <= 1'b1;
                tx_data <= 8'h55;               //alternating pattern of binary 56 ones and zeroes
                //cnt_preamble++;
                if (cnt_preamble == 3'b110) begin
                   // cnt_preamble <= 3'b0;
                    next_state <= SFD;
                end
            end

            SFD: begin
                tx_data <= 8'hAB;           //Standard 10101011
                next_state <= MAC_DEST;
            end

            MAC_DEST: begin                              //was passiert mit ungenutzten states? was ist standard hierfür?
                // case (cnt_MAC_dest) //das hier vllt auch ohne case und wie unten bei payload machen 
                //     3'b000: begin
                //         tx_data <= MAC_dest_addr[47:40];        //das hier ändern zu Bytes zuweisung
                //         CRC32_valid <= 1'b1;
                //         CRC32_data <= MAC_dest_addr[47:40];
                //     end
                //     3'b001: begin
                //         tx_data <= MAC_dest_addr[39:32];
                //         CRC32_data <= MAC_dest_addr[39:32];
                //     end 
                //     3'b010: begin
                //         tx_data <= MAC_dest_addr[31:24];
                //         CRC32_data <= MAC_dest_addr[31:24];
                //     end
                //     3'b011: begin
                //         tx_data <= MAC_dest_addr[23:16];
                //         CRC32_data <= MAC_dest_addr[23:16];
                //     end
                //     3'b100: begin
                //         tx_data <= MAC_dest_addr[15:8];
                //         CRC32_data <= MAC_dest_addr[15:8];
                //     end
                //     3'b101: begin
                //         tx_data <= MAC_dest_addr[7:0];
                //         CRC32_data <= MAC_dest_addr[7:0];
                //     end
                //     default tx_data <= 'x';
                // endcase
                tx_data <= MAC_dest_addr[5 - cnt_MAC_dest];     //MSB first
                CRC32_data <= MAC_dest_addr[5 - cnt_MAC_dest];
                if (cnt_MAC_dest == 3'b101) begin
                    //cnt_MAC_dest <= 3'b000;
                    //CRC32_valid <= 1'b0;
                    next_state <= MAC_SOURCE;
                end
                // else begin
                //     cnt_MAC_dest++;
                // end
            end

            MAC_SOURCE: begin                              //was passiert mit ungenutzten states? was ist standard hierfür?
                // case (cnt_MAC_source) 
                //     3'b000: begin
                //         tx_data <= MAC_source_addr[47:40];
                //         //CRC32_valid <= 1'b1;
                //         CRC32_data <= MAC_source_addr[47:40];
                //     end
                //     3'b001: begin
                //         tx_data <= MAC_source_addr[39:32];
                //         CRC32_data <= MAC_source_addr[39:32];
                //     end
                //     3'b010: begin
                //         tx_data <= MAC_source_addr[31:24];
                //         CRC32_data <= MAC_source_addr[31:24];
                //     end
                //     3'b011: begin
                //         tx_data <= MAC_source_addr[23:16];
                //         CRC32_data <= MAC_source_addr[23:16];
                //     end
                //     3'b100: begin
                //         tx_data <= MAC_source_addr[15:8];
                //         CRC32_data <= MAC_source_addr[15:8];
                //     end
                //     3'b101: begin
                //         tx_data <= MAC_source_addr[7:0];
                //         CRC32_data <= MAC_source_addr[7:0];
                //     end
                //     default tx_data <= 'x';
                // endcase
                tx_data <= MAC_source_addr[5 - cnt_MAC_source];     //MSB first
                CRC32_data <= MAC_source_addr[5 - cnt_MAC_source];
                if (cnt_MAC_source == 3'b101) begin
                    //cnt_MAC_source <= 3'b000;
                    //CRC32_valid <= 1'b0;
                    next_state <= TYPE;
                end
                // else begin
                //     cnt_MAC_source++;
                // end
            end

            TYPE: begin
                tx_data <= ethernet_type[1 - cnt_ethernet_type];
                CRC32_data <= ethernet_type[1 - cnt_ethernet_type];
                if (cnt_ethernet_type == 1'b1) begin
                    //cnt_ethernet_type <= 1'b0;
                    next_state <= LENGTH;
                end
                // else begin
                //     cnt_ethernet_type++;
                // end
            end

            LENGTH: begin        //was mache ich hier?
                MAX_payload <= payload_length;
                next_state <= PAYLOAD;
            end

            PAYLOAD: begin      //stimmt die Reihenfolge der bytes hier? ich schicke MSB zuerst, passt das?
                tx_data <= payload[MAX_payload - 1 - cnt_payload];  //MSB first
                //tx_data <= payload[cnt_payload];          //LSB first
                //CRC32_valid <= 1'b1;
                CRC32_data <= payload[MAX_payload - 1 - cnt_payload];   //MSB first
                //CRC32_data <= payload[cnt_payload];         //LSB first
                if (cnt_payload == MAX_payload - 2) begin           
                    //cnt_payload <= 11'b0;
                    CRC32_valid <= 1'b0;            //hier CRC32_valid zurücksetzen?
                    next_state <= PAD;
                end
                // else begin
                //     cnt_payload++;
                // end
            end

            PAD: begin               //Minimum frame Größe von 64 bytes sicherstellen
                if ((14 + MAX_payload + cnt_pad) < 11'd6) begin
                    tx_data <= 8'h00;
                    //cnt_pad++;
                end
                else begin
                    //cnt_pad <= 6'b0;
                    next_state <= FCS;
                end
            end

            FCS: begin
                // tx_data <= CRC32_crc[(31 - cnt_fcs*8) : ((31 - cnt_fcs*8) -7)];
                tx_data <= CRC32_crc[3 - cnt_fcs];      //MSB first
                if (cnt_fcs == 2'b11) begin
                    //cnt_fcs <= 2'b00;
                    next_state <= IPG;
                end
                // else begin
                //     cnt_fcs++;
                // end
            end

            IPG : begin
                tx_data <= 8'h00;
                if (cnt_ipg == 4'b1011) begin       //12 bytes
                    //cnt_ipg <= 4'b0000;
                    frame_done <= 1'b1;
                    next_state <= IDLE;
                end
                // else begin
                //     cnt_ipg++;
                // end
            end

            default tx_data <= 'x;
   
        endcase
    end

endmodule
