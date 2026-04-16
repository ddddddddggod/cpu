module ass_i2c_slave_rx_depth_ctrl (
    input        clk,
    input        rstb,
    input  [4:0] rx_diff,
    input        rxempty,
    input  [3:0] depth_count,
    input        init_signal,
    input [4:0]  tx_diff,
    input        txfull,

    output reg   rxfifo_out,
    output reg   txfifo_out
);

//__________________RX_____________________________
assign rx_depth_hit = rx_diff >= depth_count;
// depth 
reg rx_depth_flush;
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        rx_depth_flush <= 1'b0;
    else if (rxempty)                  
        rx_depth_flush <= 1'b0;
    else if (rx_depth_hit)  
        rx_depth_flush <= 1'b1;
end

// init 
reg init_flush;
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        init_flush <= 1'b0;
    else if (rxempty)
        init_flush <= 1'b0;
    else if (init_signal)
        init_flush <= 1'b1;
end

//rxfifo_out
assign rxfifo_next = rx_depth_flush || init_flush;
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        rxfifo_out <= 1'b0;
    else
        rxfifo_out <= rxfifo_next;
end

//_________________________-tx_______________________
assign tx_depth_hit = tx_diff <= depth_count;

//tx_depth
reg tx_depth_flush;
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        tx_depth_flush <= 1'b0;
    else if (txfull)
        tx_depth_flush <= 1'b0;
    else if (tx_depth_hit)
        tx_depth_flush <= 1'b1;
end

assign txfifo_next = tx_depth_flush;
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        txfifo_out <= 1'b0;
    else
        txfifo_out <= txfifo_next;
end

endmodule