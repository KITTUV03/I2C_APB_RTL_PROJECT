`ifndef I2C_APB_PACKAGE_SV
`define I2C_APB_PACKAGE_SV

`include "i2c_apb_defines.svh"
`include "apb_intf.sv"
`include "i2c_intf.sv"

package pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "i2c_sequence_item.sv"
  `include "apb_seq_item.sv"

  `include "apb_sequencer.sv"
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_agent.sv"

  `include "i2c_sequencer.sv"
  `include "i2c_driver.sv"
  `include "i2c_monitor.sv"
  `include "i2c_agent.sv"

  `include "i2c_apb_coverage.sv"
  `include "i2c_apb_scoreboard.sv"

  `include "apb_base_seq.sv"
  `include "i2c_write_seq.sv"
  `include "i2c_read_seq.sv"

  `include "i2c_apb_env.sv"
  `include "i2c_apb_base_test.sv"
  `include "i2c_write_test.sv"
  `include "i2c_read_test.sv"

endpackage

`endif 
