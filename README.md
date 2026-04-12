# cpu
---
use ARM cortex m0 (Design Start)
- **I2C without CPU** :Developed based on the previously implemented APB master–connected I2C APB module [i2c_apb](https://github.com/ddddddddggod/APB/tree/main) with added MMIO registers and protocol compliance.
- **I2C with CPU** : Updated the design by replacing the `apb_master` and `pkt_ctrl` with **CPU firmware**, and substituting the `rf` with **SRAM**.
