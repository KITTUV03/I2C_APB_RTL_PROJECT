`ifndef I2C_SEQUENCER_SV
`define I2C_SEQUENCER_SV

// ============================================================================
// I2C Sequencer: UVM sequencer for I2C transactions
// ============================================================================
class i2c_sequencer extends uvm_sequencer #(i2c_seq_item);

  `uvm_component_utils(i2c_sequencer)

  function new(string name = "i2c_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif // I2C_SEQUENCER_SV
