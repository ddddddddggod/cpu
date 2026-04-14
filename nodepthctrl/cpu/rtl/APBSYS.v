`timescale 1ns / 1ps
module APBSYS #(
    parameter [6:0] device_address = 7'h74
)(
    input  wire        scl,
    inout  wire        sda,        
    input  wire        HCLK,
    input  wire        CLK1,
    input  wire        HRESETn,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [31:0] HWDATA,
    input  wire        HSEL,
    input  wire        HREADY,
    output wire [31:0] HRDATA,
    output wire        HREADYOUT,
    output wire        interrupt    
);

wire PCLK;
wire PRESETn;
wire [31:0] PADDR;
wire PWRITE;
wire [31:0] PWDATA;
wire PENABLE;
wire PSEL_DUMMY1;
wire PREADY;
wire [31:0] PRDATA;

AHB2APB uAHB2APB (
    .HCLK     (HCLK),
    .HRESETn  (HRESETn),
    .HADDR    (HADDR),
    .HSEL     (HSEL),
    .HREADY   (HREADY),
    .HTRANS   (HTRANS),
    .HWDATA   (HWDATA),
    .HWRITE   (HWRITE),
    .HRDATA   (HRDATA),
    .HREADYOUT(HREADYOUT),
    .PCLK     (PCLK),
    .PRESETn  (PRESETn),
    .PADDR    (PADDR),
    .PWRITE   (PWRITE),
    .PWDATA   (PWDATA),
    .PENABLE  (PENABLE),
    .PREADY   (PREADY),
    .PRDATA   (PRDATA)
);

// assign apb_transfer = HSEL & HTRANS[1];

// always @(posedge HCLK or negedge HRESETn) begin
//     if (!HRESETn) begin
//         PSEL_DUMMY1 <= 1'b0;
//     end else if (apb_transfer) begin
//         PSEL_DUMMY1 <= 1'b1;
//     end else if (PREADY) begin
//         PSEL_DUMMY1 <= 1'b0;
//     end
// end
assign PSEL_DUMMY1 = (~HREADYOUT) | PENABLE;

ass_i2c_slave_rx #(
    .device_address(device_address)
) u_i2c_slave_rx (
    .clk1     (CLK1),
    .clk2     (PCLK),
    .rstb     (HRESETn),
    .scl      (scl),
    .sda      (sda),
    .pwrite   (PWRITE),
    .paddr    (PADDR),
    .pena     (PENABLE),
    .psel     (PSEL_DUMMY1),
    .pwdata   (PWDATA),
    .pready   (PREADY),
    .prdata   (PRDATA),
    .interrupt(interrupt)
);

endmodule
