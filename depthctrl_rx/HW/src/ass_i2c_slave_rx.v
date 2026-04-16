`timescale 1ns / 1ps

module ass_i2c_slave_rx #(
    parameter [6:0] device_address = 7'h74
)(
    input        clk1,
    input        clk2,
    input        rstb,
    input        scl,
    input        sda,
    input        pwrite,
    input [31:0] paddr,
    input        pena,
    input        psel,
    input [31:0]  pwdata,
    
    output        pready,
    output [31:0]  prdata,
    output        interrupt
    );
 
 wire sda_oe;
 assign sda = sda_oe ? 1'b0 : 1'bz;
//---------SDA,SCL Synchronization---------
wire scl_rising, scl_falling, start_det, stop_det, sda_in;

ass_i2c_slave_rx_sync u_sync (
    .clk        (clk1),
    .rstb       (rstb),
    .scl        (scl),
    .sda        (sda),
    .scl_rising (scl_rising),
    .scl_falling(scl_falling),
    .sda_in     (sda_in),
    .start_det  (start_det),
    .stop_det   (stop_det)
);

//--------FSM---------------------
wire rxempty, rxfull;
wire txempty, txfull;

wire count_clr, count_done;
wire shift_rx_en, shift_tx_en;
wire sda_out_bit;
wire rxwe, txre;
wire [7:0] rxwdata;
wire [7:0] txwdata;
wire load_data;
wire init_ack, init_req, request_req, request_ack, rdy_ack, rdy_req;

ass_i2c_slave_rx_ctrl #(
    .SLAVE_ADDR(device_address)
) u_ctrl (
    .clk        (clk1),
    .rstb       (rstb),
    .start_det  (start_det),
    .stop_det   (stop_det),
    .scl_rising (scl_rising),
    .scl_falling(scl_falling),
    .count_done (count_done),
    .sda_in     (sda_in),
    .wdata      (rxwdata),
    .sda_out_bit(sda_out_bit),
    .rxfull     (rxfull),
    .txempty    (txempty),
    .init_ack   (init_ack),
    .request_ack(request_ack),
    .rdy_ack    (rdy_ack),

    .sda_oe     (sda_oe),
    .count_clr  (count_clr),
    .shift_rx_en(shift_rx_en),
    .shift_tx_en(shift_tx_en),
    .request_req(request_req),
    .init_req   (init_req),
    .rdy_req    (rdy_req),
    .rxwe       (rxwe),
    .txre       (txre),
    .load_data  (load_data)
);

//------RX FIFO---------------
wire [7:0] rxrdata;
wire       rxre;
wire [4:0] rx_diff;

generic_fifo_dc #(
    .dw(8),
    .aw(4)
) u_rx_fifo (
    .wr_clk (clk1),
    .rd_clk (clk2),
    .rst    (rstb),
    .clr    (1'b0),
    .din    (rxwdata),
    .we     (rxwe),
    .dout   (rxrdata),
    .re     (rxre),
    .empty  (rxempty),
    .full   (rxfull),
    .full_n (),
    .empty_n(),
    .level  (),
    .diff   (rx_diff)
);

//--------TX FIFO---------------
wire [7:0] txrdata;
wire       txwe;
wire [4:0] tx_diff;

generic_fifo_dc #(
    .dw(8),
    .aw(4)
) u_tx_fifo (
    .wr_clk (clk2),
    .rd_clk (clk1),
    .rst    (rstb),
    .clr    (1'b0),
    .din    (txwdata), //txwdata
    .we     (txwe),
    .dout   (txrdata),
    .re     (txre),
    .empty  (txempty),
    .full   (txfull),
    .full_n (),
    .empty_n(),
    .level  (),
    .diff   (tx_diff)
);

//----------bit counter------------------
ass_i2c_slave_bit_counter u_cnt (
    .clk        (clk1),
    .rstb       (rstb),
    .count_clr  (count_clr),
    .shift_rx_en(shift_rx_en),
    .shift_tx_en(shift_tx_en),
    .count_done (count_done)
);

//--------Deserializer------------------------
//RX
ass_i2c_slave_rx_deserializer u_rx_deserial (
    .clk        (clk1),
    .rstb       (rstb),
    .sda_in     (sda_in),
    .shift_rx_en(shift_rx_en),
    .wdata      (rxwdata)
);

//TX
ass_i2c_slave_tx_deserializer u_tx_deserial (
    .clk        (clk1),
    .rstb       (rstb),
    .shift_tx_en(shift_tx_en),
    .load_data  (load_data),
    .txrdata    (txrdata),
    .sda_out_bit(sda_out_bit)
);


//-----------apb slave-----------------------
wire wr_valid, tx_valid, rd_valid;
wire init_signal;
wire rxfifo_out, txfifo_out;
ass_i2c_slave_rx_apb_slave u_apb_slave (
    .clk        (clk2),
    .rstb       (rstb),
    .pwrite     (pwrite),
    .paddr      (paddr),
    .pena       (pena),
    .psel       (psel),
    .init_signal(init_signal),
    .rxfifo_out (rxfifo_out),

    .wr_valid   (wr_valid),
    .txwe       (txwe),
    .tx_valid   (tx_valid),
    .rd_valid   (rd_valid),
    .rxre       (rxre),
    .pready     (pready)
        );
//-----------interrupt generator-----------------------
wire init_irq, request_irq, rdy_irq;
wire init_clr, rdy_clr, request_clr;
wire [2:0] intr_mask;
ass_i2c_slave_rx_interrupt_gen u_intr_gen (
    .clk        (clk2),
    .rstb       (rstb),
    .request_req(request_req),
    .init_req   (init_req),
    .rdy_req    (rdy_req),
    .rxre       (rxre),
    .tx_valid   (tx_valid),
    .init_clr   (init_clr),
    .request_clr(request_clr),
    .rdy_clr    (rdy_clr),
    .intr_mask  (intr_mask),
    .rxfifo_out (rxfifo_out),
    .txfifo_out (txfifo_out),

    .request_ack(request_ack),
    .init_ack   (init_ack),
    .rdy_ack    (rdy_ack),
    .interrupt  (interrupt),
    .init_irq   (init_irq),
    .request_irq(request_irq),
    .rdy_irq    (rdy_irq),
    .init_signal(init_signal)
);

//-----------MMIO----------------------------------------
wire [3:0] depth_count;
ass_i2c_slave_rx_mmio  u_mmio (
    .clk        (clk2),
    .rstb       (rstb),
    .rxempty    (rxempty),
    .rxrdata    (rxrdata),
    .txfull     (txfull),
    .paddr      (paddr),
    .pwdata     (pwdata),
    .wr_valid   (wr_valid),
    .tx_valid   (tx_valid),
    .rd_valid   (rd_valid),
    .init_irq   (init_irq),
    .request_irq(request_irq),
    .rdy_irq    (rdy_irq),
    .pwrite     (pwrite),
    .prdata     (prdata),
    .txwdata    (txwdata),
    .init_clr   (init_clr),
    .request_clr (request_clr),
    .rdy_clr    (rdy_clr),
    .intr_mask  (intr_mask),

    .depth_count(depth_count)
    );

//---------Depth Ctrl-----------------------------------
ass_i2c_slave_rx_depth_ctrl u_depth_ctrl (
    .clk         (clk2),
    .rstb        (rstb),
    .rx_diff     (rx_diff),
    .tx_diff     (tx_diff),
    .txfull      (txfull),
    .rxempty     (rxempty),
    .depth_count (depth_count),
    .init_signal (init_signal),

    .rxfifo_out  (rxfifo_out),
    .txfifo_out  (txfifo_out)
    );

endmodule
