// `timescale 1ns/1ps

// module CRC32_tb;

//     logic        clk;
//     logic        reset;
//     logic [7:0]  data_in;
//     logic        valid;
//     logic [31:0] crc_out;

//     // DUT
//     CRC32 dut (.*);

//     // Clock
//     initial forever #5 clk = ~clk;

//     // Testvektor: "123456789" → Bekanntes CRC32/Ethernet-Ergebnis = 0xCBF43926
//     logic [63:0] test_data = 64'h393837363534333231; // "987654321" (Little-Endian Bytes)
//     int byte_idx = 0;

//     initial begin
//         clk = 0;
//         reset = 1;
//         valid = 0;
//         data_in = 0;
        
//         #20 reset = 0;
        
//         // Byteweise Daten eingeben
//         repeat(9) begin  // 9 Bytes: "123456789"
//             @(posedge clk);
//             data_in = test_data[7:0];
//             test_data = test_data >> 8;
//             valid = 1;
//             byte_idx++;
//         end
        
//         @(posedge clk) valid = 0;  // Fertig
        
//         #100;  // Warte bis stabil
        
//         $display("=== CRC32 TEST ===");
//         $display("Input: '123456789'");
//         $display("crc_out = 0x%8h (erwartet: 0xCBF43926)", crc_out);
//         if (crc_out == 32'hCBF43926)
//             $display("✅ TEST BESTANDEN!");
//         else
//             $display("❌ TEST FEHLgeschlagen!");
        
//         $finish;
//     end

// endmodule

`timescale 1 ps / 1 ps
module CRC32_tb;

parameter CLK_T             = 10000;

parameter [31:0] POLY       = 32'h04C11DB7;
parameter        CRC_SIZE   = 32;
parameter        DATA_WIDTH = 8;
//parameter [63:0] INIT       = 32'hffff;
//parameter        REF_IN     = 1;
//parameter        REF_OUT    = 1;
parameter [31:0] XOR_OUT    = 32'hffffffff;

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
  .POLY         ( POLY       ),
  //.CRC_SIZE     ( CRC_SIZE   ),
  //.DATA_WIDTH   ( DATA_WIDTH ),
  //.INIT         ( INIT       ),
  //.REF_IN       ( REF_IN     ),
  //.REF_OUT      ( REF_OUT    ),
  .final_crc      ( XOR_OUT    )
) DUT (
  .clk        ( clk        ),
  .reset        ( rst        ),
  //.soft_reset_i ( 1'b0       ),
  .valid      ( crc_en     ),
  .data_in       ( data       ),
  .crc_out        ( crc        )
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
    data <= 8'hff;
    @( posedge clk );
    data <= 8'h00;
    @( posedge clk );
    data <= 8'h00;
    @( posedge clk );
    data <= 8'h00;
    @( posedge clk );
    data <= 8'h1e;
    @( posedge clk );
    data <= 8'hf0;
    @( posedge clk );
    data <= 8'h1e;
    @( posedge clk );
    data <= 8'hc7;
    @( posedge clk );
    data <= 8'h4f;
    @( posedge clk );
    data <= 8'h82;
    @( posedge clk );
    data <= 8'h78;
    @( posedge clk );
    data <= 8'hc5;
    @( posedge clk );
    data <= 8'h82;
    @( posedge clk );
    data <= 8'he0; 
    @( posedge clk );
    data <= 8'h8c;
    @( posedge clk );
    data <= 8'h70;
    @( posedge clk );
    data <= 8'hd2;
    @( posedge clk );
    data <= 8'h3c;
    @( posedge clk );
    data <= 8'h78;
    @( posedge clk );
    data <= 8'he9;
    @( posedge clk );
    data <= 8'hff;
    @( posedge clk );
    data <= 8'h00;
    @( posedge clk );
    data <= 8'h00;
    @( posedge clk );
    data <= 8'h01;
    @( posedge clk );
    crc_en <= 1'b0;
    data <= 8'h00;
    repeat( 10 )
      @( posedge clk );
      $display("crc_out = 0x%8h (erwartet: 0xCBF43926)", crc);
    $stop;
    
  end

endmodule
