`timescale 1ns / 1ps
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

    // interface with transfer layer
    input [3:0] tx_pid,
    input [6:0] tx_addr,
    input [3:0] tx_endp,
    input tx_valid, // a start pulse
    output reg tx_ready 
);

/* interface with control_t module */
wire tx_transok;
wire tx_to_transok;
reg [1:0] send_cnt; 
reg valid_reg; // keep level 1 fron SOP to EOP
reg [3:0] pid_reg;
reg [7:0] addr_reg;
reg [3:0] endp_reg;

assign tx_transok = tx_valid && tx_ready; 
assign tx_to_transok = tx_to_valid && tx_to_ready; 

assign tx_to_sop = (send_cnt == 2'b00);
assign tx_to_valid = valid_reg;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        tx_to_eop <= 1'b0;
    end else if (tx_transok && (tx_pid[1:0] == 2'b10)) begin
        tx_to_eop <= 1'b1;
    end else if (tx_to_transok && (send_cnt == 2'b01)) begin
        tx_to_eop <= 1'b1;
    end else if (tx_to_transok && (send_cnt == 2'b10)) begin
        tx_to_eop <= 1'b0;
    end else;
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        tx_to_data <= 8'b11110000;
    end else if (tx_transok) begin
        tx_to_data <= {~tx_pid, tx_pid};
    end else if(tx_to_transok) begin 
        if (send_cnt == 2'b00) begin
            tx_to_data <= {endp_reg[0], addr_reg};
        end else if (send_cnt == 2'b01) begin
            tx_to_data <= {crc_out, endp_reg[3:1]};
        end else if (send_cnt == 2'b10) begin
            tx_to_data <= {~tx_pid, tx_pid};
        end else;
    end else; 
end

/* interface with `link_control` */
assign tx_con_pid = pid_reg;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        tx_con_pid_en <= 1'b0;
    end else if(tx_transok) begin
        tx_con_pid_en <= 1'b1;
    end else if(tx_to_transok) begin
        tx_con_pid_en <=1'b0;
    end else;
end


/* interface with transfer layer */
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        tx_ready <= 1'b1;
    end else if (tx_valid) begin
        tx_ready <= 1'b0;
    end else if (tx_to_transok) begin
        if (pid_reg[1:0] == 2'b10) begin // HANDSHAKE packet
            tx_ready <= 1'b1;
        end else if ((pid_reg[1:0] == 2'b01) && (send_cnt == 2'b10)) begin // TOKEN packet
            tx_ready <= 1'b1;
        end else;
    end else;
end

/* inner signal */
// TX register
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        pid_reg <= 4'b0000;
    end else if (tx_transok) begin
        pid_reg <= tx_pid;
    end else;
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        addr_reg <= 7'b0000000;
    end else if (tx_transok) begin
        addr_reg <= tx_addr;
    end else;
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        endp_reg <= 4'b0000;
    end else if (tx_transok) begin
        endp_reg <= tx_endp;
    end else;
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        valid_reg <= 1'b0;
    end else if (tx_transok) begin
        valid_reg <= 1'b1;
    end else if (tx_to_transok) begin
        if (pid_reg[1:0] == 2'b10) begin // HANDSHAKE packet
            valid_reg <= 1'b0;
        end else if ((pid_reg[1:0] == 2'b01) && (send_cnt == 2'b10)) begin // TOKEN packet
            valid_reg <= 1'b0;
        end else;
    end else;
end

/* send_cnt only add when transmit token packet */

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        send_cnt <= 2'b00;
    end else if (tx_to_transok) begin
        if (pid_reg[1:0] == 2'b10) begin //HANDSHAKE packet
            send_cnt <= 2'b00; 
        end else if (pid_reg[1:0] == 2'b01) begin // TOKEN packet
            if (send_cnt == 2'b10) begin
                send_cnt <= 2'b00;
            end else begin
                send_cnt <= send_cnt + 1'b1;
            end
        end else;
    end else;
end

// crc
wire [10:0] d;
wire [4:0] c_out;//the output of crc5 module
wire [4:0] crc_out;// flip c_out

assign d = {endp_reg, addr_reg};
assign crc_out = {c_out[0], c_out[1], c_out[2], c_out[3], c_out[4]}; // reverse bit order

crc5 crc5_tx_u0 (
    .c(5'h1f),
    .d(d),
    .c_out(c_out)
);

endmodule