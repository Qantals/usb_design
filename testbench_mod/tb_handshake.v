`timescale 1ns / 1ps
// `define HS0
// phy / link layer wait spacing, choose only one these below
// `define WAIT0 // lp > lt
// `define WAIT1 // lp < lt
// `define WAIT2 // lp = lt != 0
// `define WAIT3 // lp = lt = 0
// `define WAIT4 // lp = 0, lt != 0
// `define WAIT5 // lp != 0, lt = 0
// no WAIT define: custom (simulate original case)

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

// define handshake wait spacing
integer wait_lp, wait_lt;
initial begin
    `ifdef WAIT0
        // lp > lt
        wait_lp = 16;
        wait_lt = 10;
    `elsif WAIT1
        // lp < lt
        wait_lp = 10;
        wait_lt = 16;
    `elsif WAIT2
        // lp = lt != 0
        wait_lp = 10;
        wait_lt = 10;
    `elsif WAIT3
        // lp = lt = 0
        wait_lp = 0;
        wait_lt = 0;
    `elsif WAIT4
        // lp = 0, lt != 0
        wait_lp = 0;
        wait_lt = 10;
    `elsif WAIT5
        // lp != 0, lt = 0
        wait_lp = 10;
        wait_lt = 0;
    `else
        // custom
        `ifdef HS1
            wait_lp = 31;
        `elsif HS3
            wait_lp = 31;
        `else
            wait_lp = 32;
        `endif
        wait_lt = 0;
    `endif
end


/********************** case 0 **********************/
`ifdef HS0
initial begin
    ms <= 1'b0;
    time_threshold <= 16'd200;
end

reg [7:0] tx_lt_data_values [0:8];
integer i,j;

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

// automated data check
reg [7:0] check_data0 [0:2]; // TOKEN
reg [7:0] check_data1 [0:9]; // DATA0
reg [7:0] check_data2; // ACK

initial begin
    #100;
    @(posedge clk);
    #1;

    /* slave rx TOKEN IN */
    // handshake: phy:
    //      module output level rx_lp_ready
    //      module input pulse rx_lp_valid

    // byte 0: PID
    rx_lp_sop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'b01101001; // PID = IN TOKEN
    @(posedge clk);
    check_data0[0] <= rx_lp_data;
    #1;
    rx_lp_valid <= 0;
    repeat (wait_lp) @(posedge clk);
    #1;
    // byte 1: endp[0], addr
    rx_lp_sop <= 0;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'h08;
    @(posedge clk);
    check_data0[1] <= rx_lp_data;
    #1;
    rx_lp_valid <= 0;
    repeat (wait_lp) @(posedge clk);
    #1;
    // byte 2: crc, endp[3:1]
    rx_lp_eop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'h60;
    @(posedge clk);
    check_data0[2] <= rx_lp_data;
    #1;
    rx_lp_valid <= 0;
    // finish rx TOKEN IN

    /* slave tx DATA0 */
    // handshake: link layer:
    //      module output pulse tx_lt_ready from phy
    //      module input level tx_lt_valid
    // handshake: phy:
    //      module output level tx_lp_valid from link layer
    //      module input pulse tx_lp_ready

    fork
        begin // link layer
            @(posedge clk);
            #1;
            // link layer byte 0: PID
            tx_lt_sop <= 1;
            tx_lt_data <= 8'b11000011; // PID = DATA0
            tx_lt_valid <= 1;
            @(posedge clk); while(!tx_lt_ready) @(posedge clk);           
            #1;
            tx_lt_valid <= 0;
            repeat (wait_lt) @(posedge clk);
            #1;
            // link layer byte 1
            tx_lt_sop <= 0;
            tx_lt_data <= tx_lt_data_values[0];
            tx_lt_valid <= 1;
            for (i = 1; i <= 8; i = i + 1) begin // link layer byte 2 ~ 9
                @(posedge clk); while(!tx_lt_ready) @(posedge clk);           
                #1;
                tx_lt_valid <= 0;
                repeat (wait_lt) @(posedge clk);
                #1;
                // link layer byte i+1
                tx_lt_data <= tx_lt_data_values[i];
                tx_lt_valid <= 1;
            end
            // link layer byte 9
            tx_lt_eop <= 1;
            @(posedge clk); while(!tx_lt_ready) @(posedge clk);           
            #1;
            // link layer close
            tx_lt_valid <= 0;
        end

        begin // phy
            for (j = 0; j <= 9; j = j + 1) begin
                @(posedge clk); while(!tx_lp_valid) @(posedge clk);           
                // phy finish taking byte j, not ready for byte j+1 (byte 10 = empty)
                check_data1[j] <= tx_lp_data;
                tx_lp_ready <= 0;
                repeat (wait_lp) @(posedge clk);
                tx_lp_ready <= 1;
            end
        end
    // finish tx DATA0
    join

    /* slave rx ACK */
    // handshake: phy:
    //      module output level rx_lp_ready
    //      module input pulse rx_lp_valid

    // byte 0: PID
    repeat (49) @(posedge clk);
    // reset multi data
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
    check_data2 <= rx_lp_data;
    rx_lp_valid <= 0;
    repeat (30) @(posedge clk);
    $finish;
end
`endif


