module Ethernet_frame_gen_tb;

logic clk;
logic reset;
logic start;
logic [47:0] MAC_dest;
logic [47:0] MAC_source;
logic [15_0] ethernet_type;
logic [7:0] payload [0:1499];

logic [31:0] CRC32_crc;
logic [7:0] CRC32_data;
logic CRC32_valid;

logic [7:0] tx_data;
logic frame_done;