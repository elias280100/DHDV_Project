`timescale 1 ps / 1 ps
module CRC32_tb;

parameter CLK_T             = 10000;

parameter [31:0] POLY       = 32'h04C11DB7;
//parameter [31:0] POLY       = 32'hEDB88320;     //Ethernet 32 Polynomial reflected
parameter        CRC_SIZE   = 32;
parameter        DATA_WIDTH = 8;

parameter [31:0] init       = 32'hffffffff;
parameter [31:0] final_crc    = 32'h00000000;

logic                  clk;
logic                  rst;
logic                  crc_en;
logic [DATA_WIDTH-1:0] data;
logic [CRC_SIZE-1:0]   crc;

initial
  begin
    clk    = 1'b0;
    rst    = 1'b0;
    crc_en = 1'b0;
    data   = '0;
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
  rst = 1'b1;
  @( posedge clk );
  rst = 1'b0;
endtask

CRC32 #(
  .POLY(POLY),
  .init(init),
  .final_crc(final_crc)
) DUT (
  .clk(clk),
  .reset(rst),
  .valid(crc_en),
  .data_in(data),
  .crc_out(crc)
);

//Wavefrom dump
    initial begin
        // Dump für GTKWave/ModelSim
        $dumpfile("CRC_Gen.vcd");
        $dumpvars(0, CRC32_tb);
    end

initial
  begin
    fork
      clk_gen;
      apply_reset;
    join_none
    repeat( 10 )
      @( posedge clk );
    crc_en <= 1'b1;
    data <= 8'h31;
    @( posedge clk );
    data <= 8'h32;
    @( posedge clk );
    data <= 8'h33;
    @( posedge clk );
    data <= 8'h34;
    @( posedge clk);
    data <= 8'h35;
     @( posedge clk );
    data <= 8'h36;
    @( posedge clk );
    data <= 8'h37;
    @( posedge clk );
    data <= 8'h38;
    @( posedge clk);
    data <= 8'h39;
    @( posedge clk );
    crc_en <= 1'b0;
    data <= 8'h00;
    repeat( 10 )
      @( posedge clk );
      $display("crc_out = 0x%8h (erwartet: 0x0376E6E7)", crc);
        if (crc == 32'h0376E6E7)
            $display(" Test successful");
        else
            $display(" Test unsuccessful");
      $display("crc_out = 0x%8h ", crc);
    $stop;
    
  end

endmodule