/********************** case 1 **********************/
`ifdef HS1
initial begin
    ms <= 1'b0;
    time_threshold <= 16'd800;
end

reg [7:0] rx_lp_data_values [0:8];
integer i,j;

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

// automated data check
reg [7:0] check_data0 [0:2]; // TOKEN
reg [7:0] check_data1 [0:9]; // DATA0
reg [7:0] check_data2; // ACK

initial begin
    #100;
    @(posedge clk);
    #1;

    /* slave rx TOKEN OUT */
    // handshake: phy:
    //      module output level rx_lp_ready
    //      module input pulse rx_lp_valid

    /* REFERENCE TO HS0 */
    // byte 0: PID
    rx_lp_sop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'b11100001; // PID = OUT TOKEN
    @(posedge clk);
    check_data0[0] <= rx_lp_data;
    #1;
    rx_lp_valid <= 0;
    // byte 1: endp[0], addr
    repeat (wait_lp) @(posedge clk);
    #1;
    rx_lp_sop <= 0;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'h08;
    @(posedge clk);
    check_data0[1] <= rx_lp_data;
    #1;
    rx_lp_valid <= 0;
    // byte 2: crc, endp[3:1]
    repeat (wait_lp) @(posedge clk);
    #1;
    rx_lp_eop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'h60;
    @(posedge clk);
    check_data0[2] <= rx_lp_data;
    #1;
    rx_lp_valid <= 0;
    /* TODO: start timeout next clock count 0 to 0 */

    /* slave rx DATA0 */
    // handshake: phy:
    //      module output level rx_lp_ready, from link layer
    //      module input pulse rx_lp_valid
    // handshake: link layer:
    //      module output pulse rx_lt_valid, from phy
    //      module input level rx_lt_ready

    /* REFERENCE TO HS3 */
    repeat (10) @(posedge clk);
    // phy reset
    rx_lp_eop <= 0;
    rx_lp_data <= 8'd0;

    fork
        begin // phy
            @(posedge clk);
            #1;
            rx_lp_sop <= 1;
            rx_lp_data <= 8'b11000011; // PID = DATA0
            rx_lp_valid <= 1;
            @(posedge clk); while(!rx_lp_ready) @(posedge clk);           
            /* TODO: stop timeout */
            #1;
            rx_lp_valid <= 0;
            repeat (wait_lp) @(posedge clk);
            #1;
            rx_lp_sop <= 0;
            rx_lp_data <= rx_lp_data_values[0];
            rx_lp_valid <= 1;
            for (i = 1; i <= 8; i = i + 1) begin
                @(posedge clk); while(!rx_lp_ready) @(posedge clk);           
                #1;
                rx_lp_valid <= 0;
                repeat (wait_lp) @(posedge clk);
                #1;
                rx_lp_data <= rx_lp_data_values[i];
                rx_lp_valid <= 1;
            end
            rx_lp_eop <= 1;
            @(posedge clk); while(!rx_lp_ready) @(posedge clk);           
            #1;
            rx_lp_valid <= 0;
        end

        begin // link layer
            for (j = 0; j <= 9; j = j + 1) begin
                 @(posedge clk); while(!rx_lt_valid) @(posedge clk);           
                check_data1[j] <= rx_lt_data;
                rx_lt_ready <= 0;               
                repeat (wait_lt) @(posedge clk);
                rx_lt_ready <= 1;
            end
        end
    join


    /* slave tx ACK */
    // handshake: link layer:
    //      module output pulse tx_ready, from phy
    //      module input pulse (one package level) tx_valid
    // handshake: phy:
    //      module output pulse (one package level) tx_lp_valid, from link layer
    //      module input pulse tx_lp_ready

    /* REFERENCE TO HS3 */
    repeat (20) @(posedge clk);
    tx_pid <= 4'b0010; // PID = ACK
    tx_addr <= 7'd8;
    // @(posedge clk);
    // #1;
    tx_valid <= 1;
    @(posedge clk);
    #1;
    tx_valid <= 0;
    repeat (2) @(posedge clk);
    /* TODO: start dealy count 0 to 0, 9110ns */
    check_data2 <= tx_lp_data;
    tx_lp_ready <= 0;
    repeat (wait_lp) @(posedge clk);
    tx_lp_ready <= 1;
    repeat (30) @(posedge clk);
    $finish;
end
`endif


