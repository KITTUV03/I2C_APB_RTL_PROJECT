`ifndef I2C_APB_SCOREBOARD_SV
`define I2C_APB_SCOREBOARD_SV

class i2c_apb_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(i2c_apb_scoreboard)

  `uvm_analysis_imp_decl(_apb)
  `uvm_analysis_imp_decl(_i2c)

  uvm_analysis_imp_apb #(apb_seq_item, i2c_apb_scoreboard) apb_export;
  uvm_analysis_imp_i2c #(i2c_seq_item, i2c_apb_scoreboard) i2c_export;

  logic [7:0] expected_tx_q[$];
  logic [7:0] expected_rx_q[$];

  logic [6:0] configured_slv_addrl = 7'h00;
  logic [1:0] configured_slv_addrh = 2'h0;
  logic [2:0] configured_mode      = 3'h0;

  int unsigned tx_matches    = 0;
  int unsigned tx_mismatches = 0;
  int unsigned rx_matches    = 0;
  int unsigned rx_mismatches = 0;
  int unsigned total_checks  = 0;

  function new(string name = "i2c_apb_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    apb_export = new("apb_export", this);
    i2c_export = new("i2c_export", this);
  endfunction

  virtual function void write_apb(apb_seq_item item);
    if (item.pwrite) begin
      case (item.paddr)
        `REG_SLV_ADDRL: configured_slv_addrl = item.pwdata[6:0];
        `REG_SLV_ADDRH: configured_slv_addrh = item.pwdata[1:0];
        `REG_MODE:      configured_mode      = item.pwdata[2:0];
        `REG_TX_DATA: begin
          expected_tx_q.push_back(item.pwdata);
          `uvm_info("SCB_APB", $sformatf("Queued expected TX data byte: 0x%02h", item.pwdata), UVM_HIGH)
        end
        default: ;
      endcase
    end else begin

      // APB Read from RX_FIFO (0x10)
      if (item.paddr == `REG_RX_FIFO) begin
        if (expected_rx_q.size() > 0) begin
          logic [7:0] exp_byte = expected_rx_q.pop_front();
          total_checks++;
          if (item.prdata === exp_byte) begin
            rx_matches++;
            `uvm_info("SCB_RX", $sformatf("[PASS] RX_FIFO Read MATCH: 0x%02h", item.prdata), UVM_LOW)
          end else begin
            rx_mismatches++;
            `uvm_error("SCB_RX", $sformatf("[FAIL] RX_FIFO MISMATCH! Expected: 0x%02h, Got: 0x%02h", exp_byte, item.prdata))
          end
        end else begin
          `uvm_info("SCB_RX", $sformatf("RX_FIFO Read 0x%02h while queue empty", item.prdata), UVM_HIGH)
        end
      end
    end
  endfunction

  // I2C Bus Transaction Handler
  virtual function void write_i2c(i2c_seq_item item);
    if (item.op == I2C_WRITE) begin
      // Master Write: verify data payload transmitted on I2C bus matches what APB queued
      foreach (item.data_q[i]) begin
        total_checks++;
        if (expected_tx_q.size() > 0) begin
          logic [7:0] exp_byte = expected_tx_q.pop_front();
          if (item.data_q[i] === exp_byte) begin
            tx_matches++;
            `uvm_info("SCB_TX", $sformatf("[PASS] I2C Write byte MATCH: 0x%02h", item.data_q[i]), UVM_LOW)
          end else begin
            tx_mismatches++;
            `uvm_error("SCB_TX", $sformatf("[FAIL] I2C Write byte MISMATCH! Expected: 0x%02h, Observed on bus: 0x%02h",
                      exp_byte, item.data_q[i]))
          end
        end else begin
          tx_mismatches++;
          `uvm_error("SCB_TX", $sformatf("[FAIL] Unexpected extra byte on I2C bus: 0x%02h", item.data_q[i]))
        end
      end
    end else begin
      // Master Read: store data bytes received from slave on I2C bus to expect in APB RX_FIFO reads
      foreach (item.data_q[i]) begin
        expected_rx_q.push_back(item.data_q[i]);
        `uvm_info("SCB_RX", $sformatf("Enqueued expected byte for RX_FIFO read: 0x%02h", item.data_q[i]), UVM_HIGH)
      end
    end
  endfunction

  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
    `uvm_info("SCOREBOARD", "              SCOREBOARD FINAL REPORT            ", UVM_NONE)
    `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
    `uvm_info("SCOREBOARD", $sformatf("Total Protocol Checks : %0d", total_checks), UVM_NONE)
    `uvm_info("SCOREBOARD", $sformatf("TX Data Matches       : %0d", tx_matches), UVM_NONE)
    `uvm_info("SCOREBOARD", $sformatf("TX Data Mismatches    : %0d", tx_mismatches), UVM_NONE)
    `uvm_info("SCOREBOARD", $sformatf("RX Data Matches       : %0d", rx_matches), UVM_NONE)
    `uvm_info("SCOREBOARD", $sformatf("RX Data Mismatches    : %0d", rx_mismatches), UVM_NONE)
    `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)

    if (tx_mismatches == 0 && rx_mismatches == 0 && total_checks > 0) begin
      `uvm_info("SCOREBOARD", "   *** ALL SCOREBOARD VERIFICATION CHECKS PASSED ***   ", UVM_NONE)
    end else if (total_checks == 0) begin
      `uvm_warning("SCOREBOARD", "   *** WARNING: NO DATA TRANSFERS CHECKED ***   ")
    end else begin
      `uvm_error("SCOREBOARD", "   *** FAILED: SCOREBOARD DETECTED MISMATCHES ***   ")
    end
    `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
  endfunction

endclass

`endif 

