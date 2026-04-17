module ass_i2c_apb_master_rw (
    input             clk,
    input             rstb,
    input             pready,
    input      [31:0] prdata,
    input             interrupt,
    input      [7:0]  rfwdata,
    input      [3:0]  depth_ctrl,

    // APB Master -> Slave
    output reg [31:0] paddr,
    output reg        pwrite,
    output reg [31:0] pwdata,
    // pkt_ctrl
    output reg        rdy,
    output reg        request,
    output reg        init,
    // RF & addr
    output reg [7:0]  rfrdata,
    output            rw_valid
);

//state
localparam [3:0] m_mask     = 4'd0;
localparam [3:0] m_idle     = 4'd1;
localparam [3:0] m_intr     = 4'd2;  
localparam [3:0] m_status   = 4'd3;  
localparam [3:0] m_read     = 4'd4;
localparam [3:0] m_write    = 4'd5;
localparam [3:0] m_intr_clr = 4'd6;
localparam [3:0] m_depth    = 4'd7;
localparam [3:0] m_read_check = 4'd8;
localparam [3:0] m_write_check = 4'd9;   

//paddr
localparam [31:0] status_addr   = 32'h5000_0000;
localparam [31:0] rxdata_addr   = 32'h5000_0004;
localparam [31:0] txdata_addr   = 32'h5000_0008;
localparam [31:0] intr_addr     = 32'h5000_000c;
localparam [31:0] intr_clr_addr = 32'h5000_0010;
localparam [31:0] intr_mask_addr = 32'h5000_0014;
localparam [31:0] depth_addr = 32'h5000_0018;

reg [3:0] m_state, m_state_n;

// intr_reg capture
reg [31:0] intr_captured;
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        intr_captured <= 32'h0;
    end else if (m_state == m_intr && pready) begin
        intr_captured <= prdata;
    end
end


//wire
wire intr_init    = intr_captured[0];
wire intr_rdy     = intr_captured[1];
wire intr_request = intr_captured[2];
wire status_rne  = prdata[0];  
wire status_tnf  = prdata[1];  
wire status_pkt_start = prdata[2];
wire read = intr_rdy && status_rne;
wire write = intr_request && status_tnf;

//______________txfifo management__________________
reg [3:0] tx_write_cnt;

//rf에 있는  tx fifo에 쓰이지 않은 data 수
reg [3:0] rf_wcnt;
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        rf_wcnt <= 4'h0;
    else if (rdy)              
        rf_wcnt <= rf_wcnt + 1;
    else if (m_state == m_intr_clr)  
        rf_wcnt <= rf_wcnt - tx_write_cnt;
end

//txfifo에 write한 수
always @(posedge clk or negedge rstb) begin
    if (!rstb)
        tx_write_cnt <= 4'd0;
    else if (m_state == m_idle)
        tx_write_cnt <= 4'd0;              
    else if (m_state == m_write && pready)
        tx_write_cnt <= tx_write_cnt + 1;    
end

// 아직 txfifo에 올리지 않은 RF 데이터가 있는가
wire left_data = (rf_wcnt > tx_write_cnt);

//txfifo 채우기 멈추는 조건 1.depth이상일 때 2. rf에 더이상 쓰일 데이터가 없을 때 (data 수가 depth미만)
wire tx_fill_stop = (tx_write_cnt >= depth_ctrl) || !left_data;

//_________________state___________________________________
// next state
always @(posedge clk or negedge rstb) begin
    if (!rstb) begin
        m_state <= m_mask;
    end else begin
        m_state <= m_state_n;
    end
end
// current state
always @(*) begin
    m_state_n = m_state;
    case (m_state)
        m_mask: if (pready) m_state_n = m_depth;
        m_depth: if (pready) m_state_n = m_idle;
        m_idle: if (interrupt) m_state_n = m_intr;
        m_intr: if (pready) m_state_n = m_status;
        m_status: begin
            if (pready) begin
                if (intr_init) begin
                    if (status_rne) begin
                        m_state_n = m_read;      // fifo management
                    end else begin
                        m_state_n = m_intr_clr;
                    end 
                end else if (read) begin
                    m_state_n = m_read;
                end else if (write) begin
                    m_state_n = m_write;
                end else begin
                    m_state_n = m_intr_clr;
                end
            end
        end
        m_read: if (pready) m_state_n = m_read_check;
        m_read_check: if (pready) begin
                        if (status_rne) begin         //fifo management
                            m_state_n = m_read;
                        end else begin              
                            m_state_n = m_intr_clr;
                        end
                    end
        m_write: if (pready) m_state_n = m_write_check;
        m_write_check: if (pready) begin
                        if (status_tnf && !tx_fill_stop) begin
                            m_state_n = m_write;
                        end else begin
                            m_state_n = m_intr_clr;
                        end
                    end
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
        m_depth: begin
            paddr = depth_addr;
            pwrite = 1'b1;
            pwdata = {28'h0, depth_ctrl};
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
        m_read_check: begin
            paddr = status_addr;
            pwrite = 1'b0;
            pwdata = 32'h0;
        end
        m_write: begin
            paddr  = txdata_addr;
            pwrite = 1'b1;
            pwdata = {24'h0, rfwdata};
        end
        m_write_check: begin
            paddr = status_addr;
            pwrite = 1'b0;
            pwdata = 32'h0;
        end
        m_intr_clr: begin
            paddr  = intr_clr_addr;
            pwrite = 1'b1;
            pwdata = 32'h7; 
        end
    endcase
end

endmodule