/********************** case 2 **********************/
`ifdef HS2
initial begin
    ms <= 1'b1;
    time_threshold <= 16'd800;
end

reg [7:0] tx_lt_data_values [0:14];
integer i,j;

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

// automated data check
reg [7:0] check_data0 [0:2]; // TOKEN
reg [7:0] check_data1 [0:15]; // DATA0
reg [7:0] check_data2; // ACK

initial begin
    #100;

    /* master tx TOKEN OUT */
    // handshake: link layer:
    //      module output pulse tx_ready from phy
    //      module input pulse (one package level) tx_valid
    // handshake: phy:
    //      module output level tx_lp_valid from link_control
    //      module input pulse tx_lp_ready

    /* REFERENCE TO HS3 */
    tx_pid <= 4'b0001; // PID = OUT
    tx_addr <= 7'd8;
    // @(posedge clk);
    // #1;
    tx_valid <= 1;
    @(posedge clk);
    #1;
    tx_valid <= 0;
    @(posedge clk);
    for (i = 0; i <= 2; i = i + 1) begin
        @(posedge clk);
        check_data0[i] <= tx_lp_data;
        tx_lp_ready <= 0;
        repeat (wait_lp) @(posedge clk);
        tx_lp_ready <= 1;
    end

    /* master tx DATA0 */
    // handshake: link layer:
    //      module output pulse tx_lt_ready from phy
    //      module input level tx_lt_valid
    // handshake: phy:
    //      module output level tx_lp_valid from link layer
    //      module input pulse tx_lp_ready

    /* REFERENCE TO HS0 */
    repeat (20) @(posedge clk);
    fork
        begin // link layer
            @(posedge clk);
            #1;
            tx_lt_sop <= 1;
            tx_lt_data <= 8'b11000011; // PID = DATA0
            tx_lt_valid <= 1;
            @(posedge clk); while(!tx_lt_ready) @(posedge clk);           
            #1;
            tx_lt_valid <= 0;
            repeat (wait_lt) @(posedge clk);
            #1;
            tx_lt_sop <= 0;
            tx_lt_data <= tx_lt_data_values[0];
            tx_lt_valid <= 1;
            for (i = 1; i <= 14; i = i + 1) begin
                @(posedge clk); while(!tx_lt_ready) @(posedge clk);           
                #1;
                tx_lt_valid <= 0;
                repeat (wait_lt) @(posedge clk);
                #1;
                tx_lt_data <= tx_lt_data_values[i];
                tx_lt_valid <= 1;
            end
            tx_lt_eop <= 1;
            @(posedge clk); while(!tx_lt_ready) @(posedge clk);           
            #1;
            tx_lt_valid <= 0;
        end

        begin // phy
            for (j = 0; j <= 15; j = j + 1) begin
                @(posedge clk); while(!tx_lp_valid) @(posedge clk);           
                check_data1[j] <= tx_lp_data;
                tx_lp_ready <= 0;
                repeat (wait_lp) @(posedge clk);
                tx_lp_ready <= 1;
            end
        end
    join


    /* master rx ACK */
    // handshake: phy:
    //      module output level rx_lp_ready
    //      module input pulse rx_lp_valid

    /* REFERENCE TO HS0 */
    repeat (36) @(posedge clk);
    #1;
    rx_lp_sop <= 1;
    rx_lp_eop <= 1;
    rx_lp_valid <= 1;
    rx_lp_data <= 8'b11010010; // PID = ACK
    @(posedge clk);
    #1;
    check_data2 <= rx_lp_data;
    rx_lp_valid <= 0;
    repeat (30) @(posedge clk);
    $finish;
end
`endif




