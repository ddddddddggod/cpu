#define I2C_STATUS    (*(volatile unsigned long *)0x50000000)
#define I2C_RXDATA    (*(volatile unsigned long *)0x50000004)
#define I2C_TXDATA    (*(volatile unsigned long *)0x50000008)
#define I2C_INTR      (*(volatile unsigned long *)0x5000000C)
#define I2C_INTR_CLR  (*(volatile unsigned long *)0x50000010)
#define I2C_INTR_MASK (*(volatile unsigned long *)0x50000014)

unsigned char mem[128];
unsigned char addr;
unsigned char pkt_state;   /* 0: next RX byte is address, 1: data byte */

int main(void)
{
    addr      = 0;
    pkt_state = 0;
    I2C_INTR_CLR  = 7;
    I2C_INTR_MASK = 0;   /* 0 = all interrupts enabled */

}

void __irq_hanlder_0(void)
{
    unsigned int  intr;
    unsigned int  status;
    unsigned char rx_data;

    intr = I2C_INTR;   /* bit0=init(STOP/re-START), bit1=rdy(RX), bit2=request(TX) */

    /* STOP / re-START (intr_init)*/
    if (intr & 1) {
        pkt_state = 0;
    }
    else {
        /* RX: data received (intr_rdy) */
        if (intr & 2) {
            status = I2C_STATUS;
            if (status & 1) {                       /* RNE */
                rx_data = (unsigned char)I2C_RXDATA;

                if (pkt_state == 0) {               /*pkt_state == pkt_idle*/
                    addr = rx_data & 0x7F;          /* first byte = memory address (load_addr) */
                }
                else {                              /* pkt_state == 1 (pkt_data) */
                    mem[addr & 0x7F] = rx_data;     /* we */
                    addr = (addr + 1) & 0x7F;       /* inc_addr */
                }
                pkt_state = 1;                      /*pkt_data set*/
            }
        }

        /* TX: data requested (intr_request) */
        if (intr & 4) {
            status = I2C_STATUS;
            if (status & 2) {                       /* TNF*/
                I2C_TXDATA = (unsigned int)mem[addr & 0x7F];
                addr = (addr + 1) & 0x7F;           /* inc_addr */
                pkt_state = 1;
            }
        }
    }

    I2C_INTR_CLR = intr & 7;
}
