module ass_i2c_slave_rx_ctrl_cdc (
    input           clk,     
    input           rstb,     
    input           init_ack, 
    input           request_ack,
    input           rdy_ack,   
    input           read_req_ack,  
    input           init,      
    input           request,   
    input           rdy,       
    input           read_req,  

    output          init_req,
    output          request_req,
    output          rdy_req,
    output          read_req_req,
    output          txfifo_clr
    );

//--------CDC ack--------------------
reg [1:0] init_ack_o;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        init_ack_o <= 2'b00;
    end else begin
        init_ack_o <= {init_ack_o[0],init_ack};
    end
end
assign init_ack_r = init_ack_o[1];


reg [1:0] request_ack_o;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        request_ack_o <= 2'b00;
    end else begin
        request_ack_o <= {request_ack_o[0], request_ack};
    end
end
assign request_ack_r = request_ack_o[1];


reg [1:0] rdy_ack_o;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rdy_ack_o <= 2'b00;
    end else begin
        rdy_ack_o <= {rdy_ack_o[0], rdy_ack};
    end
end
assign rdy_ack_r = rdy_ack_o[1];


//--------CDC request---------------------
reg init_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        init_r <= 1'b0;
    end else if (init_ack_r) begin
        init_r <= 1'b0;
    end else if (init) begin
        init_r <= 1'b1;
    end
end
assign init_req = init_r;


reg request_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        request_r <= 1'b0;
    end else if (request_ack_r && !request) begin
        request_r <= 1'b0;
    end else if (request) begin
        request_r <= 1'b1;
    end
end
assign request_req = request_r;

reg rdy_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rdy_r <= 1'b0;
    end else if (rdy_ack_r) begin
        rdy_r <= 1'b0;
    end else if (rdy) begin
        rdy_r <= 1'b1;
    end
end
assign rdy_req = rdy_r;

//----------txfifo clear
reg [1:0] read_req_o;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        read_req_o <= 2'b00;
    end else begin
        read_req_o <= {read_req_o[0], read_req_ack};
    end
end
assign read_req_ack_r = read_req_o[1];

reg read_req_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        read_req_r <= 1'b0;
    end else if (read_req_ack_r) begin
        read_req_r <= 1'b0;
    end else if (read_req) begin
        read_req_r <= 1'b1;
    end
end
assign read_req_req = read_req_r;


assign txfifo_clr = read_req_r;


endmodule