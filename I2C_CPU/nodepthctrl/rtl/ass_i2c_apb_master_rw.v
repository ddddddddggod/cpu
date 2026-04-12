module ass_i2c_apb_master_rw (
    input             clk,
    input             rstb,
    input             pready,
    input      [31:0] prdata,
    input             interrupt,
    input      [7:0]  rfwdata,

    // APB Master -> Slave
    output reg [31:0] paddr,
    output reg        pwrite,
    output reg [31:0] pwdata,
    // pkt_ctrl
    output reg        rdy,
    output reg        request,
    output            init,
    // RF & addr
    output reg [7:0]  rfrdata,
    output            rw_valid
);

localparam [2:0] m_mask     = 3'd0;
localparam [2:0] m_idle     = 3'd1;
localparam [2:0] m_intr     = 3'd2;  
localparam [2:0] m_status   = 3'd3;  
localparam [2:0] m_read     = 3'd4;
localparam [2:0] m_write    = 3'd5;
localparam [2:0] m_intr_clr = 3'd6;  

localparam [31:0] status_addr   = 32'h5000_0000;
localparam [31:0] rxdata_addr   = 32'h5000_0004;
localparam [31:0] txdata_addr   = 32'h5000_0008;
localparam [31:0] intr_addr     = 32'h5000_000c;
localparam [31:0] intr_clr_addr = 32'h5000_0010;
localparam [31:0] intr_mask_addr = 32'h5000_0014;

reg [2:0] m_state, m_state_n;

// next state
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        m_state <= m_mask;
    end else begin
        m_state <= m_state_n;
    end
end

// intr_reg capture
reg [31:0] intr_captured;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        intr_captured <= 32'h0;
    end else if (m_state == m_intr && pready) begin
        intr_captured <= prdata;
    end
end
wire intr_init    = intr_captured[0];
wire intr_rdy     = intr_captured[1];
wire intr_request = intr_captured[2];

// status_reg 
wire status_rne  = prdata[0];  
wire status_tnf  = prdata[1];  

wire read = intr_rdy && status_rne;
wire write = intr_request && status_tnf;

// current state
always @(*) begin
    m_state_n = m_state;
    case (m_state)
        m_mask: if (pready) m_state_n = m_idle;
        m_idle: if (interrupt) m_state_n = m_intr;
        m_intr: if (pready) m_state_n = m_status;
        m_status: begin                
                if (pready) begin
                    if (intr_init) begin 
                        m_state_n = m_intr_clr;
                    end else if (read) begin
                        m_state_n = m_read;    
                    end else if (write) begin
                        m_state_n = m_write;
                    end else begin                                  
                        m_state_n = m_intr_clr;
                    end
                end
            end
        m_read: if (pready) m_state_n = m_intr_clr;
        m_write: if (pready) m_state_n = m_intr_clr;
        m_intr_clr: if (pready) m_state_n = m_idle;
    endcase
end

//_____________Output logic_________________________________________
assign rw_valid = (m_state != m_idle);

// rfrdata
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        rfrdata <= 8'h0;
    else if (m_state == m_read && pready)
        rfrdata <= prdata[7:0];
end

// init
reg init_r;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        init_r <= 1'b0;
    end else begin
        init_r <= (m_state == m_status) && pready && intr_init;
    end
end
assign init = init_r;

// rdy
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        rdy <= 1'b0;
    end else begin
        rdy <= (m_state == m_read) && pready;
    end
end

// request
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        request <= 1'b0;
    end else begin
        request <= (m_state == m_write) && pready;
    end
end

// paddr / pwrite / pwdata
always @(*) begin
    paddr  = 32'h0;
    pwrite = 1'b0;
    pwdata = 32'h0;
    case (m_state)
        m_mask: begin
            paddr  = intr_mask_addr;
            pwrite = 1'b1;
            pwdata = 32'h0;    
        end
        m_intr: begin
            paddr  = intr_addr;
            pwrite = 1'b0;
            pwdata = 32'h0;
        end
        m_status: begin
            paddr  = status_addr;
            pwrite = 1'b0;
            pwdata = 32'h0;
        end
        m_read: begin
            paddr  = rxdata_addr;
            pwrite = 1'b0;
            pwdata = 32'h0;
        end
        m_write: begin
            paddr  = txdata_addr;
            pwrite = 1'b1;
            pwdata = {24'h0, rfwdata};
        end
        m_intr_clr: begin
            paddr  = intr_clr_addr;
            pwrite = 1'b1;
            pwdata = 32'h7; 
        end
    endcase
end

endmodule
