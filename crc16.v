module crc16 (
    input [7:0] data,
    input [15:0] crc_in,
    output [15:0] crc_out
);
    
wire [7:0] d;
wire [15:0] c;

assign d = data;
assign c = crc_in;

assign crc_out[0] = c[10]^c[11]^c[12]^c[13]^c[14]^c[15]^c[8]^c[9]^d[0]^d[1]^d[2]^d[3]^d[4]^d[5]^d[6]^d[7];
assign crc_out[1] = c[10]^c[11]^c[12]^c[13]^c[14]^c[15]^c[9]^d[0]^d[1]^d[2]^d[3]^d[4]^d[5]^d[6];
assign crc_out[2] = c[8]^c[9]^d[6]^d[7];
assign crc_out[3] = c[10]^c[9]^d[5]^d[6];
assign crc_out[4] = c[10]^c[11]^d[4]^d[5];
assign crc_out[5] = c[11]^c[12]^d[3]^d[4];
assign crc_out[6] = c[12]^c[13]^d[2]^d[3];
assign crc_out[7] = c[13]^c[14]^d[1]^d[2];
assign crc_out[8] = c[0]^c[14]^c[15]^d[0]^d[1];
assign crc_out[9] = c[1]^c[15]^d[0];
assign crc_out[10] = c[2];
assign crc_out[11] = c[3];
assign crc_out[12] = c[4];
assign crc_out[13] = c[5];
assign crc_out[14] = c[6];
assign crc_out[15] = c[10]^c[11]^c[12]^c[13]^c[14]^c[15]^c[7]^c[8]^c[9]^d[0]^d[1]^d[2]^d[3]^d[4]^d[5]^d[6]^d[7];

endmodule