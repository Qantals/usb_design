`timescale 1ns / 1ps
module link_control(
    input clk,
    input rst_n,

    /* control */
    // from `crc5_r`
    input rx_pid_en, // pulse at finish
    input [3:0] rx_pid,
    input crc5_err,
    // from `crc16_r`
    input rx_sop_en, // pulse at start.rx_sop_en presents that begin to receive DATA packet.
    input rx_lt_eop_en, // pulse at finish
    // from `crc5_t`
    input tx_con_pid_en, // pulse at start, combine with `tx_lp_eop_en` show finish
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
    output d_oe //data_outputEnable
);

// hs = handshake
// wt = write token (OUT)
// rt = read token (IN)
// wr = write ready

wire master_send_rt; // pulse at start of send TOKEN IN
wire master_send_wt; // pulse at start of send TOKEN OUT
wire slave_receive_rt; // pulse at finish of receive TOKEN IN
wire slave_receive_wt; // pulse at finish of receive TOKEN OUT
wire ms_receive_hs; // pulse at finish of receive HANDSHAKE ACK
reg slave_has_received_rt; // high at TX DATA,for TOKEN IN
// master_finish_sending_wr is used to decide the state of master(send OUT token): level 1 = send TOKEN OUT, level 2 = send DATA, level 0 = no send
reg [1:0] master_finish_sending_wr;
// master_finish_sending_rt is used to decide the state of master(send IN token): level 1 = send TOKEN IN
reg master_finish_sending_rt;
reg [5:0] delay_cnt;
wire delay_done;
reg delay_on;
reg master_d_oe;
reg slave_d_oe;
reg [15:0] timer;
reg rx_sop_en_regd; // register flopping for delay control

/* Determine which packet is currently being received*/
assign master_send_rt = ms && (tx_con_pid == 4'b1001) && tx_con_pid_en;
assign master_send_wt = ms && (tx_con_pid == 4'b0001) && tx_con_pid_en;
assign slave_receive_rt = !ms && (rx_pid == 4'b1001) && rx_pid_en && (~crc5_err); // crc5_err is used to filter the error packet
assign slave_receive_wt = !ms && (rx_pid == 4'b0001) && rx_pid_en && (~crc5_err);
assign ms_receive_hs = (rx_pid == 4'b0010) && rx_pid_en;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        slave_has_received_rt <= 1'b0;
    end else if (slave_receive_rt) begin
        slave_has_received_rt <= 1'b1;
    end else if (tx_lp_eop_en) begin
        slave_has_received_rt <= 1'b0;
    end else;
end



/* the enable signal which control to send packet or receive packet*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        master_finish_sending_wr <= 2'd0;
    end else if (master_send_wt) begin
        master_finish_sending_wr <= 2'd1; 
    end else if (tx_lp_eop_en && master_finish_sending_wr == 2'd1) begin
        master_finish_sending_wr <= 2'd2; 
    end else if (tx_lp_eop_en && master_finish_sending_wr == 2'd2) begin
        master_finish_sending_wr <= 2'd0;
    end else;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_on <= 1'b0;
    end else if (slave_receive_wt || master_send_rt) begin //as a host, read operations will receive data; as a slave, write operations will receive data.
        rx_data_on <= 1'b1;
    end else if (rx_lt_eop_en) begin
        rx_data_on <= 1'b0;
    end else;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_handshake_on <= 1'b0;
    end else if (tx_lp_eop_en && (slave_has_received_rt || master_finish_sending_wr == 2'd2)) begin // pulse && (level || level) signal = pulse signal
        rx_handshake_on <= 1'b1;
    end else if (ms_receive_hs) begin
        rx_handshake_on <= 1'b0;
    end else;
end

// tx_data_on only uses in sending DATA packet
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_data_on <= 1'b0;
    end else if (slave_receive_rt || (tx_lp_eop_en && (master_finish_sending_wr == 2'd1))) begin // pulse || (pulse && level) signal = pulse signal
        tx_data_on <= 1'b1;
    end else if (tx_lp_eop_en) begin
        tx_data_on <= 1'b0;
    end else;
end

/* the signals which are related with delay */
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        master_finish_sending_rt <= 1'b0;
    end else if (master_send_rt) begin
        master_finish_sending_rt <= 1'b1; 
    end else if (tx_lp_eop_en) begin
        master_finish_sending_rt <= 1'b0; 
    end else;
end

/* delay_cnt*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        delay_cnt <= 6'd0;
    end else if (delay_on) begin
        if (delay_done) begin
            delay_cnt <= 6'd0;
        end else begin
            delay_cnt <= delay_cnt + 6'd1;
        end
    end else begin
        delay_cnt <= 6'd0;
    end
end

/* delay_done */
assign delay_done = (delay_cnt == delay_threshole);

/* delay_on:
    if slave: 
    delay_on pull up in the situation of (DATA packet is sent,ready to receive handshake)
    or in the situation of (HANDSHAKE packet is sent)

    if master: delay_on pull up in the situation of (DATA packet is sent,ready to receive handshake)
    or in the situation of (READ packet is sent)

    no matter if master or slave ,delay_on pull down in delay_done
*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        delay_on <= 1'b0;
    end else if (ms) begin
        if (tx_lp_eop_en && (master_finish_sending_rt || (master_finish_sending_wr == 2'd2))) begin // pulse && (level || level) signal = pulse signal
            delay_on <= 1'b1;
        end else if (delay_done) begin
            delay_on <= 1'b0;
        end else;
    end else begin
        if (tx_lp_eop_en) begin
            delay_on <= 1'b1;
        end else if (delay_done) begin
            delay_on <= 1'b0;
        end else;
    end 
end

/* output: d_oe */
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        master_d_oe <= 1'b1;
    end else if (delay_done) begin
        master_d_oe <= 1'b0;
    end else if (ms_receive_hs || (rx_lt_eop_en && ms)) begin
        master_d_oe <= 1'b1;
    end else;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        slave_d_oe <= 1'b0;
    end else if (delay_done) begin
        slave_d_oe <= 1'b0;
    end else if (slave_receive_rt || rx_lt_eop_en && (!ms)) begin
        slave_d_oe <= 1'b1;
    end else;
end

assign d_oe = ms ? master_d_oe : slave_d_oe;

/* Timeout detection*/
/* 
    if slave:
    1、timer count in the situation of (ready to receive HANDSHAKE packet),this is IN token
    or in the situation of (ready to receive DATA packet),this is OUT token

    2、timer become 0 in the situation of (ms_receive_hs)
    or in the situation of (begin to recieve DATA packet,namely rx_sop_en == 1'b1)

    if master:
    1、timer count in the situation of (ready to receive HANDSHAKE packet),this is OUT token
    or in the situation of (ready to receive DATA packet),this is IN token

    2、timer become 0 in the situation of (ms_receive_hs)
    or in the situation of (begin to recieve DATA packet,namely rx_sop_en == 1'b1)
*/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        timer <= 16'd0;
    end else if (ms_receive_hs || rx_sop_en_regd || rx_sop_en) begin // clear first: use level signal to clear (you can see `ms_receive_hs` as special level signal, any it is right)
        timer <= 16'd0;
    end else if (rx_handshake_on || rx_data_on) begin // count then: use level signal to count
        timer <= timer + 16'd1;
    end else;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        time_out <= 1'b0;
    end else if (time_out) begin
        time_out <= 1'b0;
    end else if (timer == time_threshold) begin
        time_out <= 1'b1;
    end else;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_sop_en_regd <= 1'b0;
    end else if (rx_sop_en) begin
        rx_sop_en_regd <= 1'b1;
    end else if (rx_lt_eop_en) begin
        rx_sop_en_regd <= 1'b0;
    end else;
end

endmodule