# cpu
---
use ARM cortex m0 (Design Start)
- **No depth ctrl (without FIFO management)**
  - **HW** :Developed based on the previously implemented APB master–connected I2C APB module [i2c_apb](https://github.com/ddddddddggod/APB/tree/main) with added MMIO registers and protocol compliance.
  - **CPU** : Updated the design by replacing the `apb_master` and `pkt_ctrl` with **CPU firmware**, and substituting the `rf` with **SRAM**.
- **No depth ctrl_CDC (without FIFO management)**
  : has three clock
