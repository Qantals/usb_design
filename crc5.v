`timescale 1ns / 1ps
module crc5(c, d, c_out);
input	[4:0]	c;
input	[10:0]	d;
output	[4:0]	c_out;

assign c_out[0] =	d[10] ^ d[9] ^ d[6] ^ d[5] ^ d[3] ^
			d[0] ^ c[0] ^ c[3] ^ c[4];

assign c_out[1] =	d[10] ^ d[7] ^ d[6] ^ d[4] ^ d[1] ^
			c[0] ^ c[1] ^ c[4];

assign c_out[2] =	d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^
			d[3] ^ d[2] ^ d[0] ^ c[0] ^ c[1] ^
			c[2] ^ c[3] ^ c[4];

assign c_out[3] =	d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[4] ^ d[3] ^
			d[1] ^ c[1] ^ c[2] ^ c[3] ^ c[4];

assign c_out[4] =	d[10] ^ d[9] ^ d[8] ^ d[5] ^ d[4] ^ d[2] ^
			c[2] ^ c[3] ^ c[4];

endmodule
