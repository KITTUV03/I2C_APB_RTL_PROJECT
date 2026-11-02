`ifndef I2C_READ_TEST_SV
`define I2C_READ_TEST_SV

class i2c_read_test extends i2c_apb_base_test;

  `uvm_component_utils(i2c_read_test)

  function new(string name = "i2c_read_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    i2c_read_seq seq;
    seq = i2c_read_seq::type_id::create("i2c_read_seq");

    phase.raise_objection(this, "Starting i2c_read_test");
    
    seq.slave_addr = 7'h50;
    seq.num_bytes  = 4;

    seq.start(env.apb_agnt.sequencer);

    #10us;
    
    phase.drop_objection(this, "Completed i2c_read_test");
  endtask

endclass

`endif 

