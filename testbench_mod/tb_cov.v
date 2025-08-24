`timescale 1ns / 1ps
//`define CANCLE_RST_DATA

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



`ifdef CANCLE_RST_DATA
initial begin
    # 22670;
    $finish;
end

initial begin
    ms <= 1'b0;
    time_threshold <= 16'd200;
end

reg [7:0] tx_lt_data_values [0:8];
integer i;

initial begin
    tx_lt_data_values[0] = 8'h01;
    tx_lt_data_values[1] = 8'h02;
    tx_lt_data_values[2] = 8'b11110000;
    tx_lt_data_values[3] = 8'b11100000;
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
    /*********** new add **********/
    tx_lt_cancle <= 1;
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    /*********** new add **********/
    tx_lt_cancle <= 0;
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
    // for (i = 2; i <= 8; i = i + 1) begin
    for (i = 2; i <= 4; i = i + 1) begin
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_data <= tx_lt_data_values[i];
    end
    tx_lt_cancle <= 1;
    repeat (32) @(posedge clk);
    tx_lp_ready <= 1;
    @(posedge clk);
    tx_lp_ready <= 0;
    #1;
    tx_lt_cancle <= 0;
    repeat (10) @(posedge clk);
    rst_n <= 0;
    repeat (10) @(posedge clk);
    rst_n <= 1;

end
`endif



`ifdef ITER_TOKENTX
// initial begin
//     # 22670;
//     $finish;
// end

initial begin
    ms <= 1'b1;
    time_threshold <= 16'd800;
end

integer i;
reg [3:0] pid;
reg [6:0] addr;
reg [3:0] endp;

initial begin
    #100;


    for (pid = 4'b0000; pid != 4'b1111; pid = pid + 1) begin
        tx_pid <= pid;
        tx_addr <= 7'b1001000;
        tx_endp <= 4'b1111;
        @(posedge clk);
        #1;
        tx_valid <= 1;
        @(posedge clk);
        #1;
        tx_valid <= 0;
        // @(posedge clk);
        repeat (3) begin
            @(posedge clk);
            tx_lp_ready <= 0;
            repeat (5) @(posedge clk);
            tx_lp_ready <= 1;
        end
        repeat (5) @(posedge clk);
        rst_n <= 0;
        repeat (5) @(posedge clk);
        rst_n <= 1;
        repeat (5) @(posedge clk);
    end

    for (addr = 7'b0000000; addr != 7'b1111111; addr = addr + 1) begin
        tx_pid <= 4'b1111;
        tx_addr <= addr;
        tx_endp <= 4'b0000;
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
            repeat (5) @(posedge clk);
            tx_lp_ready <= 1;
        end
        repeat (5) @(posedge clk);
        rst_n <= 0;
        repeat (5) @(posedge clk);
        rst_n <= 1;
        repeat (5) @(posedge clk);
    end

    for (endp = 4'b0000; endp != 4'b1111; endp = endp + 1) begin
        tx_pid <= 4'b0001; // PID = OUT
        tx_addr <= 7'b1111111;
        tx_endp <= endp;
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
            repeat (5) @(posedge clk);
            tx_lp_ready <= 1;
        end
        repeat (5) @(posedge clk);
        rst_n <= 0;
        repeat (5) @(posedge clk);
        rst_n <= 1;
        repeat (5) @(posedge clk);
    end


    $finish;
end
`endif


/********************** case 2 **********************/
`ifdef ITER_HANDSHAKETX
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

reg [3:0] handshake;

initial begin
    #100;


    for (handshake = 4'b0000; handshake != 4'b1111; handshake = handshake + 1) begin
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
            repeat (3) @(posedge clk);
            tx_lp_ready <= 1;
        end
        repeat (3) @(posedge clk);
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
            repeat (3) @(posedge clk);
            tx_lp_ready <= 1;
            @(posedge clk);
            tx_lp_ready <= 0;
            #1;
            tx_lt_data <= tx_lt_data_values[i];
        end
        tx_lt_eop <= 1;
        repeat (3) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_valid <= 0;
        repeat (3) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        repeat (3) @(posedge clk);
        tx_lp_ready <= 1;
        repeat (3) @(posedge clk);
        #1;
        rx_lp_sop <= 1;
        rx_lp_eop <= 1;
        rx_lp_valid <= 1;
        rx_lp_data <= handshake; // PID = ACK?
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        @(posedge clk);
        rst_n <= 0;
        repeat(5) @(posedge clk);
        rst_n <= 1;
        repeat(5) @(posedge clk);
    end


    $finish;
end
`endif


