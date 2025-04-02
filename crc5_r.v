module crc5_r(
    input clk,
    input rst_n,
    input [6:0] self_addr,
    input rx_handshake_on,
    output reg crc5_err, // TODO: no useful waveform for this signal, no error case

    // interface with phy
    input rx_lp_sop,
    input rx_lp_eop,
    input rx_lp_valid,
    output rx_lp_ready,
    input [7:0] rx_lp_data,

    // interface with link layer
    output reg rx_pid_en, // at EOP, give pulse, only TOKEN, HANDSHAKE valid
    output reg [3:0] rx_pid,
    output reg [3:0] rx_endp
);

/* phy */
wire rx_sop;
wire rx_eop;
wire rx_valid;
wire rx_ready;
wire [7:0] rx_data;

assign rx_sop = rx_lp_sop;
assign rx_eop = rx_lp_eop;
assign rx_valid = rx_lp_valid;
assign rx_lp_ready = rx_ready;
assign rx_data = rx_lp_data;

assign rx_ready = 1'b1;

/* link layer: PID */
reg pid_ok; // only available at TOKEN phase: start from SOP, end in EOP
wire pid_h_l_ok; // check integrity of PID: regardless of clk, check if rx_data is PID checked correct, assume it always be PID
wire pid_is_not_data; // check type of PID: regardless of clk, TODO: check rx_data[1:0] == 2'b11 means DATA? but DATA2=4'b0111 don't invoke

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        pid_ok <= 1'b0;
    else if(rx_valid) begin
        if(~rx_handshake_on & pid_is_not_data) begin // TOKEN phase
            if(pid_h_l_ok & rx_sop)
                pid_ok <= 1'b1;
            else if(rx_eop)
                pid_ok <= 1'b0;
            else
                pid_ok <= pid_ok;
        end else
            pid_ok <= pid_ok;
    end
end

assign pid_h_l_ok = (rx_data[3:0] == ~rx_data[7:4]);
assign pid_is_not_data = (rx_data[2:0] != 3'b011);

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        rx_pid <= 4'b0;
    else if(rx_valid & rx_sop)
        rx_pid <= rx_data[3:0];
    else
        rx_pid <= rx_pid;
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        rx_pid_en <= 1'b0;
    else if(rx_pid_en)
        rx_pid_en <= 1'b0;
    else if(rx_valid & rx_eop & (pid_ok | (rx_sop & pid_h_l_ok)))
        rx_pid_en <= 1'b1;
    else
        rx_pid_en <= 1'b0;
end


/* link layer: addr */
reg addr_ok; // seems like only rely on addr_match with clk control
wire addr_match; // regardless of clk, check if rx_data == self_addr
wire crc5_right; // regardless of clk, check if rx_data[7:3] match cout
wire [10:0] d;
wire [4:0] c_out;
reg endp_bit; // TODO: set by myself, not shown in wave signal list

assign addr_match = (rx_data[6:0] == self_addr);
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        addr_ok <= 1'b0;
    else
        addr_ok <= addr_match;
end

assign d = {rx_data[2:0], endp_bit, self_addr};
assign crc5_right = (rx_data[7:3] == {cout[0], cout[1], cout[2], cout[3], cout[4]});

// I take this as pulse at EOP
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        crc5_err <= 1'b0;
    else if(crc5_err)
        crc5_err <= 1'b0;
    else if(rx_valid & rx_eop)
        crc5_err <= ~crc5_right;
    else
        crc5_err <= crc5_err;
end

crc5 crc5_u0 (
    .c(5'h1f),
    .d(d),
    .c_out(cout)
);

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        endp_bit <= 1'b0;
    else if(rx_valid & addr_match)
        endp_bit <= rx_data[7];
    else
        endp_bit <= endp_bit;
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        rx_endp <= 4'b0;
    else if(rx_valid & addr_ok & rx_eop) // TODO: I'm not sure if rx_eop is required
        rx_endp <= {rx_data[2:0], endp_bit};
    else
        rx_endp <= rx_endp;
end

endmodule
