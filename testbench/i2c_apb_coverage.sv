`ifndef I2C_APB_COVERAGE_SV
`define I2C_APB_COVERAGE_SV

// ============================================================================
// I2C APB Coverage Subscriber: Measures functional coverage on APB and I2C buses
// ============================================================================
class i2c_apb_coverage extends uvm_subscriber #(apb_seq_item);

  `uvm_component_utils(i2c_apb_coverage)

  `uvm_analysis_imp_decl(_i2c)
  uvm_analysis_imp_i2c #(i2c_seq_item, i2c_apb_coverage) i2c_export;

  apb_seq_item  sampled_apb;
  i2c_seq_item  sampled_i2c;

  // Covergroup 1: APB Register Accesses
  covergroup cg_apb;
    cp_paddr: coverpoint sampled_apb.paddr {
      bins slv_addrh       = {`REG_SLV_ADDRH};
      bins slv_addrl       = {`REG_SLV_ADDRL};
      bins mode            = {`REG_MODE};
      bins tx_data         = {`REG_TX_DATA};
      bins rx_data         = {`REG_RX_DATA};
      bins irq_clear       = {`REG_IRQ_CLEAR};
      bins rx_fifo         = {`REG_RX_FIFO};
      bins tx_count_low    = {`REG_TX_COUNT_LOW};
      bins rx_count_low    = {`REG_RX_COUNT_LOW};
      bins irq_status      = {`REG_IRQ_STATUS};
    }

    cp_pwrite: coverpoint sampled_apb.pwrite {
      bins read  = {1'b0};
      bins write = {1'b1};
    }

    cx_addr_pwrite: cross cp_paddr, cp_pwrite;
  endgroup

  // Covergroup 2: I2C Bus Transactions
  covergroup cg_i2c;
    cp_rw: coverpoint sampled_i2c.rw {
      bins write_trans = {1'b0};
      bins read_trans  = {1'b1};
    }

    cp_addr: coverpoint sampled_i2c.addr {
      bins slave_50 = {7'h50};
    }

    cp_ack: coverpoint sampled_i2c.ack {
      bins ack  = {1'b0};
      bins nack = {1'b1};
    }

    cp_burst_len: coverpoint sampled_i2c.data_q.size() {
      bins single_byte = {1};
      bins short_burst = {[2:4]};
      bins long_burst  = {[5:16]};
    }

    cx_rw_ack: cross cp_rw, cp_ack;
  endgroup

  function new(string name = "i2c_apb_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_apb = new();
    cg_i2c = new();
    i2c_export = new("i2c_export", this);
  endfunction

  virtual function void write(apb_seq_item t);
    sampled_apb = t;
    cg_apb.sample();
  endfunction

  virtual function void write_i2c(i2c_seq_item t);
    sampled_i2c = t;
    cg_i2c.sample();
  endfunction

endclass

`endif // I2C_APB_COVERAGE_SV