// CASE0
`ifdef ITER_TOKENRX
// initial begin
//     # 22670;
//     $finish;
// end

initial begin
    ms <= 1'b1;
    time_threshold <= 16'd800;
end

integer i;
reg [3:0] pid;
reg [6:0] addr;
reg [3:0] endp;

initial begin
    #100;

    // wrong PID check
    @(posedge clk);
    #1;
    rx_lp_sop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= {4'b0000, 4'b1001}; // PID?
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    repeat (3) @(posedge clk);
    #1;
    rx_lp_sop <= 0;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'h08;
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    repeat (3) @(posedge clk);
    #1;
    rx_lp_eop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'h60;
    @(posedge clk);
    #1;
    rx_lp_valid <= 0;
    @(posedge clk);
    #1;
    rst_n <= 0;
    repeat (5) @(posedge clk);
    rst_n <= 1;
    repeat (5) @(posedge clk);

    for (pid = 4'b0000; pid != 4'b1111; pid = pid + 1) begin
        @(posedge clk);
        #1;
        rx_lp_sop <= 1;
        rx_lp_valid <= 1;
        rx_lp_data <= {~pid, pid}; // PID?
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (3) @(posedge clk);
        #1;
        rx_lp_sop <= 0;
        rx_lp_valid <= 1;
        rx_lp_data <= 8'h08;
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (3) @(posedge clk);
        #1;
        rx_lp_eop <= 1;
        rx_lp_valid <= 1;
        rx_lp_data <= 8'h60;
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        @(posedge clk);
        #1;
        rst_n <= 0;
        repeat (5) @(posedge clk);
        rst_n <= 1;
        repeat (5) @(posedge clk);
    end

    rst_n <= 0;
    self_addr <= 7'h0;
    repeat (5) @(posedge clk);
    rst_n <= 1;
    repeat (5) @(posedge clk);
    for (addr = 7'b0000000; addr != 7'b1111111; addr = addr + 1) begin
        @(posedge clk);
        #1;
        rx_lp_sop <= 1;
        rx_lp_valid <= 1;
        rx_lp_data <= 8'b01101001; // PID
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (3) @(posedge clk);
        #1;
        rx_lp_sop <= 0;
        rx_lp_valid <= 1;
        rx_lp_data <= {1'b0, addr};
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (3) @(posedge clk);
        #1;
        rx_lp_eop <= 1;
        rx_lp_valid <= 1;
        rx_lp_data <= 8'h60;
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        @(posedge clk);
        #1;
        rst_n <= 0;
        /*************** new add ************/
        self_addr <= addr;
        repeat (5) @(posedge clk);
        rst_n <= 1;
        repeat (5) @(posedge clk);
    end

    rst_n <= 0;
    self_addr <= 7'h8;
    repeat (5) @(posedge clk);
    rst_n <= 1;
    repeat (5) @(posedge clk);
    for (endp = 4'b0000; endp != 4'b1111; endp = endp + 1) begin
        @(posedge clk);
        #1;
        rx_lp_sop <= 1;
        rx_lp_valid <= 1;
        rx_lp_data <= 8'b01101001; // PID
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (3) @(posedge clk);
        #1;
        rx_lp_sop <= 0;
        rx_lp_valid <= 1;
        rx_lp_data <= {endp[0], 7'h8};
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (3) @(posedge clk);
        #1;
        rx_lp_eop <= 1;
        rx_lp_valid <= 1;
        rx_lp_data <= {5'h0, endp[3:1]};
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        @(posedge clk);
        #1;
        rst_n <= 0;
        repeat (5) @(posedge clk);
        rst_n <= 1;
        repeat (5) @(posedge clk);
    end


    $finish;
end
`endif



