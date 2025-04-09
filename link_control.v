`timescale 1ns / 1ps
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
    input tx_con_pid_en, // pulse at start, combine with `tx_lp_eop_en` show finish
    input [3:0] tx_con_pid,
    // from `control_t`
    input tx_lp_eop_en, // pulse at finish

    // enable
    output reg rx_data_on,      // to `crc16_r`
    output reg rx_handshake_on, // to `crc5_r`
    output tx_data_on,      // to `control_t`. TODO: I change reg to wire type.

    // Register
    input ms, // 1 = master, 0 = slave
    input [15:0] time_threshold, // set overtime value
    input [5:0] delay_threshole, // set delay value, TODO: should be `delay_threshold` rather than `delay_threshole`?
    output reg time_out, // overtime flag, TODO: unknown behavior, for all cases is 1'b0
    output d_oe // direction (data_outputEnable): 0 = RX, 1 = TX. TODO: I change reg to wire type.
);

// ms
// hs = handshake
// wt = write token (OUT)
// rt = read token (IN)
// wr = write ready
wire ms_receive_hs; // pulse at finish of receive HANDSHAKE ACK
wire slave_receive_rt; // pulse at finish of receive TOKEN IN
wire slave_receive_wt; // pulse at finish of receive TOKEN OUT
reg slave_has_received_rt; // high at TX DATA, for TOKEN IN
wire master_send_rt; // pulse at start of send TOKEN IN
wire master_send_wt; // pulse at start of send TOKEN OUT
reg master_finish_sending_rt; // high at interval between send TOKEN OUT and RX DATA
reg [1:0] master_finish_sending_wr; // count at TOKEN OUT (1): ready, TX DATA start (2): process, TX DATA finish (0): finish

// time and delay
reg [15:0] timer;
reg delay_on;
reg [5:0] delay_cnt;
wire delay_done;

// direction
reg master_d_oe;
reg slave_d_oe;

// others
reg rx_sop_en_regd;


/* enable */
assign tx_data_on = slave_has_received_rt || (master_finish_sending_wr == 2'd2);
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        rx_handshake_on <= 1'b0;
    else if(tx_lp_eop_en && tx_data_on) // slave / master: finish send DATA0
        rx_handshake_on <= 1'b1;
    else if(ms_receive_hs)
        rx_handshake_on <= 1'b0;
    else;
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        rx_data_on <= 1'b0;
    else if(slave_receive_wt | master_send_rt) // slave: finish receive TOKEN (OUT) | master: finish send TOKEN (IN)
        rx_data_on <= 1'b1;
    else if(rx_lt_eop_en)
        rx_data_on <= 1'b0;
    else;
end




/* Register */
assign d_oe = ms ? master_d_oe : slave_d_oe;
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        time_out <= 1'b0;
    else if(timer == time_threshold)
        time_out <= 1'b1;
    else
        time_out <= time_out;       
end


/* ms */
assign ms_receive_hs = (rx_pid == 4'b0010) && rx_pid_en; //assign ms_receive_hs = (rx_pid[1:0] == 2'b10) && rx_pid_en; 

// slave
assign slave_receive_wt = ~ms && (rx_pid == 4'b0001) && rx_pid_en; // valid at slave TOKEN (OUT)
assign slave_receive_rt = ~ms && (rx_pid == 4'b1001) && rx_pid_en; // valid at slave TOKEN (IN)

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        slave_has_received_rt <= 1'b0;
    else if(slave_receive_rt)       
            slave_has_received_rt <= 1'b1;
    else if(tx_lp_eop_en) // TX finished
            slave_has_received_rt <= 1'b0;
    else;
end

// master
assign master_send_wt = ms && (tx_con_pid == 4'b0001) && tx_con_pid_en; // valid at master TOKEN (OUT)
assign master_send_rt = ms && (tx_con_pid == 4'b1001) && tx_con_pid_en; // valid at master TOKEN (IN)
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        master_finish_sending_wr <= 2'd0;
    else if(master_send_wt)
            master_finish_sending_wr <= 2'd1; // ready TX data
    else if(master_finish_sending_wr == 2'd1 && tx_lp_eop_en)
            master_finish_sending_wr <= 2'd2; // processing TX data
    else if(master_finish_sending_wr == 2'd2 && tx_lp_eop_en)
            master_finish_sending_wr <= 2'd0; // finish TX data
    else;   
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        master_finish_sending_rt <= 1'b0;
    else if (master_send_rt) 
            master_finish_sending_rt <= 1'b1;
    else if(tx_lp_eop_en) // TX finished
            master_finish_sending_rt <= 1'b0;
    else;

end


/* time */
// delay
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        delay_on <= 1'b0;
    else if(ms) 
        if(tx_lp_eop_en && (~ms || master_finish_sending_rt || master_finish_sending_wr == 2'd2))
        // master: finish send TOKEN (IN) -> receive DATA0 | finish send DATA0 -> receive HANDSHAKE (ACK)
        // slave: finish send DATA0 -> receive HANDSHAKE (ACK) | finish send HANDSHAKE (ACK)
            delay_on <= 1'b1;
        else if(delay_done)
            delay_on <= 1'b0;
        else;
end

assign delay_done = delay_cnt == delay_threshole;

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        delay_cnt <= 6'd0;
    else if(delay_on) begin
        if(delay_cnt == delay_threshole)
            delay_cnt <= 6'd0;
        else
            delay_cnt <= delay_cnt + 6'd1;
    end else
        delay_cnt <= 6'd0;
end

// timer
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        timer <= 16'd0;
    else if (rx_pid_en | rx_sop_en) // finish counting: receive HANDSHAKE (ACK) | receive DATA0
        timer <= 16'd0;
    else if(rx_handshake_on | rx_data_on) // start counting: wait receiving HANDSHAKE (ACK) | wait receiving DATA0
        timer <= timer + 16'd1; // assume `time_out` can handle this, so `timer` do not need to stay at time_threshold
    else
        timer <= 16'd0; // TODO: is it better stay? `timer <= timer`
end


/* direction */
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        slave_d_oe <= 1'b0;
    else if(slave_receive_rt | rx_lt_eop_en) // slave: finish receive TOKEN (IN) -> start send DATA0 | finish receive DATA0 -> start send HANDSHAKE (ACK)
        slave_d_oe <= 1'b1;
    else if(delay_done)
        slave_d_oe <= 1'b0;
    else;    
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        master_d_oe <= 1'b1; // caution! default master is sending.
    else if(ms_receive_hs | rx_lt_eop_en) // master: finish send DATA0 -> start receive HANDSHAKE (ACK) | finish send TOKEN (IN) -> start receive DATA0
            master_d_oe <= 1'b1;
    else if(delay_done)
        master_d_oe <= 1'b0;
    else;
end


/* others */
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        rx_sop_en_regd <= 1'b0;
    else if(rx_sop_en)
        rx_sop_en_regd <= 1'b1;
    else if(rx_lt_eop_en)
        rx_sop_en_regd <= 1'b0;
    else;
end

endmodule
