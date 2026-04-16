# cpu
---
*) 본인이 설정한 주파수(속도) 및 depth 에 따라 tb_apb.v의 display write 출력 (pass,fail)이 달라짐으로 이를 적절히 수정 or 파형으로 올바름을 확인.
use ARM cortex m0 (Design Start)
- **No depth ctrl (without FIFO management)**
  - **HW** :Developed based on the previously implemented APB master–connected I2C APB module [i2c_apb](https://github.com/ddddddddggod/APB/tree/main) with added MMIO registers and protocol compliance.
  - **CPU** : Updated the design by replacing the `apb_master` and `pkt_ctrl` with **CPU firmware**, and substituting the `rf` with **SRAM**.
- **No depth ctrl_CDC (without FIFO management)**
  : has three clock
