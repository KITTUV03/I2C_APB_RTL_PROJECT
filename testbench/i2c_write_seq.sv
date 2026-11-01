`ifndef I2C_WRITE_SEQ_SV
`define I2C_WRITE_SEQ_SV

// ============================================================================
// I2C Master Write Sequence:
// Configures slave address and mode, then queues bytes to CMD_TX (0x09)
// Spec Section 6.10: Polls TX_COUNT_LOW (0x12) to detect completion.
// ============================================================================
class i2c_write_seq extends apb_base_seq;

  `uvm_object_utils(i2c_write_seq)

  rand bit [6:0] slave_addr;
  rand bit [7:0] data_bytes[$];

  constraint c_write_defaults {
    soft slave_addr == 7'h50;
    soft data_bytes.size() == 4;
  }

  function new(string name = "i2c_write_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [7:0] tx_cnt;

    `uvm_info("WRITE_SEQ", "Starting I2C Master Write Sequence...", UVM_LOW)

    // Step 1: Configure Slave Address (Spec 5.1 & 5.2: 7-bit address in [6:0])
    write_reg(`REG_SLV_ADDRL, {1'b0, slave_addr});

    // Step 2: Configure Mode (Spec 5.2: Standard 100 kHz, 7-bit addressing -> 3'b000)
    write_reg(`REG_MODE, 3'b000);

    // Step 3: Populate default data if empty
    if (data_bytes.size() == 0) begin
      data_bytes = '{8'h11, 8'h22, 8'h33, 8'h44};
    end

    // Step 4: Queue TX Data Bytes (pushed to Command FIFO as CMD_TX per Spec 5.3)
    foreach (data_bytes[i]) begin
      `uvm_info("WRITE_SEQ", $sformatf("Queuing TX data byte [%0d]: 0x%02h", i, data_bytes[i]), UVM_MEDIUM)
      write_reg(`REG_TX_DATA, data_bytes[i]);
    end

    // Step 5: Poll TX_COUNT_LOW (0x12) until all bytes complete (Spec 6.10)
    `uvm_info("WRITE_SEQ", $sformatf("Waiting for TX_COUNT to reach %0d...", data_bytes.size()), UVM_LOW)
    poll_reg(`REG_TX_COUNT_LOW, data_bytes.size(), 2000);

    // Read back final count
    read_reg(`REG_TX_COUNT_LOW, tx_cnt);
    `uvm_info("WRITE_SEQ", $sformatf("Write Sequence Complete! Final TX_COUNT = %0d", tx_cnt), UVM_LOW)

    // Step 6: Wait for STOP condition to settle on bus (~15us in Standard mode per Spec 6.10)
    #20us;
  endtask

endclass

`endif // I2C_WRITE_SEQ_SV
