`ifndef I2C_APB_BASE_TEST_SV
`define I2C_APB_BASE_TEST_SV

class i2c_apb_base_test extends uvm_test;

  `uvm_component_utils(i2c_apb_base_test)

  i2c_apb_env env;

  function new(string name = "i2c_apb_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = i2c_apb_env::type_id::create("env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass

`endif 

