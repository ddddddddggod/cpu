module ass_i2c_slave_rx_interrupt_cdc (
	input 		clk,
	input 		rstb,
	input 		init_req,
	input 		request_req,
	input 		rdy_req,
	input 		read_req_req,

	output 		init_ack,
	output 		init_signal,
	output 		request_ack,
	output 		request_signal,
	output 		rdy_ack,
	output 		rdy_signal,
	output 		read_req_ack

);

//_________________CDC ACK_____________
reg [1:0] init_req_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        init_req_r <= 2'b00;
    end else begin
        init_req_r <= {init_req_r[0], init_req};
    end
end
assign init_ack = init_req_r[1];
assign init_signal = init_req_r[0] & ~init_req_r[1]; //edge detect

reg [1:0] request_req_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        request_req_r <= 2'b00;
    end else begin
        request_req_r <= {request_req_r[0], request_req};
    end
end
assign request_ack = request_req_r[1];
assign request_signal = request_req_r[0] & ~request_req_r[1]; //edge detect


reg [1:0] rdy_req_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rdy_req_r <= 2'b00;
    end else begin
        rdy_req_r <= {rdy_req_r[0], rdy_req};
    end
end
assign rdy_ack = rdy_req_r[1];
assign rdy_signal = rdy_req_r[0] & ~rdy_req_r[1]; //edge detect


//-----------txfifo clr------------
reg [1:0] read_req_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        read_req_r <= 2'b00;
    end else begin
        read_req_r <= {read_req_r[0], read_req_req};
    end
end
assign read_req_ack = read_req_r[1];

endmodule