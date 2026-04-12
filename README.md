# cpu
---
use cortex m0 
- **I2C without CPU** : 이전에 apb master에 연결한 [i2c_apb](https://github.com/ddddddddggod/APB/tree/main) 에서 develop함. (mmio register 추가 및 프로토콜 준수)
- **I2C with CPU** : `apb_master`과 `pkt_ctrl`을 실제 cpu frimware로 수정 `rf`를 실제 SRAM으로 수정
