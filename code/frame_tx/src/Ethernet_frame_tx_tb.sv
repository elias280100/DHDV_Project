`timescale 1 ps / 1 ps
module Ethernet_frame_gen_tb;

parameter CLK_T             = 10000;

logic clk;
logic reset;
logic start;
logic [47:0] MAC_dest;
logic [47:0] MAC_source;
logic [15:0] ethernet_type;
logic [11999:0] payload;

logic [10:0] payload_length;


logic [7:0] tb_tx_data;
logic tb_tx_valid;
logic tb_frame_done;


initial
  begin
    clk    = 1'b0;
    reset    = 1'b0;
    start = 1'b0;
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


Ethernet_frame_gen dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .MAC_dest_addr(MAC_dest),
    .MAC_source_addr(MAC_source),
    .ethernet_type(ethernet_type),
    .payload_length(payload_length),
    .payload(payload),
    //.CRC32_crc(tb_CRC32_crc),
    // .CRC32_data(tb_CRC32_data),
    // .CRC32_valid(tb_CRC32_valid),
    .tx_data(tb_tx_data),
    .tx_valid(tb_tx_valid),
    .frame_done(tb_frame_done)
);

//Wavefrom dump
    initial begin
        // Dump für GTKWave/ModelSim
        $dumpfile("Ethernet_frame.vcd");
        $dumpvars(0, Ethernet_frame_gen_tb);
    end



    initial
    begin
        fork
        clk_gen;
        apply_reset;
        join_none
        repeat( 10 )
        @( posedge clk );

        MAC_dest[47:40] <= 8'h35;
        MAC_dest[39:32] <= 8'h36;
        MAC_dest [31:24] <= 8'h37;
        MAC_dest [23:16] <= 8'h38;
        MAC_dest [15:8] <= 8'h39;
        MAC_dest [7:0] <= 8'h40;

        // MAC_dest[47:40] <= $urandom_range(8'hFF, 8'h00);
        // MAC_dest[39:32] <= $urandom_range(8'hFF, 8'h00);
        // MAC_dest[31:24] <= $urandom_range(8'hFF, 8'h00);
        // MAC_dest[23:16] <= $urandom_range(8'hFF, 8'h00);
        // MAC_dest[15:8]  <= $urandom_range(8'hFF, 8'h00);
        // MAC_dest[7:0]   <= $urandom_range(8'hFF, 8'h00);
        

        MAC_source[47:40] <= 8'h50;
        MAC_source[39:32] <= 8'h51;
        MAC_source [31:24] <= 8'h52;
        MAC_source [23:16] <= 8'h53;
        MAC_source [15:8] <= 8'h54;
        MAC_source [7:0] <= 8'h55;

        // MAC_source[47:40] <= $urandom_range(8'hFF, 8'h00);
        // MAC_source[39:32] <= $urandom_range(8'hFF, 8'h00);
        // MAC_source[31:24] <= $urandom_range(8'hFF, 8'h00);
        // MAC_source[23:16] <= $urandom_range(8'hFF, 8'h00);
        // MAC_source[15:8]  <= $urandom_range(8'hFF, 8'h00);
        // MAC_source[7:0]   <= $urandom_range(8'hFF, 8'h00);


        // ethernet_type[15:8] <= $urandom_range(8'hFF, 8'h00);
        // ethernet_type[7:0] <= $urandom_range(8'hFF, 8'h00);

        ethernet_type[15:8] <= 8'h56;
        ethernet_type[7:0] <= 8'h57;

        payload[39:32] <= 8'h60;
        payload[31:24] <= 8'h61;
        payload[23:16] <= 8'h62;
        payload[15:8] <= 8'h63;
        payload[7:0] <= 8'h64;

        // payload[39:32] <= $urandom_range(8'hFF, 8'h00);
        // payload[31:24] <= $urandom_range(8'hFF, 8'h00);
        // payload[23:16] <= $urandom_range(8'hFF, 8'h00);
        // payload[15:8]  <= $urandom_range(8'hFF, 8'h00);
        // payload[7:0]   <= $urandom_range(8'hFF, 8'h00);

        payload_length <= 11'd5;

        @( posedge clk );
        start <= 1'b1;
        @ ( posedge clk );

        repeat( 1000 )
        @( posedge clk );
        
        $stop;
        
    end

endmodule
