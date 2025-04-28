module crc16_r( // works only DATA phase
    input clk,
    input rst_n,

    // interface with link_control module
    input rx_data_on, // enable this module,the signal which begins to transfer data to transfer layer
    output rx_sop_en, // pulse, say this is DATA SOP,it's related with rx_sop (note:not related with rx_lt_sop)
    output rx_lt_eop_en, // pulse, say this is DATA EOP,it's related with rx_lt_eop(note:not related with rx_eop)

    // interface with crc5_r module
    input rx_sop,
    input rx_eop,
    input rx_valid,
    output rx_ready,
    input [7:0] rx_data,
    
    // interface with transfer layer
    // TODO: unbale to solve valid-ready correctly
    output rx_lt_sop,
    output rx_lt_eop,
    output rx_lt_valid,
    input rx_lt_ready,
    output [7:0] rx_lt_data
);

    /* output to crc5_r module*/
    assign rx_ready = 1'b1;//although rx_ready is 1'bz in waveform, I think contest doesn't care about it ,so here I set it to 1'b1
    
    /* get signal from crc5_r module and output to transfer layer*/
    wire rx_transok;
    wire tran_buf;
    reg sop_reg;
    reg eop_reg;
    reg valid_reg;
    reg [7:0] data_reg;

    assign rx_transok = rx_valid && rx_ready;

    assign tran_buf = rx_data_on && rx_transok;

    /* interface with transfer layer: register staging */
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           sop_reg <= 1'b0; 
        end else if (tran_buf) begin
            sop_reg <= rx_sop;
        end else;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           eop_reg <= 1'b0; 
        end else if (tran_buf) begin
            eop_reg <= rx_eop;
        end else;
    end

    // have been modified
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           valid_reg <= 1'b0; 
        end else if (tran_buf) begin
            valid_reg <= rx_valid;
        end else;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
           data_reg <= 8'b00000000; 
        end else if (tran_buf) begin
            data_reg <= rx_data;
        end else;
    end

    assign rx_lt_sop = sop_reg;
    assign rx_lt_eop = eop_reg;
    assign rx_lt_valid = valid_reg;
    assign rx_lt_data = data_reg;

    /* interface with link_control module */
    assign rx_sop_en = rx_data_on && rx_transok && rx_sop; 
    assign rx_lt_eop_en = rx_data_on && rx_lt_valid && rx_lt_ready && rx_lt_eop;

    /* regardless of clk,I think this signal is not used,maybe used to UVM of syn signal */
    //wire packet_is_data;
    //assign packet_is_data = (rx_data[3:0] == 4'b0011) || (rx_data[3:0] == 4'b1011);


    /* I think this signal is not used, maybe used to UVM of syn signal */
    // always @(posedge clk, negedge rst_n) begin
    //     if (!rst_n) begin
    //         tran_en <= 1'b0;
    //     end else if (rx_data_on & rx_sop) begin
    //         tran_en <= 1'b1;
    //     end else if (rx_data_on & rx_eop) begin
    //         tran_en <= 1'b0;
    //     end else;
    // end

endmodule