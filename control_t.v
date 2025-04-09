`timescale 1ns / 1ps
module control_t(
    input clk,
    input rst_n,

    // interface with `link_control`
    input tx_data_on,
    output tx_lp_eop_en,

    // interface with `crc5_t` (TX TOKEN / HANDSHAKE)
    input tx_to_sop,
    input tx_to_eop,
    input tx_to_valid,
    output tx_to_ready,
    input [7:0] tx_to_data,

    // interface with link layer (TX DATA)
    input tx_lt_sop,
    input tx_lt_eop,
    input tx_lt_valid,
    output tx_lt_ready,
    input [7:0] tx_lt_data,
    input tx_lt_cancle, // TODO: unknown behavior: all cases are 1'b0

    // interface with phy
    output reg tx_lp_sop,
    output reg tx_lp_eop,
    output reg tx_lp_valid,
    input tx_lp_ready,
    output reg [7:0] tx_lp_data,
    output reg tx_lp_cancle // TODO: unknown behavior: all cases are 1'b0
);

wire sop_buf;
wire eop_buf;
wire valid_buf;
wire ready_buf;
wire [7:0] data_buf;
wire cancle_buf;

assign ready_buf = ~tx_lp_valid | tx_lp_ready; // tx_lp_valid ? tx_lp_ready : 1'b1;

/* interface with `crc5_t` and link layer: ready signal */
assign tx_to_ready = ~tx_data_on & ready_buf; // tx_data_on ? 1'b0 : ready_buf;
assign tx_lt_ready = tx_data_on & ready_buf; // tx_data_on ? ready_buf : 1'b0;


/* interface with link_control */
assign tx_lp_eop_en = tx_lp_valid & tx_lp_ready & tx_lp_eop; // TODO: unsure behavior for don't know meanings//1

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        tx_lp_sop <= 1'b0;
        else if(ready_buf && valid_buf)
        tx_lp_sop <= sop_buf;
        else;
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        tx_lp_eop <= 1'b0;
        else if(ready_buf && valid_buf)
        tx_lp_eop <= eop_buf;
        else;
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        tx_lp_data <= 8'h0;
        else if(ready_buf && valid_buf)
        tx_lp_data <= data_buf;
        else;
end
// TODO: unknown behavior: all cases are 1'b0
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        tx_lp_cancle <= 1'b0;
    else if(ready_buf && valid_buf)
        tx_lp_cancle <= cancle_buf;
        else;
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        tx_lp_valid <= 1'b0;
    else if(~ready_buf)
        tx_lp_valid <= tx_lp_valid;
        else;
end


/* buffer */
assign sop_buf = tx_data_on ? tx_lt_sop : tx_to_sop;
assign eop_buf = tx_data_on ? tx_lt_eop : tx_to_eop;
assign valid_buf = tx_data_on ? tx_lt_valid : tx_to_valid;
assign data_buf = tx_data_on ? tx_lt_data : tx_to_data;
assign cancle_buf = tx_data_on & tx_lt_cancle; // tx_data_on ? tx_lt_cancle : 1'b0; // TODO: unknown behavior: all cases are 1'b0


endmodule
