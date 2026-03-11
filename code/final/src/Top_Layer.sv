module Top_Layer (
    input clk,
    input reset,
    input start,
    input logic [47:0] MAC_dest_addr_in,      
    input logic [47:0] MAC_source_addr_in,
    input logic [15:0] ethernet_type_in,
    input logic [11999:0] payload_in,
    input logic [10:0] payload_length,

    
    output logic CRC32_error,
    output logic CRC32_correct,
    output logic [31:0] CRC32_crc,
    output logic Check_done,

    output logic [47:0] MAC_dest_addr_out,
    output logic [47:0] MAC_source_addr_out,
    output logic [15:0] ethernet_type_out,
    output logic [100:0] payload_out 

);

    //Signals Tx
    logic [7:0] tx_data_tx;
    logic tx_valid_tx;
    logic frame_done_tx;

    //Signals Rx
    logic [7:0] rx_data_rx;      
    logic rx_valid_rx;


    Ethernet_frame_gen Transmit(
        .clk(clk),
        .reset(reset),
        .start(start),
        .MAC_dest_addr(MAC_dest_addr_in),
        .MAC_source_addr(MAC_source_addr_in),
        .ethernet_type(ethernet_type_in),
        .payload(payload_in),
        .payload_length(payload_length),

        .tx_data(tx_data_tx),
        .tx_valid(tx_valid_tx),
        .frame_done(frame_done_tx)
    );

    Ethernet_frame_rx Receive(
        .clk(clk),
        .reset(reset),
        .rx_data(tx_data_tx),
        .rx_valid(tx_valid_tx),

        .CRC32_correct(CRC32_correct),
        .CRC32_error(CRC32_error),
        .CRC32_crc(CRC32_crc),
        .Check_done(Check_done),
        .MAC_dest_addr(MAC_dest_addr_out),
        .MAC_source_addr(MAC_source_addr_out),
        .ethernet_type(ethernet_type_out),
        .payload(payload_out)
    );


endmodule



