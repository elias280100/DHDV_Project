`timescale 1 ps / 1 ps
typedef enum {
    IDLE,           //0
    PREAMBLE,       //1
    SFD,            //2
    MAC_DEST,       //3
    MAC_SOURCE,     //4
    TYPE,           //5
    LENGTH,         //6
    PAYLOAD,        //7
    PAD,            //8
    FCS,            //9
    IPG             //10
    } State;


//Ethernet 2
module Ethernet_frame_gen (
    input clk,
    input reset,
    input start,
    input [47:0] MAC_dest_addr,      
    input [47:0] MAC_source_addr,
    input [15:0] ethernet_type,
    input [11999:0] payload,
    input [10:0] payload_length,
    // input [7:0] MAC_dest_addr [5:0],        //6 Bytes
    // input [7:0] MAC_source_addr [5:0],      //6 Bytes
    // input [7:0] ethernet_type [1:0],        //2 Bytes
    // input [10:0] payload_length,
    // input [7:0] payload [1499:0],       //1500 Bytes

    //CRC Generator
    //input logic [7:0] CRC32_crc[3:0],       

    // output logic [7:0] CRC32_data,
    // output logic CRC32_valid,

    output logic [7:0] tx_data,
    output logic tx_valid,
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

    parameter [31:0] POLY = 32'h04C11DB7;     //Ethernet 32 Polynomial
    //parameter bit [31:0] POLY = 32'hEDB88320;     //Ethernet 32 Polynomial reflected
    parameter [31:0] final_crc = 32'h00000000;
    parameter [31:0] init = 32'hffffffff;

    logic [31:0] CRC32_crc;
    logic [7:0] CRC32_data;
    logic CRC32_valid;


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

    State state, next_state;

    always_ff @(posedge clk) begin
        if (reset == 1'b1) begin
            state <= IDLE;
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
                //IDLE
                if (state == IDLE) begin
                    tx_data <= 8'd0;
                    frame_done <= 1'b0;
                    CRC32_valid <= 1'b0;
                end
                //counter PREAMBLE
                if (state == PREAMBLE) begin
                    cnt_preamble++;
                end
                else if (next_state == PREAMBLE) begin
                    cnt_preamble <= 3'b000;
                end
                //SFD
                if (state == SFD) begin
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


    always_comb begin : FSM_ethernet_frame_tx
        case (state)
            IDLE: begin
                
                next_state = (start == 1'b1) ? PREAMBLE : IDLE;
            end

            PREAMBLE: begin 
                tx_valid = 1'b1;
                tx_data = 8'h55;                                        
                next_state = (cnt_preamble == 3'b110) ? SFD : PREAMBLE;
            end

            SFD: begin
                tx_data = 8'hAB; 
                next_state = MAC_DEST;
            end

            MAC_DEST: begin                              
                CRC32_valid = 1'b1;
                tx_data = MAC_dest_addr[47 - cnt_MAC_dest*8 -: 8];     //MSB first
                CRC32_data = MAC_dest_addr[47 - cnt_MAC_dest*8 -: 8]; 
                next_state = (cnt_MAC_dest == 3'b101) ? MAC_SOURCE : MAC_DEST;
                
            end

            MAC_SOURCE: begin                             
                tx_data = MAC_source_addr[47 - cnt_MAC_source*8 -: 8];     //MSB first
                CRC32_data = MAC_source_addr[47 - cnt_MAC_source*8 -: 8];
                next_state = (cnt_MAC_source == 3'b101) ? TYPE : MAC_SOURCE;
                
            end

            TYPE: begin
                tx_data = ethernet_type[15 - cnt_ethernet_type*8 -: 8];
                CRC32_data = ethernet_type[15 - cnt_ethernet_type*8 -: 8];
                next_state = (cnt_ethernet_type == 1'b1) ? PAYLOAD : TYPE;
            end

            

            PAYLOAD: begin      
                tx_data = payload[(payload_length*8) - 1 - cnt_payload*8 -: 8];  //MSB first
                CRC32_data = payload[(payload_length*8) - 1 - cnt_payload*8 -: 8];   //MSB first
                if (cnt_payload == payload_length-1) begin
                    // next_state = ((14+payload_length)*8 < 512) ? PAD : FCS;
                    next_state = ((14+payload_length)*8 < 10) ? PAD : FCS; //for testing
                end
                else begin
                    next_state = PAYLOAD;
                end
            end

            PAD: begin               //Minimum frame Größe von 64 bytes sicherstellen
                tx_data = 8'h00;
                CRC32_data = 8'h00;
                // next_state = ((14 + payload_length + cnt_pad)*8 >= 512) ? FCS : PAD;
                next_state = ((14 + payload_length + cnt_pad)*8 >= 10) ? FCS : PAD;     //for testing
            end

            FCS: begin
                CRC32_valid = 1'b0;
                tx_data = CRC32_crc[31 - cnt_fcs*8 -: 8];      //MSB first
                next_state = (cnt_fcs == 2'b11) ? IPG : FCS;
            end

            IPG : begin
                tx_data = 8'h00;
                tx_valid = 1'b0;
                if (cnt_ipg == 4'b1011) begin
                    frame_done = 1'b1;
                end
                next_state = (cnt_ipg == 4'b1011) ? IDLE : IPG;
            end

            default tx_data <= 'x;
   
        endcase
    end

endmodule
