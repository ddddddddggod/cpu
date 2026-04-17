/* Register map (ass_i2c_apb_master_rw.v localparam) */
#define I2C_STATUS     (*(volatile unsigned long *)0x50000000)
#define I2C_RXDATA     (*(volatile unsigned long *)0x50000004)
#define I2C_TXDATA     (*(volatile unsigned long *)0x50000008)
#define I2C_INTR       (*(volatile unsigned long *)0x5000000C)
#define I2C_INTR_CLR   (*(volatile unsigned long *)0x50000010)
#define I2C_INTR_MASK  (*(volatile unsigned long *)0x50000014)
#define I2C_DEPTH_CTRL (*(volatile unsigned long *)0x50000018)

#define DEPTH_CTRL_VAL  3


unsigned char mem[128];
unsigned char addr;
unsigned char pkt_state;
//tx fifo management
unsigned char rf_wcnt;
unsigned char tx_write_cnt;



int main(void)
{
    addr = 0;
    pkt_state = 0;
    rf_wcnt = 0;
    tx_write_cnt = 0;

    I2C_INTR_CLR   = 7;            /* clear any stale interrupts  */
    I2C_INTR_MASK  = 0;            /* 0 = all interrupts enabled  */
    I2C_DEPTH_CTRL = DEPTH_CTRL_VAL; /* set TX depth limit        */

    return 0;
}


void __irq_hanlder_0(void)
{
    unsigned int  intr;
    unsigned int  status;
    unsigned char rx_data;
    intr = I2C_INTR;   
    /* ----------------------------------------------------------------
     * INTR_INIT : STOP or re-START detected
     * ----------------------------------------------------------------- */
    if (intr & 1) {
        status = I2C_STATUS;
        //for rxfifo management
        while (status & 1) {
            rx_data = (unsigned char)I2C_RXDATA;
            if (pkt_state == 0) {
                addr            = rx_data & 0x7F;   /* load_addr */
                mem[addr & 0x7F] = rx_data;          /* we        */
            } else {
                /* pkt_data: subsequent bytes are data */
                mem[addr & 0x7F] = rx_data;          /* we        */
                addr = (addr + 1) & 0x7F;            /* inc_addr  */
            }
            pkt_state = 1;      /* pkt_data */
            rf_wcnt++;          /*  rdy */
            status = I2C_STATUS;
        }
        pkt_state = 0;

    } else {

        /* -----------------------------------------------------------------
         * INTR_RDY : RX data available 
         * ----------------------------------------------------------------- */
        if (intr & 2) {
            status = I2C_STATUS;
            if (status & 1) {
                rx_data = (unsigned char)I2C_RXDATA;
                if (pkt_state == 0) {
                    addr             = rx_data & 0x7F;  /* load_addr */
                    mem[addr & 0x7F] = rx_data;         /* we        */
                } 
                else {
                    mem[addr & 0x7F] = rx_data;         /* we        */
                    addr = (addr + 1) & 0x7F;           /* inc_addr  */
                }
                pkt_state = 1;  /* -> pkt_data */
                rf_wcnt++;      /* rdy +1 */
                //rx fifo management
                status = I2C_STATUS;
                while (status & 1) {
                    rx_data = (unsigned char)I2C_RXDATA;
                    mem[addr & 0x7F] = rx_data;         /* we       */
                    addr = (addr + 1) & 0x7F;           /* inc_addr */
                    rf_wcnt++;  /* rdy +1 for each additional byte */
                    status = I2C_STATUS;
                }
            }
        }

        /* -----------------------------------------------------------------
         * INTR_REQUEST : TX data requested (intr[2])
         * ----------------------------------------------------------------- */
        if (intr & 4) {
            status = I2C_STATUS;
            // tx fifo management
            /*TNF && depth fill && rf left data (not written on txfifo)*/
            while ( (status & 2) && (tx_write_cnt < DEPTH_CTRL_VAL) && (rf_wcnt > tx_write_cnt) )
            {
                I2C_TXDATA = (unsigned int)mem[addr & 0x7F];
                addr = (addr + 1) & 0x7F;   /* inc_addr (pkt_ctrl) */
                pkt_state    = 1;            /* -> pkt_data         */
                tx_write_cnt++;
                status = I2C_STATUS;
            }
        }
    }

    /* -----------------------------------------------------------------
     * Interrupt clear  
     * ----------------------------------------------------------------- */
    I2C_INTR_CLR = intr & 7;                       /* clear all interrupt flags */
    rf_wcnt      = rf_wcnt - tx_write_cnt;   /* deduct bytes sent to FIFO */
    tx_write_cnt = 0;                        /* reset for next ISR cycle   */
}
