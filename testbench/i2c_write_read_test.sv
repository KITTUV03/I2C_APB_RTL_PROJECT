`ifndef I2C_WRITE_READ_TEST_SV
`define I2C_WRITE_READ_TEST_SV

class i2c_write_read_test extends i2c_apb_base_test;

  `uvm_component_utils(i2c_write_read_test)

  function new(string name = "i2c_write_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    i2c_write_seq wr_seq;
    i2c_read_seq  rd_seq;

    wr_seq = i2c_write_seq::type_id::create("wr_seq");
    rd_seq = i2c_read_seq::type_id::create("rd_seq");

    phase.raise_objection(this, "Starting i2c_write_read_test");

    `uvm_info("TEST", "==================================================", UVM_NONE)
    `uvm_info("TEST", "     RUNNING COMBINED TEST: WRITE THEN READ       ", UVM_NONE)
    `uvm_info("TEST", "==================================================", UVM_NONE)

    // Phase 1: Run Write Sequence (4 bytes to slave 7'h50)
    `uvm_info("TEST", "--- [STEP 1/2] Executing Master Write Transfer ---", UVM_NONE)
    wr_seq.slave_addr = 7'h50;
    wr_seq.data_bytes = '{8'h11, 8'h22, 8'h33, 8'h44};
    wr_seq.start(env.apb_agnt.sequencer);

    // Wait between transactions for bus-free time (tBUF)
    #25us;

    // Phase 2: Run Read Sequence (4 bytes from slave 7'h50)
    `uvm_info("TEST", "--- [STEP 2/2] Executing Master Read Transfer ---", UVM_NONE)
    rd_seq.slave_addr = 7'h50;
    rd_seq.num_bytes  = 4;
    rd_seq.start(env.apb_agnt.sequencer);

    #15us;
    `uvm_info("TEST", "==================================================", UVM_NONE)
    `uvm_info("TEST", "     FINISHED COMBINED TEST: WRITE THEN READ      ", UVM_NONE)
    `uvm_info("TEST", "==================================================", UVM_NONE)

    phase.drop_objection(this, "Completed i2c_write_read_test");
  endtask

endclass

`endif // I2C_WRITE_READ_TEST_SV
