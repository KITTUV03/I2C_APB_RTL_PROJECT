`ifndef I2C_APB_DEFINES_SVH
`define I2C_APB_DEFINES_SVH

// ============================================================================
// Clock & Reset Definitions (Spec Section 4 & 9: 100 MHz PCLK)
// ============================================================================
`define PCLK_PERIOD    10ns
`define RESET_ASSERT   1'b0
`define RESET_DEASSERT 1'b1

// ============================================================================
// Bus Widths (Spec Section 3 & 5)
// ============================================================================
`define ADDR_WIDTH 5
`define DATA_WIDTH 8

// ============================================================================
// APB Register Address Offsets (Spec Section 5.1 & Table 2)
// ============================================================================
`define REG_SLV_ADDRH       5'h00  // Slave address high bits [9:8] (10-bit mode)
`define REG_SLV_ADDRL       5'h01  // Slave address low byte [6:0]
`define REG_MODE            5'h02  // Speed mode [2:1], 10-bit addressing [0]
`define REG_SCL_TIMEOUT2    5'h03  // Clock-stretch timeout [23:16]
`define REG_SCL_TIMEOUT1    5'h04  // Clock-stretch timeout [15:8]
`define REG_SCL_TIMEOUT0    5'h05  // Clock-stretch timeout [7:0]
`define REG_SDA_TIMEOUT2    5'h06  // SDA-stuck / bus-busy timeout [23:16]
`define REG_SDA_TIMEOUT1    5'h07  // SDA-stuck / bus-busy timeout [15:8]
`define REG_SDA_TIMEOUT0    5'h08  // SDA-stuck / bus-busy timeout [7:0]
`define REG_TX_DATA         5'h09  // Queue transmit byte (CMD_TX)
`define REG_RX_DATA         5'h0A  // Queue receive request (CMD_RX)
`define REG_IRQ_CLEAR       5'h0B  // Clear sticky IRQ status
`define REG_RX_FIFO         5'h10  // Read and pop received byte from RX FIFO
`define REG_TX_COUNT_HIGH   5'h11  // Transmitted data byte count [15:8]
`define REG_TX_COUNT_LOW    5'h12  // Transmitted data byte count [7:0]
`define REG_RX_COUNT_HIGH   5'h13  // Received data byte count [15:8]
`define REG_RX_COUNT_LOW    5'h14  // Received data byte count [7:0]
`define REG_IRQ_STATUS      5'h15  // Live sticky IRQ status bits

// ============================================================================
// IRQ_STATUS Bit Masks (Spec Section 5.2)
// ============================================================================
`define IRQ_NACK_BIT          0
`define IRQ_ARB_LOST_BIT      1
`define IRQ_SDA_ERR_BIT       2
`define IRQ_SDA_REC_BIT       3
`define IRQ_SCL_ERR_BIT       4
`define IRQ_BUS_BUSY_BIT      5
`define IRQ_CMD_FIFO_FULL_BIT 6
`define IRQ_ILLEGAL_BIT       7

// ============================================================================
// Waveform Macro for Simulation
// ============================================================================
`define WAVEFORM \
  initial begin \
    $dumpfile("dump.vcd"); \
    $dumpvars(0, tb_top); \
  end

`endif // I2C_APB_DEFINES_SVH
