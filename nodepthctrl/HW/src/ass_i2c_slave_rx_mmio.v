`timescale 1ns / 1ps

module ass_i2c_slave_rx_mmio(
	input clk,
	input rstb,
	input rxempty,
	input [7:0] rxrdata,
	input txfull,

	//apb master
	input [31:0] paddr,
	input [31:0] pwdata,
    input wr_valid,
    input tx_valid,
    input rd_valid,
    input init_irq,
    input request_irq,
    input rdy_irq,

	output reg [31:0] prdata,
    output [7:0] txwdata,
    output  init_clr,
    output  request_clr,
    output  rdy_clr,
    output [2:0] intr_mask
);

localparam [31:0] status_addr   = 32'h5000_0000;
localparam [31:0] rxdata_addr   = 32'h5000_0004;
localparam [31:0] txdata_addr   = 32'h5000_0008;
localparam [31:0] intr_addr     = 32'h5000_000c;
localparam [31:0] intr_clr_addr = 32'h5000_0010;
localparam [31:0] intr_mask_addr= 32'h5000_0014;


//1. status register
wire init 	  = init_irq;
wire rne      = ~rxempty;
wire tnf      = ~txfull;

wire [1:0] status_next;
assign status_next = {tnf, rne};
wire status_ena;
assign status_ena = 1'b1;
reg [31:0] status_reg;
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        status_reg <= 32'h0;
    else if (status_ena)
        status_reg <= {30'h0 ,status_next}; 
end


//2. rx  data register (rx->rf)
reg [31:0] rxdata_reg;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rxdata_reg   <= 32'h0;
    end else begin
        if (rd_valid) begin
            rxdata_reg <= {24'h0,rxrdata};
        end
    end
end

//3. tx data regiser (rf ->tx)
reg [31:0] txdata_reg;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        txdata_reg <= 32'h0;
    end else if (tx_valid) begin
        txdata_reg <= pwdata;  // RF dout
    end
end


//4. Interrupt register
wire [31:0] intr_reg;
assign intr_reg = {29'h0, request_irq, rdy_irq, init_irq};

//5. Interrupt clear register
reg [31:0] intr_clr_reg;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        intr_clr_reg <= 32'h0;
    end else if (wr_valid && paddr == intr_clr_addr) begin
        intr_clr_reg <= pwdata;  
    end else begin
        intr_clr_reg <= 32'h0;
    end
end
assign init_clr =  intr_clr_reg[0];
assign rdy_clr = intr_clr_reg[1];
assign request_clr =intr_clr_reg[2];


//5. mask register
reg [31:0] intr_mask_reg;
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        intr_mask_reg <= 32'h0;
    else if (wr_valid && (paddr == intr_mask_addr))
        intr_mask_reg <= pwdata;
end
assign intr_mask = intr_mask_reg[2:0];
//-----------MASTER INTERFACE--------------
always @(*) begin
    case (paddr)
        status_addr: prdata = status_reg[31:0];
        rxdata_addr: prdata = rxdata_reg[31:0];
        txdata_addr: prdata = txdata_reg[31:0];
        intr_addr: prdata = intr_reg[31:0];
        default: prdata = 32'h0;
    endcase
end

assign txwdata = txdata_reg[7:0];

endmodule
