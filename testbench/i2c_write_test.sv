`ifndef I2C_WRITE_TEST_SV
`define I2C_WRITE_TEST_SV

// ============================================================================
// I2C Write Test: Executes a 4-byte master write transfer to slave 7'h50
// ============================================================================
class i2c_write_test extends i2c_apb_base_test;

  `uvm_component_utils(i2c_write_test)

  function new(string name = "i2c_write_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    i2c_write_seq seq;
    seq = i2c_write_seq::type_id::create("i2c_write_seq");

    phase.raise_objection(this, "Starting i2c_write_test");
    `uvm_info("TEST", "==================================================", UVM_NONE)
    `uvm_info("TEST", "           RUNNING TEST: i2c_write_test           ", UVM_NONE)
    `uvm_info("TEST", "==================================================", UVM_NONE)

    seq.slave_addr = 7'h50;
    seq.data_bytes = '{8'h11, 8'h22, 8'h33, 8'h44};

    seq.start(env.apb_agnt.sequencer);

    #10us;
    `uvm_info("TEST", "==================================================", UVM_NONE)
    `uvm_info("TEST", "           FINISHED TEST: i2c_write_test          ", UVM_NONE)
    `uvm_info("TEST", "==================================================", UVM_NONE)
    phase.drop_objection(this, "Completed i2c_write_test");
  endtask

endclass

`endif // I2C_WRITE_TEST_SV
