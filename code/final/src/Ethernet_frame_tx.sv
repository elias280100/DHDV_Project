`timescale 1 ps / 1 ps
typedef enum {
    IDLE_TX,           //0
    PREAMBLE_TX,       //1
    SFD_TX,            //2
    MAC_DEST_TX,       //3
    MAC_SOURCE_TX,     //4
    TYPE_TX,           //5
    LENGTH_TX,         //6
    PAYLOAD_TX,        //7
    PAD_TX,            //8
    FCS_TX,            //9
    IPG_TX             //10
    } State_tx;


//Ethernet 2
module Ethernet_frame_gen (
    input clk,
    input reset,
    input start,
    input logic [47:0] MAC_dest_addr,       //6 Bytes    
    input logic [47:0] MAC_source_addr,     //6 Bytes
    input logic [15:0] ethernet_type,       //2 Bytes
    input logic [11999:0] payload,            //1500 Bytes
    input logic [10:0] payload_length,      //11 Bytes -> max. payload length of 2048 Bytes

    output logic [7:0] tx_data,             //transmit 8 Bytes
    output logic tx_valid,
    output logic frame_done

); 
    //Counter
    logic [2:0] cnt_preamble;
    logic [2:0] cnt_MAC_dest;
    logic [2:0] cnt_MAC_source;
    logic cnt_ethernet_type;
    logic [10:0] cnt_payload;      
    logic [5:0] cnt_pad;
    logic [1:0] cnt_fcs;
    logic [3:0] cnt_ipg;

    logic [10:0] MAX_payload;       //max value of payload (= payload_lentgh)

    parameter [31:0] POLY = 32'h04C11DB7;     //Ethernet 32 Polynomial
    //parameter bit [31:0] POLY = 32'hEDB88320;     //Ethernet 32 Polynomial reflected
    parameter [31:0] final_crc = 32'h00000000;
    parameter [31:0] init = 32'hffffffff;

    logic [31:0] CRC32_crc;
    logic [7:0] CRC32_data;
    logic CRC32_valid;

    //Instantiate CRC32
    CRC32 #(
        .POLY(POLY),
        .final_crc(final_crc),
        .init(init)
    )
    CRC32_tx (
        .clk(clk),
        .reset(reset),
        .data_in(CRC32_data),
        .valid(CRC32_valid),
        .crc_out(CRC32_crc)
    );

    State_tx state, next_state;

    always_ff @(posedge clk) begin
        if (reset == 1'b1) begin
            state <= IDLE_TX;
        end
        else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk) begin
            if (reset == 1'b1) begin
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
                //counter PREAMBLE
                if (state == PREAMBLE_TX) begin
                    cnt_preamble++;
                end
                else if (next_state == PREAMBLE_TX) begin
                    cnt_preamble <= 3'b000;
                end
                //SFD
                if (state == SFD_TX) begin
                end
                //counter MAC Dest
                if (state == MAC_DEST_TX) begin
                    cnt_MAC_dest++;
                end
                else if (next_state == MAC_DEST_TX) begin
                    cnt_MAC_dest <= 6'b000000;;
                end
                //counter MAC Source
                if (state == MAC_SOURCE_TX) begin
                    cnt_MAC_source++;
                end
                else if (next_state == MAC_SOURCE_TX) begin
                    cnt_MAC_source <= 6'b000000;;
                end
                //counter TYPE
                if (state == TYPE_TX) begin
                    cnt_ethernet_type++;
                end
                else if (next_state == TYPE_TX) begin
                    cnt_ethernet_type <= 1'b0;
                end
                //counter PAYLOAD
                if (state == PAYLOAD_TX) begin
                    cnt_payload++;
                end
                else if (next_state == PAYLOAD_TX) begin
                    cnt_payload <= 11'b00000000000;
                end
                //counter PAD
                if (state == PAD_TX) begin
                    cnt_pad++;
                end
                else if (next_state == PAD_TX) begin
                    cnt_pad <= 6'b000000;
                end
                //counter FCS
                if (state == FCS_TX) begin
                    cnt_fcs++;
                end
                else if (next_state == FCS_TX) begin
                    cnt_fcs <= 2'b00;
                end
                //counter IPG
                if (state == IPG_TX) begin
                    // end
                    cnt_ipg++;
                end
                else if (next_state == IPG_TX) begin
                    cnt_ipg <= 4'b0000;
                end
            end
        end


    always_comb begin : FSM_ethernet_frame_tx
        case (state)
            IDLE_TX: begin
                tx_data = 8'd0;
                frame_done = 1'b0;
                CRC32_valid = 1'b0;
                next_state = (start == 1'b1) ? PREAMBLE_TX : IDLE_TX;   //next state if start signal is set
            end

            PREAMBLE_TX: begin 
                //Preamble 7 Bytes of hex 55
                tx_valid = 1'b1;
                tx_data = 8'h55; 
                next_state = (cnt_preamble == 3'b110) ? SFD_TX : PREAMBLE_TX;
            end

            SFD_TX: begin
                //transmit start delimiter
                tx_data = 8'hAB; 
                next_state = MAC_DEST_TX;
            end

            MAC_DEST_TX: begin                              
                CRC32_valid = 1'b1;
                tx_data = MAC_dest_addr[47 - cnt_MAC_dest*8 -: 8];     //transmit 6 Bytes 
                CRC32_data = MAC_dest_addr[47 - cnt_MAC_dest*8 -: 8];   //transmit 6 Bytes to CRC32 
                next_state = (cnt_MAC_dest == 3'b101) ? MAC_SOURCE_TX : MAC_DEST_TX; //next state if 6 Bytes are transmitted
                
            end

            MAC_SOURCE_TX: begin                              
                tx_data = MAC_source_addr[47 - cnt_MAC_source*8 -: 8];     //transmit 6 Bytes
                CRC32_data = MAC_source_addr[47 - cnt_MAC_source*8 -: 8];   //transmit 6 Bytes to CRC32
                next_state = (cnt_MAC_source == 3'b101) ? TYPE_TX : MAC_SOURCE_TX; //next state if 6 Bytes are transmitted
                
            end

            TYPE_TX: begin
                tx_data = ethernet_type[15 - cnt_ethernet_type*8 -: 8];     //transmit 2 Bytes
                CRC32_data = ethernet_type[15 - cnt_ethernet_type*8 -: 8];  
                next_state = (cnt_ethernet_type == 1'b1) ? PAYLOAD_TX : TYPE_TX;
            end

            PAYLOAD_TX: begin      
                tx_data = payload[(payload_length*8) - 1 - cnt_payload*8 -: 8];  //transmit Bytes of payload
                CRC32_data = payload[(payload_length*8) - 1 - cnt_payload*8 -: 8];   
                if (cnt_payload == payload_length-1) begin
                    // next_state = ((14+payload_length)*8 < 512) ? PAD : FCS;  //next state PAD if not enough Bytes (64) are in payload, otherwise FCS
                    next_state = ((14+payload_length)*8 < 10) ? PAD_TX : FCS_TX; //for testing
                end
                else begin
                    next_state = PAYLOAD_TX;
                end
            end

            PAD_TX: begin               //Ensure minimum frame size of 64 bytes 
                tx_data = 8'h00;
                CRC32_data = 8'h00;
                // next_state = ((14 + payload_length + cnt_pad)*8 >= 512) ? FCS : PAD;
                next_state = ((14 + payload_length + cnt_pad)*8 >= 10) ? FCS_TX : PAD_TX;     //for testing
            end

            FCS_TX: begin
                CRC32_valid = 1'b0;
                tx_data = CRC32_crc[31 - cnt_fcs*8 -: 8];      //transmit 4 Bytes CRC32
                next_state = (cnt_fcs == 2'b11) ? IPG_TX : FCS_TX;
            end

            IPG_TX : begin
                //transmit 12 Bytes of hex 00 after 1 frame
                tx_data = 8'h00;
                tx_valid = 1'b0;
                if (cnt_ipg == 4'b1011) begin
                    frame_done = 1'b1;
                end
                next_state = (cnt_ipg == 4'b1011) ? IDLE_TX : IPG_TX;
            end

            default tx_data <= 'x;
   
        endcase
    end

endmodule
