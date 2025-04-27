`timescale 1ns / 1ps
`define CASE3

module usb_link_top_tb ();

// usb_link inputs
reg clk = 1'b0;
reg rst_n = 1'b0;
reg [6:0] self_addr = 7'h08;
reg ms; // different case init
reg [15:0] time_threshold; // different case init
reg [5:0] delay_threshole = 6'd63;
reg rx_lp_sop = 1'b0;
reg rx_lp_eop = 1'b0;
reg rx_lp_valid = 1'b0;
reg [7:0] rx_lp_data = 8'h0;
reg tx_lp_ready = 1'b1;
reg rx_lt_ready = 1'b1;
reg [3:0] tx_pid = 4'b0000;
reg [6:0] tx_addr = 7'h00;
reg [3:0] tx_endp = 4'h0;
reg tx_valid = 1'b0;
reg tx_lt_sop = 1'b0;
reg tx_lt_eop = 1'b0;
reg tx_lt_valid = 1'b0;
reg [7:0] tx_lt_data = 8'h00;
reg tx_lt_cancle = 1'b0;

// usb_link outputs
wire crc5_err;
wire time_out;
wire d_oe;
wire rx_lp_ready;
wire tx_lp_sop;
wire tx_lp_eop;
wire tx_lp_valid;
wire [7:0] tx_lp_data;
wire tx_lp_cancle;
wire rx_pid_en;
wire [3:0] rx_pid;
wire [3:0] rx_endp;
wire rx_lt_sop;
wire rx_lt_eop;
wire rx_lt_valid;
wire [7:0] rx_lt_data;
wire tx_ready;
wire tx_lt_ready;

// inner variables (I do not want to implement this, for much freedom to implement so unpracticable to guess behavior in testbench)
// reg [9:0] i = 10'h000; // indicate `tx_lt_data`
// reg [10:0] d; // no init
// wire [4:0] c_out; // no need init
// reg [9:0] j = 10'h000; // indicate `rx_lp_data`
// reg [9:0] num0; // no init
// reg [4:0] cnt = 5'h00;
// reg [1:0] abc = 2'h3; // down count for master


// instantiation
usb_link usb_link_u0(
    .clk             ( clk             ),
    .rst_n           ( rst_n           ),
    .self_addr       ( self_addr       ),
    .crc5_err        ( crc5_err        ),
    .ms              ( ms              ),
    .time_threshold  ( time_threshold  ),
    .delay_threshole ( delay_threshole ),
    .time_out        ( time_out        ),
    .d_oe            ( d_oe            ),
    .rx_lp_sop       ( rx_lp_sop       ),
    .rx_lp_eop       ( rx_lp_eop       ),
    .rx_lp_valid     ( rx_lp_valid     ),
    .rx_lp_ready     ( rx_lp_ready     ),
    .rx_lp_data      ( rx_lp_data      ),
    .tx_lp_sop       ( tx_lp_sop       ),
    .tx_lp_eop       ( tx_lp_eop       ),
    .tx_lp_valid     ( tx_lp_valid     ),
    .tx_lp_ready     ( tx_lp_ready     ),
    .tx_lp_data      ( tx_lp_data      ),
    .tx_lp_cancle    ( tx_lp_cancle    ),
    .rx_pid_en       ( rx_pid_en       ),
    .rx_pid          ( rx_pid          ),
    .rx_endp         ( rx_endp         ),
    .rx_lt_sop       ( rx_lt_sop       ),
    .rx_lt_eop       ( rx_lt_eop       ),
    .rx_lt_valid     ( rx_lt_valid     ),
    .rx_lt_ready     ( rx_lt_ready     ),
    .rx_lt_data      ( rx_lt_data      ),
    .tx_pid          ( tx_pid          ),
    .tx_addr         ( tx_addr         ),
    .tx_endp         ( tx_endp         ),
    .tx_valid        ( tx_valid        ),
    .tx_ready        ( tx_ready        ),
    .tx_lt_sop       ( tx_lt_sop       ),
    .tx_lt_eop       ( tx_lt_eop       ),
    .tx_lt_valid     ( tx_lt_valid     ),
    .tx_lt_ready     ( tx_lt_ready     ),
    .tx_lt_data      ( tx_lt_data      ),
    .tx_lt_cancle    ( tx_lt_cancle    )
);


// tb realization
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


/********************** case 0 **********************/
`ifdef CASE0
initial begin
    ms <= 1'b0;
    time_threshold <= 16'd200;
end

initial begin
    fork
        # 111 rx_lp_sop <= 1'b1;
        # 751 rx_lp_sop <= 1'b0;
        # 9051 rx_lp_sop <= 1'b1;
    join
end

initial begin
    fork
        # 1391 rx_lp_eop <= 1'b1;
        # 9030 rx_lp_eop <= 1'b0;
        # 9051 rx_lp_eop <= 1'b1;
    join
end

initial begin
    fork
        # 111 rx_lp_valid <= 1'b1;
        # 131 rx_lp_valid <= 1'b0;
        # 751 rx_lp_valid <= 1'b1;
        # 771 rx_lp_valid <= 1'b0;
        # 1391 rx_lp_valid <= 1'b1;
        # 1411 rx_lp_valid <= 1'b0;
        # 9051 rx_lp_valid <= 1'b1;
        # 9071 rx_lp_valid <= 1'b0;
    join
end

initial begin
    fork
        # 111 rx_lp_data <= 8'h69;
        # 751 rx_lp_data <= 8'h08;
        # 1391 rx_lp_data <= 8'h58;
        # 9030 rx_lp_data <= 8'h00;
        # 9051 rx_lp_data <= 8'hd2;
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
`endif


