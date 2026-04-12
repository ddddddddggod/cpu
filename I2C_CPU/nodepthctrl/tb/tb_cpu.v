`timescale 1ns / 1ps

module tb();

//================================================================
// Clock & Reset
//================================================================
localparam CLK1_FREQ = 33;  // MHz 
localparam HCLK_FREQ = 100; // MHz 

reg CLK1, HCLK;
reg reset_n;

initial CLK1 = 1'b0;
always #(1000.0/(2.0*CLK1_FREQ)) CLK1 = ~CLK1;

initial HCLK = 1'b0;
always #(1000.0/(2.0*HCLK_FREQ)) HCLK = ~HCLK;

initial begin
    reset_n = 1'b0;
    repeat(10) @(negedge CLK1);
    reset_n = 1'b1;
end

//================================================================
// I2C Bus
//================================================================
wire scl, sda;
pullup(sda);
pullup(scl);

//================================================================
// DUT
//================================================================
parameter [6:0] dev_adr = 7'h74;

AHBLITE_SYS #(
    .device_address(dev_adr)
) u_dut (
    .HCLK    (HCLK),
    .CLK1    (CLK1),
    .RESETn  (reset_n),
    .sda     (sda),
    .scl     (scl)
);

//================================================================
// I2C Master
//================================================================
i2c_master_top u_i2c_master (
    .clk     (CLK1),
    .reset_n (reset_n),
    .scl     (scl),
    .sda     (sda)
);

//================================================================
// Wave dump
//================================================================
`ifndef VCS
initial begin
    $shm_open("wave");
    $shm_probe("ASM", tb);
end
`else
initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
end
`endif

//================================================================
// Test Scenario
//================================================================
reg [7:0] rxr;
reg [7:0] rdata;

initial begin
    #50;

    // STEP 1: Write Addr 0x0A -> F5, FB, 77, 88
    u_i2c_master.start({dev_adr, 1'b0});
    u_i2c_master.byte(8'h0a, 1'b0, 1'b0, rxr);
    u_i2c_master.byte(8'hf5, 1'b0, 1'b0, rxr);
    u_i2c_master.byte(8'hfb, 1'b0, 1'b0, rxr);
    u_i2c_master.byte(8'h77, 1'b0, 1'b0, rxr);
    u_i2c_master.stop(8'h88, 1'b0, 1'b0, rxr);

    #600;

    // STEP 2: Set Read Address 0x0A
    u_i2c_master.start({dev_adr, 1'b0});
    u_i2c_master.stop(8'h0a, 1'b0, 1'b0, rxr);

    // STEP 3: Read back
    #50;
    u_i2c_master.start({dev_adr, 1'b1});
    u_i2c_master.byte(8'h00, 1'b1, 1'b0, rdata);
    u_i2c_master.stop(8'h00, 1'b1, 1'b1, rdata);

    // STEP 4: Write Addr 0x02 -> 55, AA
    #100;
    u_i2c_master.start({dev_adr, 1'b0});
    u_i2c_master.byte(8'h02, 1'b0, 1'b0, rxr);
    u_i2c_master.byte(8'h55, 1'b0, 1'b0, rxr);
    u_i2c_master.stop(8'haa, 1'b0, 1'b0, rxr);

    #500;

    // STEP 5: Repeated START
    #100;
    u_i2c_master.start({dev_adr, 1'b0});
    u_i2c_master.byte(8'h0c, 1'b0, 1'b0, rxr);
    u_i2c_master.start({dev_adr, 1'b1});
    u_i2c_master.stop(8'h00, 1'b1, 1'b1, rdata);

    // STEP 6: Zero-length Write
    #100;
    u_i2c_master.start({dev_adr, 1'b0});
    u_i2c_master.stop(8'h00, 1'b0, 1'b0, rxr);

    // STEP 7: Write Addr 0x20 -> 55,AA,BB
    u_i2c_master.start({dev_adr, 1'b0});
    u_i2c_master.byte(8'h20, 1'b0, 1'b0, rxr);
    u_i2c_master.byte(8'h55, 1'b0, 1'b0, rxr);   
    u_i2c_master.byte(8'haa, 1'b0, 1'b0, rxr);
    u_i2c_master.stop(8'hbb, 1'b0, 1'b0, rxr);

    // STEP 8: Set Read Address 0x20
    #100;
    u_i2c_master.start({dev_adr, 1'b0});
    u_i2c_master.stop(8'h20, 1'b0, 1'b0, rxr);

    // STEP 9: Read back 0x20 ~ 0x22
    #50;
    u_i2c_master.start({dev_adr, 1'b1});
    u_i2c_master.byte(8'h00, 1'b1, 1'b0, rdata);
    u_i2c_master.byte(8'h00, 1'b1, 1'b0, rdata);
    u_i2c_master.stop(8'h00, 1'b1, 1'b1, rdata);
    #2200;
    $finish;
end

endmodule
