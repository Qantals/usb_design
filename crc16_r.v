module crc16_r( // works only DATA phase
    input clk,
    input rst_n,

    // interface with `link_control`
    // TODO: may have naming error, should be `rx_lt_sop_en` rather than `rx_sop_en`?
    input rx_data_on, // enable this module
    output rx_sop_en, // pulse, say this is DATA SOP
    output rx_lt_eop_en, // pulse, say this is DATA EOP

    // interface with phy, but shared with `crc5_r` with `lp` in variable name
    input rx_sop,
    input rx_eop,
    input rx_valid,
    output rx_ready,
    input [7:0] rx_data,
    
    // interface with link layer
    // TODO: unbale to solve valid-ready correctly
    output rx_lt_sop,
    output rx_lt_eop,
    output rx_lt_valid,
    input rx_lt_ready,
    output [7:0] rx_lt_data
);

assign rx_ready = 1'bz;

// interface with link layer: register staging
reg sop_reg;
reg eop_reg;
reg valid_reg;
reg [7:0] data_reg;

assign rx_lt_sop = sop_reg;
assign rx_lt_eop = eop_reg;
assign rx_lt_valid = valid_reg;
assign rx_lt_data = data_reg;

always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        sop_reg <= 1'b0;
    else if(rx_data_on) begin
        if(~sop_reg)
            sop_reg <= rx_sop;
        else if(rx_lt_ready)
            sop_reg <= rx_sop;
        else
            sop_reg <= sop_reg;
    end else
        sop_reg <= sop_reg;
end
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        eop_reg <= 1'b0;
    else if(rx_data_on) begin
        if(~eop_reg)
            eop_reg <= rx_eop;
        else if(rx_lt_ready)
            eop_reg <= rx_eop;
        else
            eop_reg <= eop_reg;
    end else
        eop_reg <= eop_reg;
end
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        valid_reg <= 1'b0;
    else if(rx_data_on) begin
        if(~valid_reg)
            valid_reg <= tran_buf;
        else if(rx_lt_ready)
            valid_reg <= tran_buf;
        else
            valid_reg <= valid_reg;
    end else
        valid_reg <= valid_reg;
end
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        data_reg <= 8'h0;
    else if(rx_data_on) begin
        if(tran_buf)
            data_reg <= rx_data;
        else if(rx_lt_ready)
            data_reg <= rx_data;
        else
            data_reg <= data_reg;
    end else
        data_reg <= data_reg;
end

/* interface with `link_control` */
assign rx_sop_en = rx_data_on & rx_sop & ~rx_lt_sop;
assign rx_lt_eop_en = rx_data_on & rx_eop & rx_lt_eop; // TODO: Is this strange?

/* data, inner signal. TODO: do not know case of ready==0 */
wire packet_is_data;
reg tran_en;
wire tran_buf;

assign packet_is_data = rx_data_on && rx_sop && (rx_data[1:0] == 2'b11); // is this signal useless? 

// TODO: I guess enable signal like this, but not sure.
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
        tran_en <= 1'b0;
    else if(rx_data_on & rx_sop)
        tran_en <= 1'b1;
    else if(rx_data_on & rx_eop)
        tran_en <= 1'b0;
    else
        tran_en <= tran_en;
end

// regardless of clk, process signal rx_valid
assign tran_buf = rx_data_on & rx_valid & ~rx_lt_eop; // TODO: why there is rx_eop?

endmodule
