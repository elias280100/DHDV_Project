`timescale 1 ps / 1 ps
module Ethernet_frame_rx_tb;

parameter CLK_T             = 10000;
parameter DATA_WIDTH = 8; // Parameterizable width of data
parameter FIFO_DEPTH  = 2048; // Parameterizable depth of FIFO RAM

        logic clk;
        logic reset;
        logic [7:0] rx_data;      //wann logic und wann nicht?
        logic rx_valid;
  
        //output [7:0] CRC32_crc [3:0],
        //CRC Generator
        //input logic [7:0] CRC32_crc[3:0],       //4 Bytes das hier vllt auch als 32 bit?
        logic [31:0] CRC32_crc;
        logic [7:0] CRC32_data;
        logic CRC32_valid;
        logic CRC32_error;
        logic CRC32_correct;

        logic [47:0] MAC_dest_addr;
        logic [47:0] MAC_source_addr;
        logic [15:0] ethernet_type;
        logic [100:0] payload; 

        // logic [7:0] MAC_dest_addr [5:0];        //6 Bytes
        // logic [7:0] MAC_source_addr [5:0];      //6 Bytes
        // logic [7:0] ethernet_type [1:0];        //2 Bytes
        // logic [7:0] payload [1499:0];       //1500 Bytes


initial
  begin
    clk    = 1'b0;
    reset    = 1'b0;
    rx_valid = 1'b0;
  end

task automatic clk_gen;
  forever
    begin
      #( CLK_T / 2 );
      clk <= ~clk;
    end
endtask

task automatic apply_reset;
  @( posedge clk );
  reset = 1'b1;
  @( posedge clk );
  reset = 1'b0;
endtask


Ethernet_frame_rx #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
    )
    dut (
    .clk(clk),
    .reset(reset),
    .MAC_dest_addr(MAC_dest_addr),
    .MAC_source_addr(MAC_source_addr),
    .ethernet_type(ethernet_type),
    .payload(payload),
    .CRC32_crc(CRC32_crc),
    // .CRC32_data(CRC32_data),
    // .CRC32_valid(CRC32_valid),
    .CRC32_correct(CRC32_correct),
    .CRC32_error(CRC32_error),
    .rx_data(rx_data),
    .rx_valid(rx_valid)
);

//Wavefrom dump
    initial begin
        // Dump für GTKWave/ModelSim
        $dumpfile("Ethernet_frame_rx.vcd");
        $dumpvars(0, Ethernet_frame_rx_tb);
    end



    initial
    begin
        fork
        clk_gen;
        apply_reset;
        join_none
        repeat( 10 )
        @( posedge clk );
        rx_valid <= 1'b1;
        @( posedge clk );
        rx_data <= 8'hAA;
        @( posedge clk );
        rx_data <= 8'hAA;
        @( posedge clk );
        rx_data <= 8'hAA;
        @( posedge clk );
        rx_data <= 8'hAA;
        @( posedge clk );
        rx_data <= 8'hAA;
        @( posedge clk );
        rx_data <= 8'hAA;
        @( posedge clk );
        rx_data <= 8'hAA;
        @( posedge clk );
        rx_data <= 8'hD5;
        //MAC DEST
        @( posedge clk );
        rx_data <= 8'h35;
        @( posedge clk );
        rx_data <= 8'h36;
        @( posedge clk );
        rx_data <= 8'h37;
        @( posedge clk );
        rx_data <= 8'h38;
        @( posedge clk );
        rx_data <= 8'h39;
        @( posedge clk );
        rx_data <= 8'h40;
        //MAC SOURCE
        @( posedge clk );
        rx_data <= 8'h86;
        @( posedge clk );
        rx_data <= 8'h86;
        @( posedge clk );
        rx_data <= 8'h86;
        @( posedge clk );
        rx_data <= 8'h86;
        @( posedge clk );
        rx_data <= 8'h86;
        @( posedge clk );
        rx_data <= 8'h86;
        //TYPE
        @( posedge clk );
        rx_data <= 8'h27;
        @( posedge clk );
        rx_data <= 8'h27;
        //PAYLOAD
        @( posedge clk );
        rx_data <= 8'h42;
        @( posedge clk );
        rx_data <= 8'h42;
        @( posedge clk );
        rx_data <= 8'h42;
        @( posedge clk );
        rx_data <= 8'h42;
        @( posedge clk );
        rx_data <= 8'h42;
        //PAD
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h00;
        // @( posedge clk );
        // rx_data <= 8'h10;
        // @( posedge clk );
        // rx_data <= 8'h11;
        // @( posedge clk );
        // rx_data <= 8'h12;
        // @( posedge clk );
        // rx_data <= 8'h13;
        // @( posedge clk );
        // rx_data <= 8'h14;
        // @( posedge clk );
        // rx_data <= 8'hE5;
        // @( posedge clk );
        // rx_data <= 8'hE5;
        // @( posedge clk );
        // rx_data <= 8'hE5;
        // @( posedge clk );
        // rx_data <= 8'hE5;
        // @( posedge clk );
        // rx_data <= 8'hE5;
        // @( posedge clk );
        // rx_data <= 8'hE5;
        // @( posedge clk );
        // rx_data <= 8'hE5;
        // @( posedge clk );
        // rx_data <= 8'hE5;
        //FCS
        @( posedge clk );
        rx_data <= 8'hE7;
        @( posedge clk );
        rx_data <= 8'h60;
        @( posedge clk );
        rx_data <= 8'h0D;
        @( posedge clk );
        rx_data <= 8'h97;
        //@( posedge clk );
        // @( posedge clk );
        rx_valid <= 1'b0;
        @ ( posedge clk );

        repeat( 1000 )
        @( posedge clk );
        
        $stop;
        
    end

endmodule