/********************** case 0 **********************/
`ifdef CASE01230

reg [7:0] tx_lt_data_values0 [0:8];
integer i;
initial begin
    tx_lt_data_values0[0] = 8'h01;
    tx_lt_data_values0[1] = 8'h02;
    tx_lt_data_values0[2] = 8'h03;
    tx_lt_data_values0[3] = 8'h04;
    tx_lt_data_values0[4] = 8'h05;
    tx_lt_data_values0[5] = 8'h06;
    tx_lt_data_values0[6] = 8'h07;
    tx_lt_data_values0[7] = 8'he2;
    tx_lt_data_values0[8] = 8'h8e;
end
reg [7:0] tx_lt_data_values1 [0:8];
initial begin
    tx_lt_data_values1[0] = 8'h01;
    tx_lt_data_values1[1] = 8'h02;
    tx_lt_data_values1[2] = 8'h03;
    tx_lt_data_values1[3] = 8'h04;
    tx_lt_data_values1[4] = 8'h05;
    tx_lt_data_values1[5] = 8'h06;
    tx_lt_data_values1[6] = 8'h07;
    tx_lt_data_values1[7] = 8'he2;
    tx_lt_data_values1[8] = 8'h8e;
end
reg [7:0] tx_lt_data_values2 [0:14];
initial begin
    tx_lt_data_values2[0] = 8'h01;
    tx_lt_data_values2[1] = 8'h02;
    tx_lt_data_values2[2] = 8'h03;
    tx_lt_data_values2[3] = 8'h04;
    tx_lt_data_values2[4] = 8'h05;
    tx_lt_data_values2[5] = 8'h06;
    tx_lt_data_values2[6] = 8'h07;
    tx_lt_data_values2[7] = 8'h08;
    tx_lt_data_values2[8] = 8'h09;
    tx_lt_data_values2[9] = 8'h0a;
    tx_lt_data_values2[10] = 8'h0b;
    tx_lt_data_values2[11] = 8'h0c;
    tx_lt_data_values2[12] = 8'h0d;
    tx_lt_data_values2[13] = 8'heb;
    tx_lt_data_values2[14] = 8'hef;
end
reg [7:0] tx_lt_data_values3 [0:8];
initial begin
    tx_lt_data_values3[0] = 8'h01;
    tx_lt_data_values3[1] = 8'h02;
    tx_lt_data_values3[2] = 8'h03;
    tx_lt_data_values3[3] = 8'h04;
    tx_lt_data_values3[4] = 8'h05;
    tx_lt_data_values3[5] = 8'h06;
    tx_lt_data_values3[6] = 8'h07;
    tx_lt_data_values3[7] = 8'he2;
    tx_lt_data_values3[8] = 8'h8e;
end

// slave rx TOKEN IN
initial begin
    ms <= 1'b0;
    time_threshold <= 16'd200;
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
    tx_lt_data <= tx_lt_data_values0[0];
    @(posedge clk);
    tx_lp_ready <= 0;
    #1;
    tx_lt_data <= tx_lt_data_values0[1];
    for (i = 2; i <= 8; i = i + 1) begin
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_data <= tx_lt_data_values0[i];
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

    /************************* RESET ***********************/
    rst_n <= 0;
    ms <= 1'b0;
    time_threshold <= 16'd800;
    repeat (5) @(posedge clk);
    rst_n <= 1;
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
    rx_lp_data <= tx_lt_data_values1[0];
    for (i = 1; i <= 8; i = i + 1) begin
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (31) @(posedge clk);
        #1;
        rx_lp_valid <= 1;
        rx_lp_data <= tx_lt_data_values1[i];
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



    /************************* RESET ***********************/
    rst_n <= 0;
    ms <= 1'b1;
    time_threshold <= 16'd800;
    tx_pid <= 4'b0001; // PID = OUT
    tx_addr <= 7'd8;
    repeat (5) @(posedge clk);
    rst_n <= 1;
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
    tx_lt_data <= tx_lt_data_values2[0];
    @(posedge clk);
    tx_lp_ready <= 0;
    #1;
    tx_lt_data <= tx_lt_data_values2[1];
    for (i = 2; i <= 14; i = i + 1) begin
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_data <= tx_lt_data_values2[i];
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


    /************************* RESET ***********************/
    rst_n <= 0;
    ms <= 1'b1;
    time_threshold <= 16'd800;
    tx_pid <= 4'b1001; // PID = IN TOKEN
    tx_addr <= 7'h08;
    repeat (5) @(posedge clk);
    rst_n <= 1;

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
    rx_lp_data <= tx_lt_data_values3[0];
    for (i = 1; i <= 8; i = i + 1) begin
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (31) @(posedge clk);
        #1;
        rx_lp_valid <= 1;
        rx_lp_data <= tx_lt_data_values3[i];
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

    /************************* RESET ***********************/
    rst_n <= 0;
    ms <= 1'b0;
    time_threshold <= 16'd200;
    repeat (5) @(posedge clk);
    rst_n <= 1;

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
    tx_lt_data <= tx_lt_data_values0[0];
    @(posedge clk);
    tx_lp_ready <= 0;
    #1;
    tx_lt_data <= tx_lt_data_values0[1];
    for (i = 2; i <= 8; i = i + 1) begin
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_data <= tx_lt_data_values0[i];
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

    $finish;
end
`endif



