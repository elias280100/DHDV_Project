module Top_Layer_tb;
parameter CLK_T             = 10000;

logic clk;
logic reset;
logic start;
logic [47:0] MAC_dest_addr_in;      
logic [47:0] MAC_source_addr_in;
logic [15:0] ethernet_type_in;
logic [11999:0] payload_in;
logic [10:0] payload_length;


logic CRC32_error;
logic CRC32_correct;
logic [31:0] CRC32_crc;
logic Check_done;

logic [47:0] MAC_dest_addr_out;
logic [47:0] MAC_source_addr_out;
logic [15:0] ethernet_type_out;
logic [11999:0] payload_out;

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

Top_Layer dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    .MAC_dest_addr_in(MAC_dest_addr_in),
    .MAC_source_addr_in(MAC_source_addr_in),
    .ethernet_type_in(ethernet_type_in),
    .payload_in(payload_in),
    .payload_length(payload_length),

    .CRC32_error(CRC32_error),
    .CRC32_correct(CRC32_correct),
    .CRC32_crc(CRC32_crc),
    .Check_done(Check_done),

    .MAC_dest_addr_out(MAC_dest_addr_out),
    .MAC_source_addr_out(MAC_source_addr_out),
    .ethernet_type_out(ethernet_type_out),
    .payload_out(payload_out)
);

//Wavefrom dump
    initial begin
        // Dump für GTKWave/ModelSim
        $dumpfile("Final.vcd");
        $dumpvars(0, Top_Layer_tb);
    end

  // Reset if one complete frame is received
  always @(posedge Check_done) begin
      apply_reset;
  end


initial
    begin
        fork
        clk_gen;
        apply_reset;
        join_none
        repeat( 10 )
        @( posedge clk );

        MAC_dest_addr_in [47:40] <= 8'h35;
        MAC_dest_addr_in [39:32] <= 8'h35;
        MAC_dest_addr_in [31:24] <= 8'h35;
        MAC_dest_addr_in [23:16] <= 8'h35;
        MAC_dest_addr_in [15:8] <= 8'h35;
        MAC_dest_addr_in [7:0] <= 8'h35;
        
        // MAC_dest[0] <= 8'h35;
        // MAC_dest[1] <= 8'h35;
        // MAC_dest[2] <= 8'h35;
        // MAC_dest[3] <= 8'h35;
        // MAC_dest[4] <= 8'h35;
        // MAC_dest[5] <= 8'h35;

        MAC_source_addr_in [47:40] <= 8'h86;
        MAC_source_addr_in [39:32] <= 8'h86;
        MAC_source_addr_in [31:24] <= 8'h86;
        MAC_source_addr_in [23:16] <= 8'h86;
        MAC_source_addr_in [15:8] <= 8'h86;
        MAC_source_addr_in [7:0] <= 8'h86;

        // MAC_source[0] <= 8'h86;
        // MAC_source[1] <= 8'h86;
        // MAC_source[2] <= 8'h86;
        // MAC_source[3] <= 8'h86;
        // MAC_source[4] <= 8'h86;
        // MAC_source[5] <= 8'h86;

        ethernet_type_in [15:8] <= 8'h27;
        ethernet_type_in [7:0] <= 8'h27;

        payload_in[39:32] <= 8'h42;
        payload_in[31:24] <= 8'h42;
        payload_in[23:16] <= 8'h42;
        payload_in[15:8] <= 8'h42;
        payload_in[7:0] <= 8'h42;

        payload_length <= 11'd5;

        // tb_CRC32_crc[0] <= 8'h50;
        // tb_CRC32_crc[1] <= 8'h50;
        // tb_CRC32_crc[2] <= 8'h50;
        // tb_CRC32_crc[3] <= 8'h50;

        @( posedge clk );
        start <= 1'b1;
        @ ( posedge clk );
        
        repeat( 1000 )
        @( posedge clk );
        
        $stop;
        
    end

endmodule