`timescale 1ns/1ps
`define CASE2
`define FSDB
module ctrl_t_tb();

reg clk = 1'b0;
reg rst_n = 1'b0;
reg tx_data_on = 1'b0;
reg tx_lp_ready =1'b1;
reg tx_lt_sop = 1'b0;
reg tx_lt_eop = 1'b0;
reg tx_lt_valid = 1'b0;
reg [7:0] tx_lt_data = 8'h00;
reg tx_lt_cancle = 1'b0;
reg [7:0] tx_to_data = 8'hf0;
reg tx_to_sop = 1'b1;
reg tx_to_eop = 1'b0;
reg tx_to_valid = 1'b0;

wire tx_lp_sop;
wire tx_lp_eop;
wire tx_lp_valid;
wire [7:0] tx_lp_data;
wire tx_lp_cancle;
wire tx_lp_eop_en;
wire tx_to_ready;
wire tx_lt_ready;


control_t control_tu_u0(
    .clk          ( clk          ), // input
    .rst_n        ( rst_n        ), // input
    
    // interface with `link_control`
    .tx_data_on   ( tx_data_on   ), // input
    .tx_lp_eop_en ( tx_lp_eop_en ), // output

    // interface with `crc5_t` (TX TOKEN / HANDSHAKE)
    .tx_to_sop    ( tx_to_sop    ), // input
    .tx_to_eop    ( tx_to_eop    ), // input
    .tx_to_valid  ( tx_to_valid  ), // input
    .tx_to_ready  ( tx_to_ready  ), // output
    .tx_to_data   ( tx_to_data   ), // input [7:0]
    
    // interface with link layer (TX DATA)
    .tx_lt_sop    ( tx_lt_sop    ), // input
    .tx_lt_eop    ( tx_lt_eop    ), // input
    .tx_lt_valid  ( tx_lt_valid  ), // input
    .tx_lt_ready  ( tx_lt_ready  ), // output
    .tx_lt_data   ( tx_lt_data   ), // input [7:0]
    .tx_lt_cancle ( tx_lt_cancle ), // input

    // interface with phy
    .tx_lp_sop    ( tx_lp_sop    ), // output
    .tx_lp_eop    ( tx_lp_eop    ), // output
    .tx_lp_valid  ( tx_lp_valid  ), // output
    .tx_lp_ready  ( tx_lp_ready  ), // input
    .tx_lp_data   ( tx_lp_data   ), // output [7:0]
    .tx_lp_cancle ( tx_lp_cancle ) // output
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
        #1430 tx_data_on = 1'b1;
        #7410 tx_data_on = 1'b0;
    join
end

integer mycnt1;
initial begin
    # 1470 tx_lp_ready <= 1'b0;
    # 640;
    for(mycnt1 = 0; mycnt1 < 9; mycnt1 = mycnt1 + 1) begin
        tx_lp_ready <= 1'b1;
        # 20;
        tx_lp_ready <= 1'b0;
        # 640;
    end
    tx_lp_ready <= 1'b1;
end

integer mycnt2;
initial begin
    # 1431 tx_lt_data <= 8'hc3;
    # 20 tx_lt_data <= 8'h01;
    # 20 tx_lt_data <= 8'h02;
    for(mycnt2 = 0; mycnt2 < 7; mycnt2 = mycnt2 + 1) begin
        # 660;
        tx_lt_data <= tx_lt_data + 8'd1;
    end
end

initial begin
    # 1431 tx_lt_sop <= 1'b1;
    # 20 tx_lt_sop <= 1'b0;
end

initial begin
    # 6091 tx_lt_eop <= 1'b1;
end

initial begin
    fork
        # 1431 tx_lt_valid <= 1'b1;
        # 6751 tx_lt_valid <= 1'b0;
    join
end
`endif

`ifdef CASE1
initial begin
    fork
        # 9110 tx_lp_ready <= 1'b0;
        # 9750 tx_lp_ready <= 1'b1;
    join
end

initial begin
    #9070 tx_to_data <= 8'hd2;
end

initial begin
    fork    
        #9070 tx_to_eop <= 1'b1;
        #9070 tx_to_valid <= 1'b1;
        #9090 tx_to_valid <= 1'b0;
    join
end

`endif

