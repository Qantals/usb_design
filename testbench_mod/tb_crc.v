`timescale 1ns / 1ps
`define EXAMPLE_CRC5
`define EXAMPLE3
// `define BAD1

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
wire crc16_err;
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


// instantiation
usb_link usb_link_u0(
    .clk             ( clk             ),
    .rst_n           ( rst_n           ),
    .self_addr       ( self_addr       ),
    .crc5_err        ( crc5_err        ),
    .crc16_err       ( crc16_err       ),
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


/********************** case CRC16 **********************/
`ifdef EXAMPLE_CRC16
// based on case1
// test correctness of CRC16, support any DATA0 length
initial begin
    ms <= 1'b0;
    time_threshold <= 16'd800;
end

/* example 1 */
`ifdef EXAMPLE1
`define DATA_LEN 6
reg [7:0] rx_lp_data_values [0:5];
integer i;
initial begin
    rx_lp_data_values[0] = 8'h82;
    rx_lp_data_values[1] = 8'h65;
    rx_lp_data_values[2] = 8'h90;
    rx_lp_data_values[3] = 8'h16;
    rx_lp_data_values[4] = 8'h2a;
    rx_lp_data_values[5] = 8'h72;
end
`endif

/* example 2 */
`ifdef EXAMPLE2
`define DATA_LEN 7
reg [7:0] rx_lp_data_values [0:6];
integer i;
initial begin
    rx_lp_data_values[0] = 8'h01;
    rx_lp_data_values[1] = 8'h02;
    rx_lp_data_values[2] = 8'h03;
    rx_lp_data_values[3] = 8'h04;
    rx_lp_data_values[4] = 8'h05;
    rx_lp_data_values[5] = 8'hd5;
    rx_lp_data_values[6] = 8'h44;
end
`endif


/* example 3 */
`ifdef EXAMPLE3
`define DATA_LEN 7
reg [7:0] rx_lp_data_values [0:6];
integer i;
initial begin
    rx_lp_data_values[0] = 8'h03;
    rx_lp_data_values[1] = 8'h04;
    rx_lp_data_values[2] = 8'h05;
    rx_lp_data_values[3] = 8'h06;
    rx_lp_data_values[4] = 8'h07;
    rx_lp_data_values[5] = 8'hcc;
    rx_lp_data_values[6] = 8'hac;
end
`endif

/* bad 1 */
`ifdef BAD1
`define DATA_LEN 7
reg [7:0] rx_lp_data_values [0:6];
integer i;
initial begin
    rx_lp_data_values[0] = 8'h01;
    rx_lp_data_values[1] = 8'h02;
    rx_lp_data_values[2] = 8'h03;
    rx_lp_data_values[3] = 8'h04;
    rx_lp_data_values[4] = 8'h05;
    rx_lp_data_values[5] = 8'h44;
    rx_lp_data_values[6] = 8'hd5;
end
`endif


initial begin
    #100;
    @(posedge clk);
    #1;
    rx_lp_sop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'b11100001; // PID = OUT TOKEN
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    repeat (31) @(posedge clk);
    #1;
    rx_lp_sop <= 0;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'h08; // addr = 4'h8, endp = 4'h0, crc = 5'h01100
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    repeat (31) @(posedge clk);
    #1;
    rx_lp_eop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'h60;
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    repeat (81) @(posedge clk);
    rx_lp_eop <= 0;
    rx_lp_data <= 8'd0;
    @(posedge clk);
    #1;
    rx_lp_sop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'b11000011; // PID = DATA0
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    repeat (31) @(posedge clk);
    #1;
    rx_lp_sop <= 0;
    rx_lp_valid <= 1;
    rx_lp_data <= rx_lp_data_values[0];
    for (i = 1; i <= `DATA_LEN - 1; i = i + 1) begin
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (31) @(posedge clk);
        #1;
        rx_lp_valid <= 1;
        rx_lp_data <= rx_lp_data_values[i];
    end
    rx_lp_eop <= 1;
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    repeat (10) @(posedge clk);
    `ifdef BAD1
    tx_pid <= 4'b1010; // PID = NAK
    `else
    tx_pid <= 4'b0010; // PID = ACK
    `endif       

    tx_addr <= 7'd8;
    @(posedge clk);
    #1;
    tx_valid <= 1;
    @(posedge clk);
    #1;
    tx_valid <= 0;
    repeat (2) @(posedge clk);
    tx_lp_ready <= 0;
    repeat (32) @(posedge clk);
    tx_lp_ready <= 1;
end
`endif


