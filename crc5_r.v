`timescale 1ns / 1ps
module crc5_r (
    input clk,
    input rst_n,

    // interface with reg file
    input [6:0] self_addr,
    output reg crc5_err, // TODO: no useful waveform for this signal, no error case

    // interface with phy
    input rx_lp_sop,
    input rx_lp_eop,
    input rx_lp_valid,
    output rx_lp_ready,
    input [7:0] rx_lp_data,

    // interface with transfer layer
    output reg [3:0] rx_endp,

    // with link_ctrl module
    input rx_handshake_on,
    output reg [3:0] rx_pid,//also with transefer layer
    output reg rx_pid_en,//also with transefer layer

    // interface with crc16_r module
    input rx_ready,//TODO:always 1'bz according to waveform
    output [7:0] rx_data,
    output rx_sop,
    output rx_eop,
    output rx_valid
);

    /* get from phy and output to phy*/
    wire rx_lp_transok;
    assign rx_lp_transok = rx_lp_ready && rx_lp_valid;
    assign rx_lp_ready = 1'b1;

    /* link layer: addr*/
    wire addr_match; // regardless of clk, check if rx_lp_data == self_addr
    reg addr_ok;//only rely on addr_match with clk control,delay one clk

    assign addr_match = (rx_lp_data[6:0] == self_addr); 
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            addr_ok <= 1'b0;
        end else begin
            addr_ok <= addr_match;
        end
    end

    /* link layer: crc5 */ 
    wire [10:0] d;
    wire [4:0] c_out;
    reg endp_bit;//TODO: set by myself, not shown in wave signal list

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            endp_bit <= 1'b0;
        end else if (rx_lp_transok && addr_match) begin
            endp_bit <= rx_lp_data[7];
        end else;
    end

    crc5 crc5_u0 (
    .c(5'h1f),
    .d(d),
    .c_out(c_out)
    );

    assign d = {rx_lp_data[2:0], endp_bit, self_addr};
    assign crc5_right = (rx_lp_data[7:3] == {c_out[0], c_out[1], c_out[2], c_out[3], c_out[4]});

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc5_err <= 1'b0;
        end else if (rx_lp_transok && (rx_lp_eop && !rx_lp_sop) && rx_pid[1:0] == 2'b01) begin
            crc5_err <= ~crc5_right;
        end else if (crc5_err) begin
            crc5_err <= 1'b0;
        end else;
    end

    /* link layer: endp */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_endp <= 4'b0000;
        end else if (rx_lp_transok && addr_ok && rx_lp_eop) begin
            rx_endp <= {rx_lp_data[2:0], endp_bit};
        end else;
    end

    /* link layer: PID */
    wire pid_h_l_ok; // check integrity of PID: regardless of clk, check if rx_lp_data is PID checked correct
    wire pid_is_not_data; // check type of PID: regardless of clk, check if rx_lp_data[3:0] == 0011 or rx_lp_data[3:0] == 1011;(0011 represent DATA0, 1011 represent DATA1)
    wire pid_ok_en; //the signal to pull up pid_ok
    reg pid_ok; // only available at TOKEN phase: start from SOP, end in EOP
    wire rx_pid_en_token; // the signal to pull up rx_pid_en
    wire rx_pid_en_handshake; // the signal to pull up rx_pid_en

    assign pid_h_l_ok = (rx_lp_data[3:0] == ~rx_lp_data[7:4]);
    assign pid_is_not_data = (rx_lp_data[3:0] != 4'b0011) && (rx_lp_data[3:0] != 4'b1011);
    assign pid_ok_en = pid_h_l_ok && rx_lp_sop && rx_lp_transok && pid_is_not_data && ~rx_handshake_on;
    assign rx_pid_en_token = rx_lp_transok && rx_lp_eop && addr_ok && crc5_right && pid_ok;
    assign rx_pid_en_handshake = rx_lp_transok && rx_lp_eop && pid_h_l_ok && rx_handshake_on;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           pid_ok <= 1'b0; 
        end else if (pid_ok_en) begin
            pid_ok <= 1'b1;
        end else if (rx_lp_eop && rx_lp_transok) begin
            pid_ok <= 1'b0;
        end else;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_pid <= 4'b0000;
        end else if (rx_lp_transok && rx_lp_sop) begin
            rx_pid <= rx_lp_data[3:0];
        end else;
    end

    /* rx_pid_en decides when rx_pid、rx_endp is valid

    rx_pid_en only pull up in token and handshake phase:
        1.token phase: must satisfy addr_ok, crc5_right, pid_ok(rx_lp_transok && rx_lp_eop)
        2.handshake phase: must satisfy rx_handshake_on, pid_h_l_ok(rx_lp_transok && rx_lp_eop)

    for data phase, rx_pid_en is 0;
    for addr dosen't match, rx_pid_en is 0;
    for crc5 error, rx_pid_en is 0;

    */

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_pid_en <= 1'b0;
        end else if ((rx_pid_en_token || rx_pid_en_handshake) && rx_ready) begin
            rx_pid_en <= 1'b1;
        end else begin
            rx_pid_en <= 1'b0;
        end
    end

    /* output to crc16_r module */
    assign rx_sop = rx_lp_sop;
    assign rx_eop = rx_lp_eop;
    assign rx_valid = rx_lp_valid;
    assign rx_data = rx_lp_data;

endmodule
