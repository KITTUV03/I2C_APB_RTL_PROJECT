`ifndef I2C_APB_DEFINES_SVH
`define I2C_APB_DEFINES_SVH

// Clock & Reset Definitions 
`define PCLK_PERIOD    10ns
`define TIME_PERIOD    10ns
`define RESET_ASSERT   1'b0
`define RESET_DEASSERT 1'b1

// Waveform Dump Macro
`define WAVEFORM \
  initial begin \
    $dumpfile("dump.vcd"); \
    $dumpvars(0, tb_top); \
  end

// Interface Bus Widths
`define ADDR_WIDTH 5
`define DATA_WIDTH 8

// APB Register Address Offsets 
`define REG_SLV_ADDRH       5'h00
`define REG_SLV_ADDRL       5'h01
`define REG_MODE            5'h02
`define REG_SCL_TIMEOUT2    5'h03
`define REG_SCL_TIMEOUT1    5'h04
`define REG_SCL_TIMEOUT0    5'h05
`define REG_SDA_TIMEOUT2    5'h06
`define REG_SDA_TIMEOUT1    5'h07
`define REG_SDA_TIMEOUT0    5'h08
`define REG_TX_DATA         5'h09
`define REG_RX_DATA         5'h0A
`define REG_IRQ_CLEAR       5'h0B
`define REG_RX_FIFO         5'h10
`define REG_TX_COUNT_HIGH   5'h11
`define REG_TX_COUNT_LOW    5'h12
`define REG_RX_COUNT_HIGH   5'h13
`define REG_RX_COUNT_LOW    5'h14
`define REG_IRQ_STATUS      5'h15

// IRQ_STATUS Bit Masks 
`define IRQ_NACK_BIT          0
`define IRQ_ARB_LOST_BIT      1
`define IRQ_SDA_ERR_BIT       2
`define IRQ_SDA_REC_BIT       3
`define IRQ_SCL_ERR_BIT       4
`define IRQ_BUS_BUSY_BIT      5
`define IRQ_CMD_FIFO_FULL_BIT 6
`define IRQ_ILLEGAL_BIT       7

`endif
