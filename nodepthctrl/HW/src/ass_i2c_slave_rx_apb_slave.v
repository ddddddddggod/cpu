`timescale 1ns / 1ps
module ass_i2c_slave_rx_apb_slave(
    input clk,
    input rstb,
    //apb master
    input pwrite,
    input [31:0] paddr,
    input pena,
    input psel,
    input init_signal,

    output  wr_valid,
    output reg txwe,
    output  tx_valid,
    output  rd_valid,
    output rxre,
    //apb master
    output pready
);


localparam [1:0] apb_idle = 2'd0;
localparam [1:0] apb_setup = 2'd1;
localparam [1:0] apb_access = 2'd2;
localparam [31:0] rxdata_addr = 32'h5000_0004;
localparam [31:0] txdata_addr = 32'h5000_0008;

reg [1:0] apb_state, apb_state_n;

//next state
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        apb_state <= apb_idle;
    end else if (init_signal) begin
        apb_state <= apb_idle;
    end else begin           
        apb_state <= apb_state_n;
    end
end

//current state
always @(*) begin
    apb_state_n = apb_state;
    case (apb_state)
        apb_idle: apb_state_n = (psel) ? apb_setup : apb_idle;
        apb_setup: apb_state_n = (pena) ? apb_access : apb_setup;
        apb_access: apb_state_n = (pready) ? apb_idle : apb_access; 
    endcase
end

//_____________________Output logic_________________________________
wire read_access;
reg read_access_r;

reg rd_valid_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        read_access_r <= 1'b0;
    end else begin
        read_access_r <= read_access;
    end
end
assign read_access = (apb_state == apb_access) && !pwrite;
assign rd_valid = read_access && (paddr == rxdata_addr);
assign pready = (apb_state == apb_access) && (pwrite || read_access_r); 
assign wr_valid = pwrite && pready;
assign rxre = pready & !pwrite && (paddr == rxdata_addr); 
assign tx_valid = wr_valid && (paddr == txdata_addr);

always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        txwe <= 1'b0;
    end else begin
        txwe <= tx_valid;
    end
end


endmodule