/********************** case 3 **********************/
`ifdef HS3
initial begin
    ms <= 1'b1;
    time_threshold <= 16'd800;
end

reg [7:0] rx_lp_data_values [0:8];
integer i,j;

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

// automated data check
reg [7:0] check_data0 [0:2]; // TOKEN
reg [7:0] check_data1 [0:9]; // DATA0
reg [7:0] check_data2; // ACK

initial begin
    #100;

    /* master tx TOKEN IN */
    // handshake: link layer:
    //      module output pulse tx_ready from phy
    //      module input pulse (one package level) tx_valid
    // handshake: phy:
    //      module output level tx_lp_valid from link layer
    //      module input pulse tx_lp_ready

    // link layer byte 0
    tx_pid <= 4'b1001; // PID = IN TOKEN
    tx_addr <= 7'h08;
    // @(posedge clk);
    // #1;
    tx_valid <= 1;
    @(posedge clk);
    #1;
    tx_valid <= 0;
    @(posedge clk);
    // phy byte 0
    for (i = 0; i <= 2; i = i + 1) begin
        @(posedge clk);
        // phy finish taking byte 0-1-2, not ready for byte 1-2-empty
        check_data0[i] <= tx_lp_data;
        tx_lp_ready <= 0;
        repeat (wait_lp) @(posedge clk);
        tx_lp_ready <= 1;
    end
    // phy finish

    /* master rx DATA0 */
    // handshake: phy:
    //      module output level rx_lp_ready from link layer
    //      module input pulse rx_lp_valid (with 1 ns)
    // handhake: link layer:
    //      module output pulse rx_lt_valid from phy
    //      module input level rx_lt_ready

    repeat (70) @(posedge clk); // delay control
    fork
        begin // phy
            @(posedge clk);
            #1;
            // phy byte 0: PID
            rx_lp_sop <= 1;
            rx_lp_data <= 8'b11000011; // PID = DATA0
            rx_lp_valid <= 1;
            @(posedge clk); while(!rx_lp_ready) @(posedge clk);           
            #1;
            rx_lp_valid <= 0;
            repeat (wait_lp) @(posedge clk);
            #1;
            // phy byte 1
            rx_lp_sop <= 0;
            rx_lp_data <= rx_lp_data_values[0];
            rx_lp_valid <= 1;
            for (i = 1; i <= 8; i = i + 1) begin // phy byte 2 ~ 9
                @(posedge clk); while(!rx_lp_ready) @(posedge clk);           
                #1;
                rx_lp_valid <= 0;
                repeat (wait_lp) @(posedge clk);
                #1;
                // phy byte i+1
                rx_lp_data <= rx_lp_data_values[i];
                rx_lp_valid <= 1;
            end
            // phy byte 9
            rx_lp_eop <= 1;
            @(posedge clk); while(!rx_lp_ready) @(posedge clk);           
            #1;
            // phy close
            rx_lp_valid <= 0;
        end

        begin // link layer
            for (j = 0; j <= 9; j = j + 1) begin
                 @(posedge clk); while(!rx_lt_valid) @(posedge clk);           
                // link layer finish taking byte j, not ready for byte j+1 (byte 10 = empty)
                check_data1[j] <= rx_lt_data;
                rx_lt_ready <= 0;               
                repeat (wait_lt) @(posedge clk);
                rx_lt_ready <= 1;
            end
        end
    // finish rx DATA0
    join

    // check data
    // if (check_data[0] != 8'b11000011)
    //     $display("find mismatch value: byte 0, check_data: 0x%0h, standard value: 0x%0h\n", check_data[0], 8'b11000011);
    // for(i = 1; i <= 9; i = i + 1) begin
    //     if (check_data[i] != rx_lp_data_values[i - 1])
    //         $display("find mismatch value: byte %0d, check_data: 0x%0h, standard value: 0x%0h\n",
    //             i, check_data[i], rx_lp_data_values[i - 1]);
    // end

    /* master tx ACK */
    // handshake: link layer:
    //      module output pulse tx_ready from phy
    //      module input pulse (one package level) tx_valid
    // handshake: phy:
    //      module output pulse (one package level) tx_lp_valid from link layer
    //      module input pulse tx_lp_ready

    repeat (20) @(posedge clk);
    // link layer byte 0: PID
    tx_pid <= 4'b0010; // PID = ACK
    tx_addr <= 0;
    // @(posedge clk);
    // #1;
    tx_valid <= 1;
    @(posedge clk);
    #1;
    tx_valid <= 0;
    // link layer finish
    // after one clock: phy byte 0
    repeat (2) @(posedge clk);
    check_data2 <= tx_lp_data;
    tx_lp_ready <= 0;
    // phy finish
    repeat (wait_lp) @(posedge clk);
    tx_lp_ready <= 1;
    repeat (30) @(posedge clk);
    $finish;
end
`endif

