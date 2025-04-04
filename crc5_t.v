module crc5_t(
    input clk,
    input rst_n,

    // interface with `control_t`
    output tx_to_sop,
    output reg tx_to_eop,
    output tx_to_valid,
    input tx_to_ready,
    output reg [7:0] tx_to_data,

    // interface with `link_control`
    output reg tx_con_pid_en,
    output [3:0] tx_con_pid,

    // interface with link layer
    input [3:0] tx_pid,
    input [6:0] tx_addr,
    input [3:0] tx_endp,
    input tx_valid, // a start pulse
    output tx_ready // TODO: forgive me do not match waveform type `reg`: simple to guess
);

reg [3:0] pid_reg;
reg [7:0] addr_reg;
reg [3:0] endp_reg;
reg valid_reg; // keep level 1 fron SOP to EOP
reg [1:0] send_cnt; // for TOKEN, ascending

wire [10:0] d;
wire [4:0] c_out;
wire [4:0] crc_out;


/* interface with phy */
assign tx_to_sop = send_cnt == 2'b00;
assign tx_to_valid = valid_reg;

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        tx_to_eop <= 1'b0;
    else if(tx_valid) begin // -> 1/x phase
        if(tx_pid[1:0] == 2'b10) // HANDSHAKE packet, -> 1/1 phase
            tx_to_eop <= 1'b1;
        else // TOKEN packet, -> 1/3 phase
            tx_to_eop <= 1'b0;
    end else if(~tx_to_ready)
        tx_to_eop <= tx_to_eop;
    else if(send_cnt == 2'd1) // TOKEN packet, -> 3/3 phase
        tx_to_eop <= 1'b1;
    else // IDLE, TOKEN packet, -> 2/3 phase
        tx_to_eop <= 1'b0;
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        tx_to_data <= 8'h0;
    else if(tx_valid) // -> 1/x phase
        tx_to_data <= {~tx_pid, tx_pid};
    else if(~tx_to_ready)
        tx_to_data <= tx_to_data;
    else if(send_cnt == 2'd0 && pid_reg[1:0] == 2'b01) // TOKEN packet, -> 2/3 phase
        tx_to_data <= {endp_reg[0], addr_reg};
    else if(send_cnt == 2'd1) // TOKEN packet, -> 3/3 phase
        tx_to_data <= {crc_out, endp_reg[3:1]};
    else // IDLE
        tx_to_data <= {~pid_reg, pid_reg}; // TODO: guess from waveform, but why wouldn't I use reset 8'h0 value?
end

/* interface with `link_control` */
assign tx_con_pid = pid_reg;
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        tx_con_pid_en <= 1'b0;
    else if(tx_valid)
        tx_con_pid_en <= 1'b1;
    else if(~tx_to_ready)
        tx_con_pid_en <= tx_con_pid_en;
    else
        tx_con_pid_en <= 1'b0;
end


/* interface with link layer */
assign tx_ready = ~valid_reg;


/* inner signal */
// TX register
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        pid_reg <= 4'h0;
    else if(tx_valid)
        pid_reg <= tx_pid;
    else
        pid_reg <= pid_reg;
end
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        addr_reg <= 7'h0;
    else if(tx_valid)
        addr_reg <= tx_addr;
    else
        addr_reg <= addr_reg;
end
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        endp_reg <= 4'h0;
    else if(tx_valid)
        endp_reg <= tx_endp;
    else
        endp_reg <= endp_reg;
end

// state machine to counter control
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        valid_reg <= 1'b0;
    else if(tx_valid)
        valid_reg <= 1'b1;
    else if(~tx_to_ready)
        valid_reg <= valid_reg;
    // else if(pid_reg[1:0] == 2'b01 && (send_cnt == 2'd0 || send_cnt == 2'd1)) // TOKEN packet requires keep more phases
    else if(pid_reg[1:0] == 2'b01 && (~send_cnt[1])) // TOKEN packet requires keep more phases
        valid_reg <= 1'b1;
    else
        valid_reg <= 1'b0;
end

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        send_cnt <= 2'd0;
    else if(~tx_to_ready)
        send_cnt <= send_cnt;
    else if(pid_reg[1:0] == 2'b01) begin // TOKEN packet
        if(send_cnt == 2'd2)
            send_cnt <= 2'd0;
        else
            send_cnt <= send_cnt + 2'd1;
    end else
        send_cnt <= 2'd0;
end

// crc
assign d = {endp_reg, addr_reg};
assign crc_out = {c_out[0], c_out[1], c_out[2], c_out[3], c_out[4]}; // reverse bit order

crc5 crc5_tx_u0 (
    .c(5'h1f),
    .d(d),
    .c_out(c_out)
);

endmodule
