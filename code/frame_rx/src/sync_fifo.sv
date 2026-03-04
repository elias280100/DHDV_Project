module sync_fifo #(
    parameter DATA_WIDTH = 8, // Parameterizable width of data
    parameter FIFO_DEPTH  = 2048, // Parameterizable depth of FIFO RAM
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH) // FIFO address width
) (
    input  logic clk,        // Clock input signal
    input  logic reset,      // Reset input signal
    // Write port
    input  logic push,  // Write enable to issue a write operation
    input  logic [DATA_WIDTH-1:0] wr_data, // Input data to be written
    // Read port
    input  logic pop,  // Read enable to issue a read operation
    output logic [DATA_WIDTH-1:0] rd_data, // The read output data
    // Control flags
    output logic fifo_full,  // Flag indicating the FIFO is full
    output logic fifo_empty,  // Flag indicating the FIFO is empty
    //Used memory in fifo
    output logic [ADDR_WIDTH-1:0] fifo_used_memory
);

    logic [ADDR_WIDTH-1:0] wr_ptr;     // Write operation pointer
    logic [ADDR_WIDTH-1:0] rd_ptr;     // Read operation pointer
    logic [ADDR_WIDTH-1:0] wr_ptr_nxt; // Next state write pointer
    logic [ADDR_WIDTH-1:0] rd_ptr_nxt; // Next state read pointer

    // Signals for RAM module
    logic write_enable;
    logic [DATA_WIDTH-1:0] rd_data_raw;
    

    // Instantiate the dual-port RAM module
    dual_port_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_ram (
        .clk(clk),
        .we(write_enable),
        .wr_addr(wr_ptr),
        .wr_data(wr_data),
        .rd_addr(rd_ptr),
        .rd_data(rd_data_raw)
    );

    // Write enable logic
    assign write_enable = (~fifo_full) & push;

    //Used memory
    assign fifo_used_memory = wr_ptr - rd_ptr;

    // WRITE operation logic
    //----------------------
    always_comb
        wr_ptr_nxt = wr_ptr + 1;

    always_ff @(posedge clk) begin
        if (reset) begin
            wr_ptr <= 0;
        end else begin
            if (~fifo_full & push) begin
                wr_ptr <= wr_ptr_nxt; // Increment write pointer
            end
        end
    end

    // READ operation logic
    //----------------------
    always_comb
        rd_ptr_nxt = rd_ptr + 1;

    always_ff @(posedge clk) begin
        if (reset) begin
            rd_ptr <= 0;
        end else begin
            if (~fifo_empty & pop) begin
                rd_ptr <= rd_ptr_nxt;   // Increment read pointer
            end
        end
    end

    assign rd_data = rd_data_raw; // Read output data

    // Control flags logic
    //----------------------
    always_comb
        fifo_full = (wr_ptr_nxt == rd_ptr);

    always_comb
        fifo_empty = (rd_ptr == wr_ptr);
endmodule : sync_fifo