`ifdef MS
// invert ms from CASE01230
reg [7:0] tx_lt_data_values0 [0:8];
integer i;
initial begin
    tx_lt_data_values0[0] = 8'h01;
    tx_lt_data_values0[1] = 8'h02;
    tx_lt_data_values0[2] = 8'h03;
    tx_lt_data_values0[3] = 8'h04;
    tx_lt_data_values0[4] = 8'h05;
    tx_lt_data_values0[5] = 8'h06;
    tx_lt_data_values0[6] = 8'h07;
    tx_lt_data_values0[7] = 8'he2;
    tx_lt_data_values0[8] = 8'h8e;
end
reg [7:0] tx_lt_data_values1 [0:8];
initial begin
    tx_lt_data_values1[0] = 8'h01;
    tx_lt_data_values1[1] = 8'h02;
    tx_lt_data_values1[2] = 8'h03;
    tx_lt_data_values1[3] = 8'h04;
    tx_lt_data_values1[4] = 8'h05;
    tx_lt_data_values1[5] = 8'h06;
    tx_lt_data_values1[6] = 8'h07;
    tx_lt_data_values1[7] = 8'he2;
    tx_lt_data_values1[8] = 8'h8e;
end
reg [7:0] tx_lt_data_values2 [0:14];
initial begin
    tx_lt_data_values2[0] = 8'h01;
    tx_lt_data_values2[1] = 8'h02;
    tx_lt_data_values2[2] = 8'h03;
    tx_lt_data_values2[3] = 8'h04;
    tx_lt_data_values2[4] = 8'h05;
    tx_lt_data_values2[5] = 8'h06;
    tx_lt_data_values2[6] = 8'h07;
    tx_lt_data_values2[7] = 8'h08;
    tx_lt_data_values2[8] = 8'h09;
    tx_lt_data_values2[9] = 8'h0a;
    tx_lt_data_values2[10] = 8'h0b;
    tx_lt_data_values2[11] = 8'h0c;
    tx_lt_data_values2[12] = 8'h0d;
    tx_lt_data_values2[13] = 8'heb;
    tx_lt_data_values2[14] = 8'hef;
end
reg [7:0] tx_lt_data_values3 [0:8];
initial begin
    tx_lt_data_values3[0] = 8'h01;
    tx_lt_data_values3[1] = 8'h02;
    tx_lt_data_values3[2] = 8'h03;
    tx_lt_data_values3[3] = 8'h04;
    tx_lt_data_values3[4] = 8'h05;
    tx_lt_data_values3[5] = 8'h06;
    tx_lt_data_values3[6] = 8'h07;
    tx_lt_data_values3[7] = 8'he2;
    tx_lt_data_values3[8] = 8'h8e;
end

// slave rx TOKEN IN
initial begin
    ms <= 1'b1;
    time_threshold <= 16'd200;
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
    tx_lt_data <= tx_lt_data_values0[0];
    @(posedge clk);
    tx_lp_ready <= 0;
    #1;
    tx_lt_data <= tx_lt_data_values0[1];
    for (i = 2; i <= 8; i = i + 1) begin
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_data <= tx_lt_data_values0[i];
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

    /************************* RESET ***********************/
    rst_n <= 0;
    ms <= 1'b1;
    time_threshold <= 16'd800;
    repeat (5) @(posedge clk);
    rst_n <= 1;
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
    rx_lp_data <= tx_lt_data_values1[0];
    for (i = 1; i <= 8; i = i + 1) begin
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (31) @(posedge clk);
        #1;
        rx_lp_valid <= 1;
        rx_lp_data <= tx_lt_data_values1[i];
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



    /************************* RESET ***********************/
    rst_n <= 0;
    ms <= 1'b0;
    time_threshold <= 16'd800;
    tx_pid <= 4'b0001; // PID = OUT
    tx_addr <= 7'd8;
    repeat (5) @(posedge clk);
    rst_n <= 1;
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
    tx_lt_data <= tx_lt_data_values2[0];
    @(posedge clk);
    tx_lp_ready <= 0;
    #1;
    tx_lt_data <= tx_lt_data_values2[1];
    for (i = 2; i <= 14; i = i + 1) begin
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_data <= tx_lt_data_values2[i];
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


    /************************* RESET ***********************/
    rst_n <= 0;
    ms <= 1'b0;
    time_threshold <= 16'd800;
    tx_pid <= 4'b1001; // PID = IN TOKEN
    tx_addr <= 7'h08;
    repeat (5) @(posedge clk);
    rst_n <= 1;

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
    rx_lp_data <= tx_lt_data_values3[0];
    for (i = 1; i <= 8; i = i + 1) begin
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (31) @(posedge clk);
        #1;
        rx_lp_valid <= 1;
        rx_lp_data <= tx_lt_data_values3[i];
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

    /************************* RESET ***********************/
    rst_n <= 0;
    ms <= 1'b1;
    time_threshold <= 16'd200;
    repeat (5) @(posedge clk);
    rst_n <= 1;

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
    tx_lt_data <= tx_lt_data_values0[0];
    @(posedge clk);
    tx_lp_ready <= 0;
    #1;
    tx_lt_data <= tx_lt_data_values0[1];
    for (i = 2; i <= 8; i = i + 1) begin
        repeat (32) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_data <= tx_lt_data_values0[i];
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

    $finish;
end
`endif




