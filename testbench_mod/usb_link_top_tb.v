`timescale 1ns / 1ps

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


/********************** case 0 **********************/
`ifdef CASE0
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
    rx_lp_data <= 8'h08;
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
end
`endif


/********************** case 1 **********************/
`ifdef CASE1
initial begin
    ms <= 1'b0;
    time_threshold <= 16'd800;
end

reg [7:0] rx_lp_data_values [0:8];
integer i;

initial begin
    rx_lp_data_values[0] = 8'h01;
    rx_lp_data_values[1] = 8'h02;
    rx_lp_data_values[2] = 8'h03;
    rx_lp_data_values[3] = 8'h04;
    rx_lp_data_values[4] = 8'h05;
    rx_lp_data_values[5] = 8'h06;
    rx_lp_data_values[6] = 8'h07;
    rx_lp_data_values[7] = 8'he2;
    rx_lp_data_values[8] = 8'h8e;
end


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
    rx_lp_data <= 8'h08;
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
    for (i = 1; i <= 8; i = i + 1) begin
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
    tx_pid <= 4'b0010; // PID = ACK
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


/********************** case 2 **********************/
`ifdef CASE2
initial begin
    ms <= 1'b1;
    time_threshold <= 16'd800;
end

reg [7:0] tx_lt_data_values [0:14];
integer i;

initial begin
    tx_lt_data_values[0] = 8'h01;
    tx_lt_data_values[1] = 8'h02;
    tx_lt_data_values[2] = 8'h03;
    tx_lt_data_values[3] = 8'h04;
    tx_lt_data_values[4] = 8'h05;
    tx_lt_data_values[5] = 8'h06;
    tx_lt_data_values[6] = 8'h07;
    tx_lt_data_values[7] = 8'h08;
    tx_lt_data_values[8] = 8'h09;
    tx_lt_data_values[9] = 8'h0a;
    tx_lt_data_values[10] = 8'h0b;
    tx_lt_data_values[11] = 8'h0c;
    tx_lt_data_values[12] = 8'h0d;
    tx_lt_data_values[13] = 8'heb;
    tx_lt_data_values[14] = 8'hef;
end

initial begin
    #100;
    tx_pid <= 4'b0001; // PID = OUT
    tx_addr <= 7'd8;
    @(posedge clk);
    #1;
    tx_valid <= 1;
    @(posedge clk);
    #1;
    tx_valid <= 0;
    @(posedge clk);
    repeat (3) begin
        @(posedge clk);
        tx_lp_ready <= 0;
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
    end
    repeat (136) @(posedge clk);
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
    for (i = 2; i <= 14; i = i + 1) begin
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
    repeat (36) @(posedge clk);
    #1;
    rx_lp_sop <= 1;
    rx_lp_eop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'b11010010; // PID = ACK
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
end
`endif




/********************** case 3 **********************/
`ifdef CASE3
initial begin
    ms <= 1'b1;
    time_threshold <= 16'd800;
end

reg [7:0] rx_lp_data_values [0:8];
integer i;

initial begin
    rx_lp_data_values[0] = 8'h01;
    rx_lp_data_values[1] = 8'h02;
    rx_lp_data_values[2] = 8'h03;
    rx_lp_data_values[3] = 8'h04;
    rx_lp_data_values[4] = 8'h05;
    rx_lp_data_values[5] = 8'h06;
    rx_lp_data_values[6] = 8'h07;
    rx_lp_data_values[7] = 8'he2;
    rx_lp_data_values[8] = 8'h8e;
end

initial begin
    #100;
    tx_pid <= 4'b1001; // PID = IN TOKEN
    tx_addr <= 7'h08;
    @(posedge clk);
    #1;
    tx_valid <= 1;
    @(posedge clk);
    #1;
    tx_valid <= 0;
    @(posedge clk);
    repeat (3) begin
        @(posedge clk);
        tx_lp_ready <= 0;
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
    end
    repeat (136) @(posedge clk);
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
    for (i = 1; i <= 8; i = i + 1) begin
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
    repeat (100) @(posedge clk);
    tx_pid <= 4'b0010; // PID = ACK
    tx_addr <= 0;
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



`ifdef FSDB
initial begin
    `ifdef CASE0
        $fsdbDumpfile("sim_CASE0.fsdb");
    `elsif CASE1
        $fsdbDumpfile("sim_CASE1.fsdb");
    `elsif CASE2
        $fsdbDumpfile("sim_CASE2.fsdb");
    `elsif CASE3
        $fsdbDumpfile("sim_CASE3.fsdb");
    `else
        $display("error CASE macro.\n")
    `endif
	$fsdbDumpvars;
end
`endif

endmodule
