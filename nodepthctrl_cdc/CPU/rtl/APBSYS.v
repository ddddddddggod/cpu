`timescale 1ns / 1ps
module APBSYS #(
    parameter [6:0] device_address = 7'h74
)(
    input  wire        scl,
    inout  wire        sda,        
    input  wire        HCLK,
    input  wire        PCLK,
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

wire [31:0] PADDR;
wire        PWRITE;
wire [31:0] PWDATA;
wire        PENABLE;
wire        PSEL_DUMMY1;
wire        PREADY;
wire [31:0] PRDATA;

// CDC
wire        pready_req;
wire        pready_ack;
wire        pready_signal;
wire        pena_req;
wire        pwrite_req;
wire        psel_req;
wire [31:0] prdata_cdc;

// slave cdc 
wire        pena_cdc;
wire        pwrite_cdc;
wire        psel_cdc;
wire [31:0] pwdata_cdc;
wire [31:0] paddr_cdc;


wire [31:0] prdata;
wire        pready;

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
    .PCLK     (),
    .PRESETn  (),
    .PADDR    (PADDR),
    .PWRITE   (PWRITE),
    .PWDATA   (PWDATA),
    .PENABLE  (PENABLE),
    .PREADY   (pready_signal),  
    .PRDATA   (prdata_cdc)      
);

assign PSEL_DUMMY1 = (~HREADYOUT) | PENABLE;

apb_rx_cdc u_apb_cdc (
    .clk            (HCLK),
    .rstb           (HRESETn),
    .pready_req     (pready_req),
    .pena           (PENABLE),
    .pwrite         (PWRITE),
    .psel           (PSEL_DUMMY1),
    .prdata         (prdata),
    .pready_ack     (pready_ack),
    .pready_signal  (pready_signal),
    .pena_req       (pena_req),
    .pwrite_req     (pwrite_req),
    .psel_req       (psel_req),
    .prdata_cdc     (prdata_cdc)
);

ass_i2c_slave_cdc u_i2c_cdc (
    .clk            (PCLK),
    .rstb           (HRESETn),
    .pready         (pready),
    .pready_ack     (pready_ack),
    .pena_req       (pena_req),
    .pwrite_req     (pwrite_req),
    .psel_req       (psel_req),
    .pwdata         (PWDATA),
    .paddr          (PADDR),
    .pready_req     (pready_req),
    .pena_cdc       (pena_cdc),
    .pwrite_cdc     (pwrite_cdc),
    .psel_cdc       (psel_cdc),
    .pwdata_cdc     (pwdata_cdc),
    .paddr_cdc      (paddr_cdc)
);

ass_i2c_slave_rx #(
    .device_address(device_address)
) u_i2c_slave_rx (
    .clk1     (CLK1),
    .clk2     (PCLK),
    .rstb     (HRESETn),
    .scl      (scl),
    .sda      (sda),
    .pwrite   (pwrite_cdc),
    .paddr    (paddr_cdc),
    .pena     (pena_cdc),
    .psel     (psel_cdc),
    .pwdata   (pwdata_cdc),
    .pready   (pready),
    .prdata   (prdata),
    .interrupt(interrupt)
);

endmodule