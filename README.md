# cpu
---
🔴  **Before CPU integration, the master and RF modules were first designed and verified in Verilog. They were then implemented in firmware and integrated with the actual CPU.**

*) use ARM cortex m0 (Design Start)

*)The pass/fail result of the write operation display in `tb_apb.v` depends on the configured frequency (speed) and FIFO depth. 
Therefore, it should be adjusted accordingly or verified through waveform analysis.

### 1. No depth ctrl (without FIFO management) : Has two clocks  
  <p align="center">
    <img src="nodepthctrl/clock2.png" width="200">
  </p>
  
  - **HW**: Developed based on the previously implemented APB master–connected I2C APB module  [i2c_apb](https://github.com/ddddddddggod/APB/tree/main), with added MMIO registers and protocol compliance.

  - **CPU**: Updated the design by replacing the `apb_master` and `pkt_ctrl` with **CPU firmware**,  
    and substituting the `rf` with **SRAM**.
  
### 2. No depth ctrl_CDC (without FIFO management)
  : has three clock
      <p align="center">
  <img src="nodepthctrl_cdc/clock3.png" width="200"></p>
  </p>
    <p align="center">
      <img src="nodepthctrl_cdc/handshake.png" width="700">
  </p>
 In APB, `PWRITE` `PENABLE` `PSEL` already form a **handshake** with `PREADY`, so no additional ack signal is required. 
 Flip-flops  and multiplexers are used to align the timing.
 
### 3. DepthCtrl (fifo management)
  - **Depthctrl_RX** : Implements FIFO management for the **RX** path only.
    - The **RX FIFO** generates a write ***interrupt when it is filled up to its configured depth or when an init signal is asserted***, triggering data transfer to SRAM.
  - **Depthctrl** : Implements FIFO management for both **RX** and **TX** paths, with additional modularization.
    - The **TX FIFO** is ***pre-filled with data up to the configured depth when a read interrupt is received***. It is cleared when a start signal is asserted.
 