/********************** case 1 **********************/
`ifdef CASE1
initial begin
    ms <= 1'b0;
    time_threshold <= 16'd800;
end

initial begin
    fork
        # 111 rx_lp_sop <= 1'b1;
        # 751 rx_lp_sop <= 1'b0;
        # 3051 rx_lp_sop <= 1'b1;
        # 3691 rx_lp_sop <= 1'b0;
    join
end

initial begin
    fork
        # 1391 rx_lp_eop <= 1'b1;
        # 3030 rx_lp_eop <= 1'b0;
        # 8811 rx_lp_eop <= 1'b1;
    join
end

integer mycnt1;
initial begin
    # 111 rx_lp_valid <= 1'b1;
    # 20 rx_lp_valid <= 1'b0; // 131 ns
    # 620 rx_lp_valid <= 1'b1;
    # 20 rx_lp_valid <= 1'b0; // 771 ns
    # 620 rx_lp_valid <= 1'b1;
    # 20 rx_lp_valid <= 1'b0; // 1411 ns
    # 1640;
    for(mycnt1 = 0; mycnt1 < 10; mycnt1 = mycnt1 + 1) begin
        rx_lp_valid <= 1'b1;
        # 20 rx_lp_valid <= 1'b0;
        # 620;
    end
end

integer mycnt2;
initial begin
    # 111 rx_lp_data <= 8'he1;
    # 640 rx_lp_data <= 8'h08;
    # 640 rx_lp_data <= 8'h58; // 1391 ns
    # 1639 rx_lp_data <= 8'h00; // 3030 ns
    # 21 rx_lp_data <= 8'hc3; // 3051 ns
    # 640 rx_lp_data <= 8'h01; // 3691 ns
    for(mycnt2 = 0; mycnt2 < 8; mycnt2 = mycnt2 + 1) begin
        # 640 rx_lp_data <= rx_lp_data + 8'd1;
    end
end

initial begin
    fork
        # 9110 tx_lp_ready <= 1'b0;
        # 9750 tx_lp_ready <= 1'b1;
    join
end

initial begin
    # 9051 tx_valid <= 1'b1;
    # 20 tx_valid <= 1'b0;
end
`endif


/********************** case 2 **********************/
`ifdef CASE2
initial begin
    ms <= 1'b1;
    time_threshold <= 16'd800;
end

initial begin
    # 16151 rx_lp_sop <= 1'b1;
end

initial begin
    # 16151 rx_lp_eop <= 1'b1;
end

initial begin
    # 16151 rx_lp_valid <= 1'b1;
    # 20 rx_lp_valid <= 1'b0;
end

initial begin
    # 16151 rx_lp_data <= 8'hd2;
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

initial begin
    # 100;
    tx_pid <= 4'b0001;
    tx_addr <= 7'h08;
end

initial begin
    # 111 tx_valid <= 1'b1;
    # 20 tx_valid <= 1'b0;
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

integer mycnt2;
initial begin
    # 4851 tx_lt_data <= 8'hc3;
    # 20 tx_lt_data <= 8'h01; // 4871 ns
    # 20 tx_lt_data <= 8'h02; // 4891 ns
    for(mycnt2 = 0; mycnt2 < 13; mycnt2 = mycnt2 + 1) begin
        # 660 tx_lt_data <= tx_lt_data + 8'd1;
    end
end
`endif


/********************** case 3 **********************/
`ifdef CASE3
initial begin
    ms <= 1'b1;
    time_threshold <= 16'd800;
end

initial begin
    fork
        # 4851 rx_lp_sop <= 1'b1;
        # 5491 rx_lp_sop <= 1'b0;
    join
end

initial begin
    # 10611 rx_lp_eop <= 1'b1;
end

integer mycnt1;
initial begin
    # 4851 rx_lp_valid <= 1'b1;
    # 20 rx_lp_valid <= 1'b0; // 4871 ns
    for(mycnt1 = 0; mycnt1 < 9; mycnt1 = mycnt1 + 1) begin
        # 620 rx_lp_valid <= 1'b1;
        # 20 rx_lp_valid <= 1'b0;
    end
end

integer mycnt2;
initial begin
    # 4851 rx_lp_data <= 8'hc3;
    # 640 rx_lp_data <= 8'h01; // 5491 ns
    for(mycnt2 = 0; mycnt2 < 8; mycnt2 = mycnt2 + 1) begin
        # 640 rx_lp_data <= rx_lp_data + 8'd1;
    end
end

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
        # 100 tx_pid <= 4'b1001;
        # 12630 tx_pid <= 4'b0010;
    join
end

initial begin
    fork
        # 100 tx_addr <= 7'h08;
        # 12630 tx_addr <= 7'h00;
    join
end

initial begin
    fork
        # 111 tx_valid <= 1'b1;
        # 131 tx_valid <= 1'b0;
        # 12651 tx_valid <= 1'b1;
        # 12671 tx_valid <= 1'b0;
    join
end
`endif

`ifdef FSDB
initial begin
	$fsdbDumpfile("tb_usb_case3.fsdb");
	$fsdbDumpvars;
end
`endif

endmodule
