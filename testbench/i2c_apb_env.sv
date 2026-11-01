`ifndef I2C_APB_ENV_SV
`define I2C_APB_ENV_SV

// ============================================================================
// I2C APB Environment: Instantiates and connects APB agent, I2C agent,
// scoreboard, and coverage subscriber.
// ============================================================================
class i2c_apb_env extends uvm_env;

  `uvm_component_utils(i2c_apb_env)

  apb_agent          apb_agnt;
  i2c_agent          i2c_agnt;
  i2c_apb_scoreboard scb;
  i2c_apb_coverage   cov;

  function new(string name = "i2c_apb_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_agnt = apb_agent::type_id::create("apb_agnt", this);
    i2c_agnt = i2c_agent::type_id::create("i2c_agnt", this);
    scb      = i2c_apb_scoreboard::type_id::create("scb", this);
    cov      = i2c_apb_coverage::type_id::create("cov", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect APB monitor to Scoreboard and Coverage
    apb_agnt.monitor.item_collected_port.connect(scb.apb_export);
    apb_agnt.monitor.item_collected_port.connect(cov.analysis_export);

    // Connect I2C monitor to Scoreboard and Coverage
    i2c_agnt.monitor.item_collected_port.connect(scb.i2c_export);
    i2c_agnt.monitor.item_collected_port.connect(cov.i2c_export);
  endfunction

endclass

`endif // I2C_APB_ENV_SV
