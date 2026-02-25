module Top_layer (

);

CRC32 # (                           //funktioniert das so?
    .POLY(CRC32_Poly),
    .final_crc(CRC32_final_crc),
    .init(CRC32_init)
) crc_inst (
    .clk(clk),
    .reset(CRC32_reset),
    .data_in(CRC32_data),
    .valid(CRC32_valid),
    .crc_out(CRC32_crc_out)
);