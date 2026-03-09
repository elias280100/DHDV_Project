`timescale 1 ps / 1 ps
typedef enum {
    IDLE, 
    PREAMBLE, 
    SFD, 
    MAC_DEST, 
    MAC_SOURCE,
    TYPE, 
    FIFO,
    PAYLOAD, 
    PAD, 
    FCS,
    CHECK
    } State;

    module Ethernet_frame_rx (
        input clk,
        input reset,
        input logic [7:0] rx_data,      //wann logic und wann nicht?
        input logic rx_valid,
  
        //output [7:0] CRC32_crc [3:0],
        //CRC Generator
        //input logic [7:0] CRC32_crc[3:0],       //4 Bytes das hier vllt auch als 32 bit?
        //input logic [31:0] CRC32_crc,
        output logic [7:0] CRC32_data,
        output logic CRC32_valid,
        output logic CRC32_error,
        output logic CRC32_correct,


        //hier vllt alles in einem array
        output logic [47:0] MAC_dest_addr,
        output logic [47:0] MAC_source_addr,
        output logic [15:0] ethernet_type,
        output logic [100:0] payload 
        // output logic [7:0] MAC_dest_addr [5:0],        //6 Bytes
        // output logic [7:0] MAC_source_addr [5:0],      //6 Bytes
        // output logic [7:0] ethernet_type [1:0],        //2 Bytes
        // output logic [7:0] payload [1499:0]      //1500 Bytes
    );

    parameter DATA_WIDTH = 8; // Parameterizable width of data
    parameter FIFO_DEPTH  = 2048; // Parameterizable depth of FIFO RAM

    parameter [31:0] POLY = 32'h04C11DB7;     //Ethernet 32 Polynomial
    //parameter bit [31:0] POLY = 32'hEDB88320;     //Ethernet 32 Polynomial reflected
    parameter [31:0] final_crc = 32'h00000000;
    parameter [31:0] init = 32'hffffffff;

    logic [31:0] CRC32_crc;

    logic [DATA_WIDTH-1:0] fifo_data;
    logic fifo_rd_en;
    logic fifo_wr_en;
    logic fifo_empty;
    logic fifo_full;
    logic [DATA_WIDTH-1:0] fifo_used_memory;
    logic [DATA_WIDTH-1:0] length_payload_fcs;

    //logic [7:0] MAC_dest_addr_test [5:0];
    // logic [7:0] MAC_source_addr_test [5:0];      //6 Bytes
    // logic [7:0] ethernet_type_test [1:0];        //2 Bytes
    // logic [7:0] payload_test [1499:0];      //1500 Bytes

    // logic [47:0] MAC_dest_addr_test;
    // logic [47:0] MAC_source_addr_test;
    // logic [15:0] ethernet_type_test;
    // logic [11999:0] payload_test; 

    logic debug;

    // assign MAC_source_addr_test = MAC_source_addr;
    // //assign MAC_dest_addr_test = MAC_dest_addr;
    // assign ethernet_type_test = ethernet_type;
    // assign payload_test = payload;

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    )
    rx_fifo (
        .clk(clk),
        .reset(reset),
        .push(fifo_wr_en),
        .wr_data(rx_data),
        .pop(fifo_rd_en),
        .rd_data(fifo_data),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .fifo_used_memory(fifo_used_memory)
    );

    CRC32 #(
        .POLY(POLY),
        .final_crc(final_crc),
        .init(init)
    )
    CRC32_rx (
        .clk(clk),
        .reset(reset),
        .data_in(CRC32_data),
        .valid(CRC32_valid),
        .crc_out(CRC32_crc)
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
            //state <= IDLE;
            cnt_ethernet_type <= 1'b0;
            cnt_fcs <= 2'b00;
            cnt_ipg <= 4'b0000;
            cnt_MAC_dest <= 6'b000000;
            cnt_MAC_source <= 6'b000000;
            cnt_pad <= 6'b000000;
            cnt_payload <= 11'b00000000000;
            cnt_preamble <= 3'b000;
        end else begin
            //state <= next_state;
            //counter PREAMBLE
            if (state == PREAMBLE) begin
                if (rx_data == 8'hAA) begin      //muss das hier AA sein, wenn ich 55 hex sende?
                    cnt_preamble++;
                end
            end
            else if (next_state == PREAMBLE) begin
                cnt_preamble <= 3'b000;;
            end
            //counter MAC Dest
            if (state == MAC_DEST) begin
                // CRC32_valid <= 1'b1;
                // MAC_dest_addr[(47 - cnt_MAC_dest*8) -: 8] <= rx_data;
                // //MAC_dest_addr[5 - cnt_MAC_dest] <= rx_data;
                // CRC32_data <= rx_data;      //geht das so?
                cnt_MAC_dest++;
            end
            else if (next_state == MAC_DEST) begin
                cnt_MAC_dest <= 6'b000000;;
            end
            //counter MAC Source
            if (state == MAC_SOURCE) begin
                // MAC_source_addr[(47 - cnt_MAC_source*8) -: 8] <= rx_data;
                // //MAC_source_addr[5 - cnt_MAC_source] <= rx_data;
                // CRC32_data <= rx_data;
                cnt_MAC_source++;
            end
            else if (next_state == MAC_SOURCE) begin
                cnt_MAC_source <= 6'b000000;;
            end
            //counter TYPE
            if (state == TYPE) begin
                // ethernet_type[(15 - cnt_ethernet_type*8) -: 8] <= rx_data;
                // //ethernet_type[1 - cnt_ethernet_type] <= rx_data;
                // CRC32_data <= rx_data;
                cnt_ethernet_type++;
            end
            else if (next_state == TYPE) begin
                cnt_ethernet_type <= 1'b0;
            end
            //counter PAYLOAD
            if (state == PAYLOAD) begin
                // length_payload_fcs <= fifo_used_memory;  
                cnt_payload++;
                CRC32_valid = 1'b1;
                CRC32_data <= fifo_data;
                // if (fifo_used_memory > 4) begin // dann solange Daten reinschreiben bis nur noch 4 bytes im fifo sind -> FCS
                //         payload[(((length_payload_fcs-5)*8)-1) -: 8] <= fifo_data;
                //         //payload[length_payload_fcs - 4] <= fifo_data; //muss ich hier überhaupt mit counter runterzählen? oder reicht length
                //         CRC32_data <= fifo_data;
                // end
                
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
                // length_payload_fcs <= fifo_used_memory;
                // CRC32_data <= fifo_data;
                cnt_fcs++;

            end
            else if (next_state == FCS) begin
                cnt_fcs <= 2'b00;
            end
            //FIFO
            // if (state == FIFO) begin
            //     fifo_wr_en <= 1'b1;
            // end
            // if (state == CHECK) begin
            //     fifo_rd_en <= 1'b0;
            // end
        end
    end 

    //welche signale in always_comb setzen und welche in always_ff?

    always_comb begin : FSM_ethernet_frame_rx
        case (state)
            IDLE: begin
                CRC32_valid = 1'b0;
                CRC32_correct = 1'b0;
                CRC32_error = 1'b0;
                fifo_wr_en = 1'b0;
                fifo_rd_en = 1'b0;
                next_state = (rx_valid == 1'b1) ? PREAMBLE : IDLE;
            end

            PREAMBLE: begin
                next_state = (cnt_preamble == 3'b101) ? SFD : PREAMBLE;
            end

            SFD: begin
                next_state = (rx_data == 8'hD5) ? MAC_DEST : SFD;
            end

            MAC_DEST: begin                 
                //CRC32_valid = 1'b1;
                CRC32_valid = 1'b1;
                MAC_dest_addr[(47 - cnt_MAC_dest*8) -: 8] = rx_data;
                //MAC_dest_addr[5 - cnt_MAC_dest] <= rx_data;
                CRC32_data = rx_data;      //geht das so?
                next_state = (cnt_MAC_dest == 3'b101) ? MAC_SOURCE : MAC_DEST;
            end

            MAC_SOURCE: begin
                MAC_source_addr[(47 - cnt_MAC_source*8) -: 8] = rx_data;
                //MAC_source_addr[5 - cnt_MAC_source] <= rx_data;
                CRC32_data = rx_data;
                next_state = (cnt_MAC_source == 3'b101) ? TYPE : MAC_SOURCE;
            end

            TYPE: begin
                ethernet_type[(15 - cnt_ethernet_type*8) -: 8] = rx_data;
                //ethernet_type[1 - cnt_ethernet_type] <= rx_data;
                CRC32_data = rx_data;
                next_state = (cnt_ethernet_type == 1'b1) ? FIFO : TYPE;
            end

            FIFO: begin
                fifo_wr_en = 1'b1;
                CRC32_valid = 1'b0;
                next_state = (rx_valid == 1'b0) ? PAYLOAD : FIFO;
            end


            PAYLOAD: begin
                //CRC32_valid = 1'b1;
                fifo_wr_en = 1'b0;
                fifo_rd_en = 1'b1;     //read enable
                length_payload_fcs = fifo_used_memory;
                //if (fifo_used_memory > 3) begin // dann solange Daten reinschreiben bis nur noch 4 bytes im fifo sind -> FCS
                    payload[(((length_payload_fcs-4)*8)-1) -: 8] = fifo_data;
                    //payload[length_payload_fcs - 4] <= fifo_data; //muss ich hier überhaupt mit counter runterzählen? oder reicht length
                    //CRC32_data = fifo_data;
                //end
                    //das hier nur einmal zuweisen, wenn keine neue Daten mehr ins fifo geschrieben werden und noch nicht gelesen wurde
                
                next_state = (fifo_used_memory == 5) ? FCS : PAYLOAD;       
            end

            FCS: begin
                length_payload_fcs = fifo_used_memory;
                CRC32_data = fifo_data;
                next_state = (fifo_empty == 1'b1) ? CHECK : FCS;
                end

            CHECK: begin            //das hier vllt auch alles in always_ff?
                fifo_rd_en = 1'b0;
                CRC32_valid = 1'b0;
                if (CRC32_crc == 0) begin
                    CRC32_correct = 1'b1;
                end
                else begin
                    CRC32_error = 1'b1;
                end
                next_state = IDLE;
            end
            
    endcase
end
    

endmodule

                






