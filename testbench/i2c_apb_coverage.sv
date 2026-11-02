`ifndef I2C_APB_COVERAGE_SV
`define I2C_APB_COVERAGE_SV

class i2c_apb_coverage extends uvm_subscriber #(apb_seq_item);

  `uvm_component_utils(i2c_apb_coverage)

  `uvm_analysis_imp_decl(_i2c)
  uvm_analysis_imp_i2c #(i2c_seq_item, i2c_apb_coverage) i2c_export;

  apb_seq_item  sampled_apb;
  i2c_seq_item  sampled_i2c;

  covergroup cg_apb;
    cp_paddr: coverpoint sampled_apb.paddr {
      bins slv_addrh       = {`REG_SLV_ADDRH};
      bins slv_addrl       = {`REG_SLV_ADDRL};
      bins mode            = {`REG_MODE};
      bins scl_timeout[3]  = {[`REG_SCL_TIMEOUT2 : `REG_SCL_TIMEOUT0]};
      bins sda_timeout[3]  = {[`REG_SDA_TIMEOUT2 : `REG_SDA_TIMEOUT0]};
      bins tx_data         = {`REG_TX_DATA};
      bins rx_data         = {`REG_RX_DATA};
      bins irq_clear       = {`REG_IRQ_CLEAR};
      bins reserved_space  = {5'h0C, 5'h0D, 5'h0E, 5'h0F};
      bins rx_fifo         = {`REG_RX_FIFO};
      bins tx_count[2]     = {`REG_TX_COUNT_HIGH, `REG_TX_COUNT_LOW};
      bins rx_count[2]     = {`REG_RX_COUNT_HIGH, `REG_RX_COUNT_LOW};
      bins irq_status      = {`REG_IRQ_STATUS};
      bins illegal_high    = {[5'h16 : 5'h1F]};
    }

    cp_pwrite: coverpoint sampled_apb.pwrite {
      bins read  = {1'b0};
      bins write = {1'b1};
    }

    cx_addr_pwrite: cross cp_paddr, cp_pwrite;
  endgroup

  covergroup cg_i2c;
    cp_op: coverpoint sampled_i2c.op {
      bins write_trans = {I2C_WRITE};
      bins read_trans  = {I2C_READ};
    }

    cp_is_10bit: coverpoint sampled_i2c.is_10bit {
      bins mode_7bit  = {1'b0};
      bins mode_10bit = {1'b1};
    }

    cp_ack_status: coverpoint sampled_i2c.ack_status {
      bins ack  = {I2C_ACK};
      bins nack = {I2C_NACK};
    }

    cp_burst_size: coverpoint sampled_i2c.data_q.size() {
      bins single_byte = {1};
      bins short_burst = {[2:4]};
      bins long_burst  = {[5:16]};
    }

    cp_repeated_start: coverpoint sampled_i2c.repeated_start {
      bins regular_start = {1'b0};
      bins rep_start     = {1'b1};
    }

    cx_op_ack: cross cp_op, cp_ack_status;
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

`endif 

