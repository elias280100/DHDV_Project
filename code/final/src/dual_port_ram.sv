module dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 11  // For FIFO_DEPTH = 16, ADDR_WIDTH = 4
) (
    input  logic                  clk,
    input  logic                  we,          // Write enable
    input  logic [ADDR_WIDTH-1:0] wr_addr,     // Write address
    input  logic [DATA_WIDTH-1:0] wr_data,     // Write data
    input  logic [ADDR_WIDTH-1:0] rd_addr,     // Read address
    output logic [DATA_WIDTH-1:0] rd_data      // Read data
);

    // RAM storage
    logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Write operation
    always_ff @(posedge clk) begin
        if (we) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // Read operation
    always_ff @(posedge clk) begin
        rd_data <= mem[rd_addr];
    end

endmodule