/********************** case CRC5 **********************/
`ifdef EXAMPLE_CRC5
// based on case 0
initial begin
    ms <= 1'b0;
    time_threshold <= 16'd200;
end

reg [7:0] tx_lt_data_values [0:8];
integer i;

initial begin
    tx_lt_data_values[0] = 8'h01;
    tx_lt_data_values[1] = 8'h02;
    tx_lt_data_values[2] = 8'h03;
    tx_lt_data_values[3] = 8'h04;
    tx_lt_data_values[4] = 8'h05;
    tx_lt_data_values[5] = 8'h06;
    tx_lt_data_values[6] = 8'h07;
    tx_lt_data_values[7] = 8'he2;
    tx_lt_data_values[8] = 8'h8e;
end

reg [7:0] rx_lp_data_values [0:1];

// example 1
`ifdef EXAMPLE1
initial begin
    rx_lp_data_values[0] = 8'h88;
    rx_lp_data_values[1] = 8'hf9;
end
`endif

// example 2
`ifdef EXAMPLE2
initial begin
    rx_lp_data_values[0] = 8'h08;
    rx_lp_data_values[1] = 8'h32;
end
`endif

// example 3
`ifdef EXAMPLE3
initial begin
    self_addr <= 7'd4;
    rx_lp_data_values[0] = 8'h04;
    rx_lp_data_values[1] = 8'h7a;
end
`endif

// bad 1
`ifdef BAD1
initial begin
    rx_lp_data_values[0] = 8'h08;
    rx_lp_data_values[1] = 8'hD0;
end
`endif

// slave rx TOKEN IN
initial begin
    #100;
    @(posedge clk);
    #1;
    rx_lp_sop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'b01101001; // PID = IN TOKEN
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    repeat (31) @(posedge clk);
    #1;
    rx_lp_sop <= 0;
    rx_lp_valid <= 1;
    rx_lp_data <= rx_lp_data_values[0];
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    repeat (31) @(posedge clk);
    #1;
    rx_lp_eop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= rx_lp_data_values[1];
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;


    `ifdef BAD1
    `else
    @(posedge clk);
    #1;
    tx_lt_sop <= 1;
    tx_lt_valid <= 1;
    tx_lt_data <= 8'b11000011; // PID = DATA0
    @(posedge clk);
    #1;
    tx_lt_sop <= 0;
    tx_lt_data <= tx_lt_data_values[0];
    @(posedge clk);
    tx_lp_ready <= 0;
    #1;
    tx_lt_data <= tx_lt_data_values[1];
    for (i = 2; i <= 8; i = i + 1) begin
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_data <= tx_lt_data_values[i];
    end
    tx_lt_eop <= 1;
    repeat (32) @(posedge clk);
    tx_lp_ready <= 1;
    @(posedge clk);
    tx_lp_ready <= 0;
    #1;
    tx_lt_valid <= 0;
    repeat (32) @(posedge clk);
    tx_lp_ready <= 1;
    @(posedge clk);
    tx_lp_ready <= 0;
    repeat (32) @(posedge clk);
    tx_lp_ready <= 1;
    repeat (49) @(posedge clk);
    rx_lp_eop <= 0;
    rx_lp_data <= 8'd0;
    @(posedge clk);
    #1;
    rx_lp_sop <= 1;
    rx_lp_eop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'b11010010; // PID = ACK
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    `endif
end
`endif




`ifdef FSDB
initial begin
	$fsdbDumpfile("tb_usb_case3.fsdb");
	$fsdbDumpvars;
end
`endif

endmodule
