`timescale 1ns / 1ps
module usb_link(
    input clk,
    input rst_n,

    // Register
    // `crc5_r`
    input [6:0] self_addr,
    output crc5_err,
    // `crc16_r`
    output crc16_err,
    // `link_control`
    input ms,
    input [15:0] time_threshold,
    input [5:0] delay_threshole,
    output time_out,
    output d_oe,


    // interface with phy
    // `crc5_r` and share `crc16_r` with different signal without `lp`
    input rx_lp_sop,
    input rx_lp_eop,
    input rx_lp_valid,
    output rx_lp_ready,
    input [7:0] rx_lp_data,
    // `control_t`
    output tx_lp_sop,
    output tx_lp_eop,
    output tx_lp_valid,
    input tx_lp_ready,
    output [7:0] tx_lp_data,
    output tx_lp_cancle,


    // interface with link layer
    output rx_pid_en,       // reused by `crc5_t` and `link_control`
    output [3:0] rx_pid,    // reused by `crc5_t` and `link_control`
    // `crc5_r`
    output [3:0] rx_endp,
    // `crc16_r`
    output rx_lt_sop,
    output rx_lt_eop,
    output rx_lt_valid,
    input rx_lt_ready,
    output [7:0] rx_lt_data,
    // `crc5_t`
    input [3:0] tx_pid,
    input [6:0] tx_addr,
    input [3:0] tx_endp,
    input tx_valid,
    output tx_ready,
    // `control_t`
    input tx_lt_sop,
    input tx_lt_eop,
    input tx_lt_valid,
    output tx_lt_ready,
    input [7:0] tx_lt_data,
    input tx_lt_cancle
);

wire rx_handshake_on;
// crc16_r to phy, shared with `crc5_r` with `lp` in variable name
wire rx_sop;
wire rx_eop;
wire rx_valid;
wire rx_ready; // ready from `crc16_r` is useless
wire [7:0] rx_data;

wire rx_data_on;
wire rx_sop_en;
wire rx_lt_eop_en;
wire tx_to_sop;
wire tx_to_eop;
wire tx_to_valid;
wire tx_to_ready;
wire [7:0] tx_to_data;
wire tx_con_pid_en;
wire [3:0] tx_con_pid;
wire tx_data_on;
wire tx_lp_eop_en;


/* assign `crc16_r` to phy port 
assign rx_sop = rx_lt_sop;
assign rx_eop = rx_lt_eop;
assign rx_valid = rx_lt_valid;
assign rx_data = rx_lt_data;*/


/* instantiation */
crc5_r crc5_ru_u0(
    .clk             ( clk             ), // input
    .rst_n           ( rst_n           ), // input

    // Register
    .self_addr       ( self_addr       ), // input [6:0]
    .crc5_err        ( crc5_err        ), // output

    // interface with `link_control`
    .rx_handshake_on ( rx_handshake_on ), // input
    .rx_pid_en       ( rx_pid_en       ), // output         reused by link layer
    .rx_pid          ( rx_pid          ), // output [3:0]   reused by link layer

    // interface with phy
    .rx_lp_sop       ( rx_lp_sop       ), // input
    .rx_lp_eop       ( rx_lp_eop       ), // input
    .rx_lp_valid     ( rx_lp_valid     ), // input
    .rx_lp_ready     ( rx_lp_ready     ), // output
    .rx_lp_data      ( rx_lp_data      ), // input [7:0]

    // interface with link layer
    .rx_endp         ( rx_endp         ), // output [3:0]

    // interface with crc16_r module
    .rx_sop          (rx_sop),//output
    .rx_eop          (rx_eop),//output
    .rx_valid        (rx_valid),//output
    .rx_ready        (rx_ready),//input,always 1'bz according to waveform
    .rx_data         (rx_data)//output [7:0]
);


crc16_r crc16_ru_u0(
    .clk          ( clk          ), // input
    .rst_n        ( rst_n        ), // input

    // interface with `link_control`
    .rx_data_on   ( rx_data_on   ), // input
    .rx_sop_en    ( rx_sop_en    ), // output
    .rx_lt_eop_en ( rx_lt_eop_en ), // output

    // interface with crc5_r, but shared with `crc5_r` with `lp` in variable name
    .rx_sop       ( rx_sop       ), // input
    .rx_eop       ( rx_eop       ), // input
    .rx_valid     ( rx_valid     ), // input
    .rx_ready     ( rx_ready     ), // output
    .rx_data      ( rx_data      ), // input [7:0]

    // interface with link layer
    .rx_lt_sop    ( rx_lt_sop    ), // output
    .rx_lt_eop    ( rx_lt_eop    ), // output
    .rx_lt_valid  ( rx_lt_valid  ), // output
    .rx_lt_ready  ( rx_lt_ready  ), // input
    .rx_lt_data   ( rx_lt_data   ), // output [7:0]
    .crc16_err    ( crc16_err    ) // output
);



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

link_control link_control_u0(
    .clk             ( clk             ), // input
    .rst_n           ( rst_n           ), // input

    // control
    .rx_pid_en       ( rx_pid_en       ), // input          `crc5_r` reused by link layer
    .rx_pid          ( rx_pid          ), // input [3:0]    `crc5_r` reused by link layer
    .crc5_err        ( crc5_err        ), // input          `crc5_r` reused by link layer

    .rx_sop_en       ( rx_sop_en       ), // input          `crc16_r`
    .rx_lt_eop_en    ( rx_lt_eop_en    ), // input          `crc16_r`

    .tx_con_pid_en   ( tx_con_pid_en   ), // input          `crc5_t`
    .tx_con_pid      ( tx_con_pid      ), // input [3:0]    `crc5_t`

    .tx_lp_eop_en    ( tx_lp_eop_en    ), // input          `control_t`

    // enable
    .rx_data_on      ( rx_data_on      ), // output, `crc16_r`
    .rx_handshake_on ( rx_handshake_on ), // output, `crc5_r`
    .tx_data_on      ( tx_data_on      ), // output, `control_t`

    // Register
    .ms              ( ms              ), // input
    .time_threshold  ( time_threshold  ), // input [15:0]
    .delay_threshole ( delay_threshole ), // input [5:0]
    .time_out        ( time_out        ), // output
    .d_oe            ( d_oe            ) // output
);


endmodule