`ifdef FSDB
initial begin
    `ifdef HS0
        `ifdef WAIT0
            $fsdbDumpfile("sim_handshake_HS0_WAIT0.fsdb");
        `elsif WAIT1
            $fsdbDumpfile("sim_handshake_HS0_WAIT1.fsdb");
        `elsif WAIT2
            $fsdbDumpfile("sim_handshake_HS0_WAIT2.fsdb");
        `elsif WAIT3
            $fsdbDumpfile("sim_handshake_HS0_WAIT3.fsdb");
        `elsif WAIT4
            $fsdbDumpfile("sim_handshake_HS0_WAIT4.fsdb");
        `elsif WAIT5
            $fsdbDumpfile("sim_handshake_HS0_WAIT5.fsdb");
        `else
            $fsdbDumpfile("sim_handshake_HS0.fsdb");
        `endif

    `elsif HS1
        `ifdef WAIT0
            $fsdbDumpfile("sim_handshake_HS1_WAIT0.fsdb");
        `elsif WAIT1
            $fsdbDumpfile("sim_handshake_HS1_WAIT1.fsdb");
        `elsif WAIT2
            $fsdbDumpfile("sim_handshake_HS1_WAIT2.fsdb");
        `elsif WAIT3
            $fsdbDumpfile("sim_handshake_HS1_WAIT3.fsdb");
        `elsif WAIT4
            $fsdbDumpfile("sim_handshake_HS1_WAIT4.fsdb");
        `elsif WAIT5
            $fsdbDumpfile("sim_handshake_HS1_WAIT5.fsdb");
        `else
            $fsdbDumpfile("sim_handshake_HS1.fsdb");
        `endif

    `elsif HS2
        `ifdef WAIT0
            $fsdbDumpfile("sim_handshake_HS2_WAIT0.fsdb");
        `elsif WAIT1
            $fsdbDumpfile("sim_handshake_HS2_WAIT1.fsdb");
        `elsif WAIT2
            $fsdbDumpfile("sim_handshake_HS2_WAIT2.fsdb");
        `elsif WAIT3
            $fsdbDumpfile("sim_handshake_HS2_WAIT3.fsdb");
        `elsif WAIT4
            $fsdbDumpfile("sim_handshake_HS2_WAIT4.fsdb");
        `elsif WAIT5
            $fsdbDumpfile("sim_handshake_HS2_WAIT5.fsdb");
        `else
            $fsdbDumpfile("sim_handshake_HS2.fsdb");
        `endif

    `elsif HS3
        `ifdef WAIT0
            $fsdbDumpfile("sim_handshake_HS3_WAIT0.fsdb");
        `elsif WAIT1
            $fsdbDumpfile("sim_handshake_HS3_WAIT1.fsdb");
        `elsif WAIT2
            $fsdbDumpfile("sim_handshake_HS3_WAIT2.fsdb");
        `elsif WAIT3
            $fsdbDumpfile("sim_handshake_HS3_WAIT3.fsdb");
        `elsif WAIT4
            $fsdbDumpfile("sim_handshake_HS3_WAIT4.fsdb");
        `elsif WAIT5
            $fsdbDumpfile("sim_handshake_HS3_WAIT5.fsdb");
        `else
            $fsdbDumpfile("sim_handshake_HS3.fsdb");
        `endif

    `else
        $display("Error: Unknown or undefined TB_HANDSHAKE_MACRO1 macro!\n");
    `endif

    $fsdbDumpvars;
end
`endif



endmodule
