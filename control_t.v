module control_t(
    input clk,
    input rst_n,

    // interface with `crc5_t`
    input tx_to_sop,
    input tx_to_eop,
    input tx_to_valid,
    output tx_to_ready,
    input [7:0] tx_to_data,

    // interface with link layer
    input tx_lt_sop,
    input tx_lt_eop,
    input tx_lt_valid,
    output tx_lt_ready,
    input [7:0] tx_lt_data,
    input tx_lt_cancle,

    // interface with phy
    output tx_data_on, // unsure orientation
    output tx_lp_eop_en, // unsure orientation
    output reg tx_lp_sop,
    output reg tx_lp_eop,
    output reg tx_lp_valid,
    input tx_lp_ready,
    output reg [7:0] tx_lp_data,
    output reg tx_lp_cancle
);

wire sop_buf;
wire eop_buf;
wire valid_buf;
wire ready_buf;
wire [7:0] data_buf;
wire cancle_buf;


endmodule
