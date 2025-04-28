`timescale 1ns / 1ps
`define CASE3
`define FSDB
module crc5_t_tb();

reg clk = 1'b0;
reg rst_n = 1'b0;
reg [3:0] tx_pid = 4'b0000;
reg [6:0] tx_addr = 7'h00;
reg [3:0] tx_endp = 4'h0;
reg tx_valid = 1'b0;
reg tx_to_ready = 1'b1;

wire tx_ready;
wire [3:0] tx_con_pid;
wire tx_con_pid_en;
wire [7:0] tx_to_data;
wire tx_to_sop;
wire tx_to_eop;
wire tx_to_vld;

crc5_t crc5_tu_u0(
    .clk           ( clk           ), // input
    .rst_n         ( rst_n         ), // input

    // interface with `control_t`
    .tx_to_sop     ( tx_to_sop     ), // output
    .tx_to_eop     ( tx_to_eop     ), // output
    .tx_to_valid   ( tx_to_valid   ), // output
    .tx_to_ready   ( tx_to_ready   ), // input
    .tx_to_data    ( tx_to_data    ), // output [7:0]

    // interface with `link_control`
    .tx_con_pid_en ( tx_con_pid_en ), // output
    .tx_con_pid    ( tx_con_pid    ), // output [3:0]

    // interface with link layer
    .tx_pid        ( tx_pid        ), // input [3:0]
    .tx_addr       ( tx_addr       ), // input [6:0]
    .tx_endp       ( tx_endp       ), // input [3:0]
    .tx_valid      ( tx_valid      ), // input
    .tx_ready      ( tx_ready      ) // output
);

parameter PERIOD  = 20;

initial begin
    forever #(PERIOD/2) clk = ~clk;
end

initial begin
    #92 rst_n = 1'b1;
end

initial begin
    # 22670;
    $finish;
end

`ifdef CASE0
initial begin
    fork
        #1430.5 tx_to_ready = 1'b0;
        #7410.5 tx_to_ready = 1'b1;
    join
end
`endif

`ifdef CASE1
initial begin
    fork
        #9030.5 tx_addr = 7'h8;
        #9030.5 tx_pid = 4'h2;
        #9051 tx_valid = 1'b1;
        #9071 tx_valid = 1'b0;
    join
end
`endif

`ifdef CASE2
initial begin
    fork
        #100.5 tx_addr = 7'h8;
        #100.5 tx_pid = 4'h1;
        #111 tx_valid = 1'b1;
        #131 tx_valid = 1'b0;
    join
end

initial begin
    fork
        #170.5 tx_to_ready = 1'b0;
        #810.5 tx_to_ready =1'b1;
        #830.5 tx_to_ready =1'b0;
        #1470.5 tx_to_ready =1'b1;
        #1490.5 tx_to_ready =1'b0;
        #14790.5 tx_to_ready =1'b1;
    join
end
`endif

`ifdef CASE3
initial begin
    fork
        #100.5 tx_addr = 7'h8;
        #12630.5 tx_addr = 7'h0;
        #100.5 tx_pid = 4'h9;
        #12630.5 tx_pid = 4'h2;
        #111 tx_valid = 1'b1;
        #131 tx_valid = 1'b0;
        #12651 tx_valid = 1'b1;
        #12671 tx_valid = 1'b0;
    join
end

initial begin
    fork
        #170.5 tx_to_ready = 1'b0;
        #810.5 tx_to_ready =1'b1;
        #830.5 tx_to_ready =1'b0;
        #1470.5 tx_to_ready =1'b1;
    join
end
`endif

`ifdef FSDB
initial begin
	$fsdbDumpfile("crc5_t_case.fsdb");
	$fsdbDumpvars;
end
`endif

endmodule