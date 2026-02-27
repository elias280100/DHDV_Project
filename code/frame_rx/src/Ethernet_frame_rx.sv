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

    module Ethernet_frame_rx (
        input clk,
        input reset,
        input [7:0] rx_data,
        output [7:0] CRC32_crc [3:0],
        output [7:0] MAC_dest_addr [5:0],        //6 Bytes
        output [7:0] MAC_source_addr [5:0],      //6 Bytes
        output [7:0] ethernet_type [1:0],        //2 Bytes
        output [7:0] payload [1499:0],       //1500 Bytes
    )