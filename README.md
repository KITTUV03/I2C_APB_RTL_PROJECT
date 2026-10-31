# I2C Master Controller with APB4 Interface (`I2C_APB_RTL_PROJECT`)

This repository contains the RTL implementation and a modular UVM 1.2 Verification Environment for an **I2C Master Controller with APB4 Configuration Interface** based on the design specification (v1.1) and NXP/Philips I2C-Bus Specification (UM10204).

---

## 📁 Repository Structure

```text
I2C_APB_RTL_PROJECT/
├── design/                     # RTL Design Files
│   ├── design.sv               # Top-level DUT wrapper (`i2c_top`)
│   ├── i2c_bit.sv              # Bit-level controller & line timing
│   ├── i2c_byte_fsm.sv         # Byte-level transaction FSM
│   ├── i2c_counter.sv          # Shared timing counter
│   ├── i2c_fifo.sv             # Parameterized synchronous FIFO (CMD & RX FIFOs)
│   ├── i2c_glitch.sv           # Digital debounce / glitch suppression filter
│   └── sync_2ff.sv             # 2-stage flip-flop synchronizer
│
├── testbench/                  # UVM 1.2 Verification Testbench
│   ├── apb_agent.sv            # APB4 UVM Agent
│   ├── apb_driver.sv           # APB4 2-phase Master Driver
│   ├── apb_intf.sv             # APB4 Physical Interface
│   ├── apb_monitor.sv          # APB4 Bus Monitor
│   ├── apb_seq_item.sv         # APB Transfer Sequence Item
│   ├── apb_sequencer.sv        # APB Sequencer
│   ├── apb_base_seq.sv         # APB Helper Sequence (write_reg, read_reg, poll_reg)
│   ├── i2c_agent.sv            # I2C UVM Agent
│   ├── i2c_driver.sv           # Reactive Slave Driver / Memory Model (Factory Overridable)
│   ├── i2c_intf.sv             # Open-Drain I2C Physical Interface with Pull-ups
│   ├── i2c_monitor.sv          # I2C Bus Protocol Monitor
│   ├── i2c_sequence_item.sv    # I2C Transaction Item
│   ├── i2c_sequencer.sv        # I2C Sequencer
│   ├── i2c_apb_coverage.sv     # Functional Coverage Subscriber
│   ├── i2c_apb_defines.svh     # Clock, reset, register offsets & bit masks
│   ├── i2c_apb_env.sv          # UVM Verification Environment
│   ├── i2c_apb_package.sv      # Package `pkg` compiling all components
│   ├── i2c_apb_scoreboard.sv   # Scoreboard Checker (TX/RX data, byte counters)
│   ├── i2c_apb_base_test.sv    # Base UVM Test
│   ├── i2c_write_seq.sv        # 4-Byte Master Write Sequence
│   ├── i2c_write_test.sv       # Testcase 1: Master Write Test
│   ├── i2c_read_seq.sv         # 4-Byte Master Read Sequence
│   ├── i2c_read_test.sv        # Testcase 2: Master Read Test
│   ├── readme.md               # Interface connection mapping
│   └── testbench.sv            # Top-Level Testbench Module (`tb_top`)
│
├── .gitignore
└── README.md
```

---

## 🚀 Key Features

- **APB4 Slave Interface**: Two-phase APB (`PSEL`, `PENABLE`, `PWRITE`, `PADDR[4:0]`, `PWDATA[7:0]`, `PRDATA[7:0]`).
- **Command FIFO (12-bit, Depth 1024)**: Writes to `0x00`–`0x0A` are queued as 12-bit command words `{PADDR[3:0], PWDATA[7:0]}`.
- **I2C Protocol Support**:
  - Standard-mode (100 kHz), Fast-mode (400 kHz), Fast-mode Plus (1 MHz).
  - 7-bit and 10-bit slave addressing.
  - Automatic START, repeated START, and STOP generation.
  - Multi-byte write and read bursts.
  - Master clock stretching support and programmable `stretch_timeout`.
  - Stuck SDA detection and 9-clock bus-recovery sequence.
- **Verification Environment**:
  - Fully spec-compliant **UVM 1.2** architecture.
  - **Autonomous Reactive Slave Driver**: Emulates an EEPROM memory model with configurable slave address (`7'h50`). All response tasks are `virtual` to allow UVM **Factory Overriding** for error injection.
  - **Scoreboard**: End-to-end data integrity checking (APB `CMD_TX` vs I2C bus write, I2C slave data vs APB `RX_FIFO` reads).
  - **Functional Coverage Subscriber**: Cross-coverage of registers, R/W operations, addressing modes, and burst sizes.

---

## ⚡ Simulation Instructions

### Using QuestaSim / ModelSim
```bash
# Compile design and testbench
vlog -timescale 1ns/1ps -mfcu +acc=rmb -sv +incdir+design +incdir+testbench design/design.sv testbench/testbench.sv

# Run Master Write Test
vsim -voptargs=+acc work.tb_top +UVM_TESTNAME=i2c_write_test -do "run -all; quit"

# Run Master Read Test
vsim -voptargs=+acc work.tb_top +UVM_TESTNAME=i2c_read_test -do "run -all; quit"
```

### Using Synopsys VCS
```bash
vcs -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps +incdir+design+testbench design/design.sv testbench/testbench.sv -o simv
./simv +UVM_TESTNAME=i2c_write_test
./simv +UVM_TESTNAME=i2c_read_test
```