`ifdef CASE2
initial begin
    fork
        #1490 tx_data_on <= 1'b1;
        #14790 tx_data_on <= 1'b0;
    join
end

integer mycnt1;
initial begin
    # 170 tx_lp_ready <= 1'b0;
    # 640 tx_lp_ready <= 1'b1; // 810 ns
    # 20 tx_lp_ready <= 1'b0; // 830 ns
    # 640 tx_lp_ready <= 1'b1; // 1470 ns
    # 20 tx_lp_ready <= 1'b0; // 1490 ns
    # 640 tx_lp_ready <= 1'b1; // 2130 ns
    # 2760 tx_lp_ready <= 1'b0; // 4890 ns
    for(mycnt1 = 0; mycnt1 < 15; mycnt1 = mycnt1 + 1) begin
        # 640;
        tx_lp_ready <= 1'b1;
        # 20;
        tx_lp_ready <= 1'b0;
    end // 14790 ns
    # 640 tx_lp_ready <= 1'b1;
end

integer mycnt2;
initial begin
    # 4851 tx_lt_data <= 8'hc3;
    # 20 tx_lt_data <= 8'h01; // 4871 ns
    # 20 tx_lt_data <= 8'h02; // 4891 ns
    for(mycnt2 = 0; mycnt2 < 13; mycnt2 = mycnt2 + 1) begin
        # 660 tx_lt_data <= tx_lt_data + 8'd1;
    end
end

initial begin
    fork
        #130 tx_to_data <= 8'he1;
        #150 tx_to_data <= 8'h8;
        #170 tx_to_data <= 8'h58;
        #830 tx_to_data <= 8'he1;
    join
end

initial begin
    fork    
        #170 tx_to_eop <= 1'b1;
        #830 tx_to_eop <= 1'b0;
        #150 tx_to_sop <= 1'b0;
        #830 tx_to_sop <= 1'b1;
        #130 tx_to_valid <= 1'b1;
        #830 tx_to_valid <= 1'b0;
    join
end

initial begin
    # 4851 tx_lt_sop <= 1'b1;
    # 20 tx_lt_sop <= 1'b0;
end

initial begin
    # 13471 tx_lt_eop <= 1'b1;
end

initial begin
    fork
        # 4851 tx_lt_valid <= 1'b1;
        # 14131 tx_lt_valid <= 1'b0;
    join
end
`endif

`ifdef CASE3
initial begin
    fork
        # 170 tx_lp_ready <= 1'b0;
        # 810 tx_lp_ready <= 1'b1;
        # 830 tx_lp_ready <= 1'b0;
        # 1470 tx_lp_ready <= 1'b1;
        # 1490 tx_lp_ready <= 1'b0;
        # 2130 tx_lp_ready <= 1'b1;
        # 12710 tx_lp_ready <= 1'b0;
        # 13350 tx_lp_ready <= 1'b1;
    join
end

initial begin
    fork
        #130 tx_to_data <= 8'h69;
        #150 tx_to_data <= 8'h8;
        #170 tx_to_data <= 8'h58;
        #830 tx_to_data <= 8'h69;
        #12670 tx_to_data <= 8'hd2;
    join
end

initial begin
    fork    
        #170 tx_to_eop <= 1'b1;
        #830 tx_to_eop <= 1'b0;
        #12670 tx_to_eop <= 1'b1;
        #150 tx_to_sop <= 1'b0;
        #830 tx_to_sop <= 1'b1;
        #130 tx_to_valid <= 1'b1;
        #830 tx_to_valid <= 1'b0;
        #12670 tx_to_valid <= 1'b1;
        #12690 tx_to_valid <= 1'b0;
    join
end

`endif

`ifdef FSDB
initial begin
	$fsdbDumpfile("ctrl_t_case.fsdb");
	$fsdbDumpvars;
end
`endif
endmodule
