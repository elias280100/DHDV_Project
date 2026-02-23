module CRC32_tb;

parameter [31:0] POLY;
parameter [31:0] final_crc;

logic clk;
logic reset;
logic [7:0] data;
logic enable;

logic [31:0] crc;

CRC32 #(
    .POLY(POLY),
    .final_crc(final_crc)
)
dut (
    .clk(clk),
    .reset(reset),
    .data_in(data),
    .valid(enable),
    .crc_out(crc)
);

// Clock generation
  always #5 clk = ~clk;

  initial begin
        enable = 1'b1;
        data = 8'b10010110;
        $$display("CRC: %b", crc);
  end
endmodule
