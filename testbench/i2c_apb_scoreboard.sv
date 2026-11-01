`ifndef I2C_APB_SCOREBOARD_SV
`define I2C_APB_SCOREBOARD_SV

// ============================================================================
// I2C APB Scoreboard: Checks write data and read data integrity
// ============================================================================
class i2c_apb_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(i2c_apb_scoreboard)

  `uvm_analysis_imp_decl(_apb)
  `uvm_analysis_imp_decl(_i2c)

  uvm_analysis_imp_apb #(apb_seq_item, i2c_apb_scoreboard) apb_export;
  uvm_analysis_imp_i2c #(i2c_seq_item, i2c_apb_scoreboard) i2c_export;

  // Expected transaction queues
  logic [7:0] expected_tx_q[$]; // Master Write: APB TX_DATA -> I2C bus
  logic [7:0] expected_rx_q[$]; // Master Read:  I2C bus data -> APB RX_FIFO

  // Statistics counters
  int tx_matches    = 0;
  int tx_mismatches = 0;
  int rx_matches    = 0;
  int rx_mismatches = 0;

  function new(string name = "i2c_apb_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    apb_export = new("apb_export", this);
    i2c_export = new("i2c_export", this);
  endfunction

  // APB Transaction Observer
  virtual function void write_apb(apb_seq_item item);
    // 1. Software writes to TX_DATA (0x09) -> Enqueue byte for I2C bus check
    if (item.pwrite && item.paddr == `REG_TX_DATA) begin
      expected_tx_q.push_back(item.pwdata);
      `uvm_info("SCB_APB", $sformatf("Queued expected TX data byte: 0x%02h", item.pwdata), UVM_HIGH)
    end

    // 2. Software reads from RX_FIFO (0x10) -> Compare against byte received on I2C bus
    if (!item.pwrite && item.paddr == `REG_RX_FIFO) begin
      if (expected_rx_q.size() > 0) begin
        logic [7:0] exp_byte = expected_rx_q.pop_front();
        if (item.prdata === exp_byte) begin
          rx_matches++;
          `uvm_info("SCB_RX", $sformatf("[PASS] RX_FIFO Read MATCH: 0x%02h", item.prdata), UVM_LOW)
        end else begin
          rx_mismatches++;
          `uvm_error("SCB_RX", $sformatf("[FAIL] RX_FIFO MISMATCH! Expected: 0x%02h, Got: 0x%02h",
                     exp_byte, item.prdata))
        end
      end
    end
  endfunction

  // I2C Bus Transaction Observer
  virtual function void write_i2c(i2c_seq_item item);
    // Case 1: Master Write Transfer (rw == 0)
    // Check that bytes transmitted on I2C bus match what was queued via APB
    if (item.rw == 1'b0) begin
      foreach (item.data_q[i]) begin
        if (expected_tx_q.size() > 0) begin
          logic [7:0] exp_byte = expected_tx_q.pop_front();
          if (item.data_q[i] === exp_byte) begin
            tx_matches++;
            `uvm_info("SCB_TX", $sformatf("[PASS] I2C Write byte MATCH: 0x%02h", item.data_q[i]), UVM_LOW)
          end else begin
            tx_mismatches++;
            `uvm_error("SCB_TX", $sformatf("[FAIL] I2C Write byte MISMATCH! Expected: 0x%02h, Observed: 0x%02h",
                       exp_byte, item.data_q[i]))
          end
        end else begin
          tx_mismatches++;
          `uvm_error("SCB_TX", $sformatf("[FAIL] Unexpected extra byte on I2C bus: 0x%02h", item.data_q[i]))
        end
      end
    end

    // Case 2: Master Read Transfer (rw == 1)
    // Enqueue bytes from I2C bus to compare against APB RX_FIFO reads
    if (item.rw == 1'b1) begin
      foreach (item.data_q[i]) begin
        expected_rx_q.push_back(item.data_q[i]);
        `uvm_info("SCB_RX", $sformatf("Queued expected byte for RX_FIFO read: 0x%02h", item.data_q[i]), UVM_HIGH)
      end
    end
  endfunction

  // Scoreboard Final Summary Report
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
    `uvm_info("SCOREBOARD", "              SCOREBOARD FINAL REPORT            ", UVM_NONE)
    `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
    `uvm_info("SCOREBOARD", $sformatf("TX Data Matches       : %0d", tx_matches), UVM_NONE)
    `uvm_info("SCOREBOARD", $sformatf("TX Data Mismatches    : %0d", tx_mismatches), UVM_NONE)
    `uvm_info("SCOREBOARD", $sformatf("RX Data Matches       : %0d", rx_matches), UVM_NONE)
    `uvm_info("SCOREBOARD", $sformatf("RX Data Mismatches    : %0d", rx_mismatches), UVM_NONE)
    `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)

    if (tx_mismatches == 0 && rx_mismatches == 0 && (tx_matches > 0 || rx_matches > 0)) begin
      `uvm_info("SCOREBOARD", "   *** ALL SCOREBOARD VERIFICATION CHECKS PASSED ***   ", UVM_NONE)
    end else begin
      `uvm_error("SCOREBOARD", "   *** FAILED: SCOREBOARD DETECTED MISMATCHES ***   ")
    end
    `uvm_info("SCOREBOARD", "==================================================", UVM_NONE)
  endfunction

endclass

`endif // I2C_APB_SCOREBOARD_SV
