module link_control(
    input clk,
    input rst_n,

    /* control */
    // from `crc5_r`
    input rx_pid_en, // pulse at finish
    input [3:0] rx_pid,
    // from `crc16_r`
    input rx_sop_en, // pulse at start. TODO: should be `rx_lt_sop_en` rather than `rx_sop_en`?
    input rx_lt_eop_en, // pulse at finish
    // from `crc5_t`
    input tx_con_pid_en, // pulse at finish
    input [3:0] tx_con_pid,
    // from `control_t`
    input tx_lp_eop_en, // pulse at finish

    // enable
    output reg rx_data_on,      // to `crc16_r`
    output reg rx_handshake_on, // to `crc5_r`
    output reg tx_data_on,      // to `control_t`

    // Register
    input ms, // 1 = master, 0 = slave
    input [15:0] time_threshold, // set overtime value
    input [5:0] delay_threshole, // set delay value, TODO: should be `delay_threshold` rather than `delay_threshole`?
    output reg time_out, // overtime flag, TODO: unknown behavior, for all cases is 1'b0
    output reg d_oe // direction: 0 = RX, 1 = TX
);

wire slave_receive_wt;
wire slave_receive_rt;
wire ms_receive_hs;
wire master_send_rt;
wire master_send_wt;
reg slave_has_received_rt;
reg [1:0] master_finish_sending_wr;
reg master_finish_sending_rt;
reg [15:0] timer;
reg delay_on;
reg [5:0] delay_cnt;
wire delay_done;
reg rx_sop_en_regd;
reg master_d_oe;
reg slave_d_oe;

endmodule
