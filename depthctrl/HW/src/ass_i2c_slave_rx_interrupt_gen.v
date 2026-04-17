`timescale 1ns / 1ps

module ass_i2c_slave_rx_interrupt_gen(
	input clk,
	input rstb,
	input request_req,
	input read_req_req,
	input init_req,
	input rdy_req,
    input rxre,
    input tx_valid,
    input init_clr,
    input request_clr,
    input rdy_clr,
    input [2:0] intr_mask,
    input rxfifo_out,


	output request_ack,
	output read_req_ack,
	output init_ack,
	output rdy_ack,
	output interrupt,
    output reg init_irq,
    output reg request_irq,
    output reg rdy_irq,
    output init_signal
);

ass_i2c_slave_rx_interrupt_cdc u_intr_cdc(
    .clk            (clk),
    .rstb           (rstb),
    .init_req       (init_req),
    .request_req    (request_req),
    .rdy_req        (rdy_req),
    .read_req_req   (read_req_req),

    .init_ack       (init_ack),
    .init_signal    (init_signal),
    .request_ack   (request_ack),
    .request_signal (request_signal),
    .rdy_ack        (rdy_ack),
    .rdy_signal     (rdy_signal),
    .read_req_ack   (read_req_ack)
);

//_______________interrupt______________________
//init
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        init_irq <= 1'b0;
    end else if (init_clr) begin
        init_irq <= 1'b0;
    end else if (init_signal) begin
        init_irq <= 1'b1;
    end
end

//request (tx write)
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        request_irq <= 1'b0;
    end else if (request_clr) begin
        request_irq <= 1'b0;
    end else if (request_signal) begin
        request_irq <= 1'b1;
    end
end

//rdy (rx read)
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rdy_irq <= 1'b0;
    end else if (rdy_clr) begin  
        rdy_irq <= 1'b0;
    end else if (rxfifo_out) begin //rdy_signal
        rdy_irq <= 1'b1;
    end
end

//_____________________Output logic_________________________________
assign interrupt = (init_irq & ~intr_mask[0]) | (rdy_irq & ~intr_mask[1]) | (request_irq & ~intr_mask[2]);

endmodule
