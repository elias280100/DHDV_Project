typedef enum {
    IDLE, 
    PREAMBLE, 
    SFD, 
    MAC_DEST, 
    MAC_SOURCE, 
    LENGTH, 
    PAYLOAD, 
    PAD, 
    FCS,
    IPG
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

    //CRC Generator
    input logic [31:0] CRC32_crc,
    output logic [7:0] CRC32_data,
    output logic CRC32_valid,

    output logic [7:0] tx_data,
    //brauche ich ein tx_valid?
    output logic frame_done,

); 

    logic [2:0] cnt_preamble;
    logic [2:0] cnt_MAC_dest;
    logic [2:0] cnt_MAC_source;
    logic [10:0] cnt_payload;      //max 1500 Bytes Payload
    logic [5:0] cnt_pad;
    logic [1:0] cnt_fcs;
    logic [3:0] cnt_ipg;

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
            IDLE: begin
                tx_data <= 8'd0;
                frame_done <= 1'b0;
                if (start == 1'b1) begin
                    next_state <= PREAMBLE;
                end
            end

            PREAMBLE: begin 
                start <= 1'b0;      //hier zurücksetzen?
                tx_data <= 8'h55;               //alternating pattern of binary 56 ones and zeroes
                cnt_preamble++;
                if (cnt_preamble == 3'b110) begin
                    cnt_preamble <= 3'b0;
                    next_state <= SFD;
                end
            end

            SFD: begin
                tx_data <= 8'hAB;           //Standard 10101011
                next_state <= MAC_DEST;
            end

            MAC_DEST: begin                              //was passiert mit ungenutzten states? was ist standard hierfür?
                case (cnt_MAC_dest) //das hier vllt auch ohne case und wie unten bei payload machen 
                    3'b000: begin
                        tx_data <= MAC_dest_addr[47:40];
                        CRC32_valid <= 1'b1;
                        CRC32_data <= MAC_dest_addr[47:40];
                    end
                    3'b001: begin
                        tx_data <= MAC_dest_addr[39:32];
                        CRC32_data <= MAC_dest_addr[39:32];
                    end 
                    3'b010: begin
                        tx_data <= MAC_dest_addr[31:24];
                        CRC32_data <= MAC_dest_addr[31:24];
                    end
                    3'b011: begin
                        tx_data <= MAC_dest_addr[23:16];
                        CRC32_data <= MAC_dest_addr[23:16];
                    end
                    3'b100: begin
                        tx_data <= MAC_dest_addr[15:8];
                        CRC32_data <= MAC_dest_addr[15:8];
                    end
                    3'b101: begin
                        tx_data <= MAC_dest_addr[7:0];
                        CRC32_data <= MAC_dest_addr[7:0];
                    end
                    default tx_data <= 'x';
                endcase
                cnt_MAC_dest++;
                if (cnt_MAC_dest == 3'b101) begin
                    cnt_MAC_dest <= 3'b000;
                    CRC32_valid <= 1'b0;
                    next_state <= MAC_DEST;
                end
            end

            MAC_SOURCE: begin                              //was passiert mit ungenutzten states? was ist standard hierfür?
                case (cnt_MAC_source) 
                    3'b000: begin
                        tx_data <= MAC_source_addr[47:40];
                        CRC32_valid <= 1'b1;
                        CRC32_data <= MAC_source_addr[47:40];
                    end
                    3'b001: begin
                        tx_data <= MAC_source_addr[39:32];
                        CRC32_data <= MAC_source_addr[39:32];
                    end
                    3'b010: begin
                        tx_data <= MAC_source_addr[31:24];
                        CRC32_data <= MAC_source_addr[31:24];
                    end
                    3'b011: begin
                        tx_data <= MAC_source_addr[23:16];
                        CRC32_data <= MAC_source_addr[23:16];
                    end
                    3'b100: begin
                        tx_data <= MAC_source_addr[15:8];
                        CRC32_data <= MAC_source_addr[15:8];
                    end
                    3'b101: begin
                        tx_data <= MAC_source_addr[7:0];
                        CRC32_data <= MAC_source_addr[7:0];
                    end
                    default tx_data <= 'x';
                endcase
                MAC_source_addr++;
                if (MAC_source_addr == 3'b101) begin
                    cnt_MAC_source <= 3'b000;
                    CRC32_valid <= 1'b0;
                    next_state <= LENGTH;
                end
            end

            LENGTH: begin        //was mache ich hier?
                MAX_payload <= payload_length;
                next_state <= PAYLOAD;
            end

            PAYLOAD: begin      //stimmt die Reihenfolge der bytes hier? ich schicke MSB zuerst, passt das?
                //tx_data <= payload(MAX_payload - cnt_payload);  //MSB first
                tx_data <= payload(cnt_payload);          //LSB first
                CRC32_valid <= 1'b1;
                //CRC32_data <= payload(MAX_payload - cnt_payload);   //MSB first
                CRC32_data <= payload(cnt_payload);         //LSB first
                if (cnt_payload == MAX_payload) begin           
                    cnt_payload <= 11'b0;
                    CRC32_valid <= 1'b0;
                    next_state <= PAD;
                end
                else begin
                    cnt_payload++;
                end
            end

            PAD: begin               //Minimum frame Größe von 64 bytes sicherstellen
                if ((14 + MAX_payload + cnt_pad) < 11'd6) begin
                    tx_data <= 8'h00;
                    cnt_pad++;
                end
                else begin
                    cnt_pad <= 6'b0;
                    next_state <= FCS;
                end
            end

            FCS: begin
                tx_data <= CRC32_crc[(31 - cnt_fcs*8) : ((31 - cnt_fcs*8) -7)];
                if (cnt_fcs == 2'11) begin
                    cnt_fcs <= 2'b00;
                    next_state <= IPG;
                end
                else begin
                    cnt_fcs++;
                end
            end

            IPG : begin
                tx_data <= 8'h00;
                if (cnt_ipg == 4'b1011) begin       //12 bytes
                    cnt_ipg <= 4'b0000;
                    frame_done <= 1'b1;
                    next_state <= IDLE;
                end
                else begin
                    cnt_ipg++;
                end
            end

            default tx_data <= 'x';
   
        endcase
    end

endmodule