/********************** case 0 **********************/
`ifdef TIMEOUT
initial begin
    ms <= 1'b0;
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
reg [15:0] timet;
reg [5:0] delayt;

// slave rx TOKEN IN
initial begin
    // max time_threshold
    time_threshold <= 16'hFFFF;
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

    // phase 3
    repeat (80000) @(posedge clk);
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


    // iter port timeout
    for (timet = 0; timet != 16'hFFFF; timet = timet + 1) begin
        time_threshold <= timet;
        rst_n <= 0;
        repeat(3) @(posedge clk);
        rst_n <= 1;
        repeat(3) @(posedge clk);
        #1;
        rx_lp_sop <= 1;
        rx_lp_valid <= 1;
        rx_lp_data <= 8'b01101001; // PID = IN TOKEN
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (5) @(posedge clk);
        #1;
        rx_lp_sop <= 0;
        rx_lp_valid <= 1;
        rx_lp_data <= 8'h08;
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (5) @(posedge clk);
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
            repeat (5) @(posedge clk);
            tx_lp_ready <= 1;
            @(posedge clk);
            tx_lp_ready <= 0;
            #1;
            tx_lt_data <= tx_lt_data_values[i];
        end
        tx_lt_eop <= 1;
        repeat (5) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_valid <= 0;
        repeat (5) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        repeat (5) @(posedge clk);
        tx_lp_ready <= 1;

        // phase 3
        repeat (10) @(posedge clk);
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
        repeat(5) @(posedge clk);
    end

    // iter port delay
    time_threshold <= 16'd200;
    for (delayt = 0; delayt != 6'b111111; delayt = delayt + 1) begin
        delay_threshole <= delayt;
        rst_n <= 0;
        repeat(3) @(posedge clk);
        rst_n <= 1;
        repeat(3) @(posedge clk);
        #1;
        rx_lp_sop <= 1;
        rx_lp_valid <= 1;
        rx_lp_data <= 8'b01101001; // PID = IN TOKEN
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (5) @(posedge clk);
        #1;
        rx_lp_sop <= 0;
        rx_lp_valid <= 1;
        rx_lp_data <= 8'h08;
        @(posedge clk);
        #1;
        rx_lp_valid <= 0;
        repeat (5) @(posedge clk);
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
            repeat (5) @(posedge clk);
            tx_lp_ready <= 1;
            @(posedge clk);
            tx_lp_ready <= 0;
            #1;
            tx_lt_data <= tx_lt_data_values[i];
        end
        tx_lt_eop <= 1;
        repeat (5) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        #1;
        tx_lt_valid <= 0;
        repeat (5) @(posedge clk);
        tx_lp_ready <= 1;
        @(posedge clk);
        tx_lp_ready <= 0;
        repeat (5) @(posedge clk);
        tx_lp_ready <= 1;

        // phase 3
        repeat (10) @(posedge clk);
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
        repeat(5) @(posedge clk);
    end

    $finish;
end
`endif



/********************** case 1 **********************/
`ifdef MS1
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
    $finish;
end
`endif


`ifdef FSDB
initial begin
    `ifdef CANCLE_RST_DATA
        $fsdbDumpfile("sim_cov_CANCLE_RST_DATA.fsdb");
    `elsif ITER_TOKENTX
        $fsdbDumpfile("sim_cov_ITER_TOKENTX.fsdb");
    `elsif ITER_HANDSHAKETX
        $fsdbDumpfile("sim_cov_ITER_HANDSHAKETX.fsdb");
    `elsif ITER_TOKENRX
        $fsdbDumpfile("sim_cov_ITER_TOKENRX.fsdb");
    `elsif CASE01230
        $fsdbDumpfile("sim_cov_CASE01230.fsdb");
    `elsif MS
        $fsdbDumpfile("sim_cov_MS.fsdb");
    `elsif TIMEOUT
        $fsdbDumpfile("sim_cov_TIMEOUT.fsdb");
    `elsif MS1
        $fsdbDumpfile("sim_cov_MS1.fsdb");
    `else
        $display("error CASE macro.\n")
    `endif
	$fsdbDumpvars;
end
`endif





endmodule
