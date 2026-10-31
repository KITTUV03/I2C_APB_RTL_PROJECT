`ifndef I2C_WRITE_SEQ_SV
`define I2C_WRITE_SEQ_SV

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

    // Configure Slave Address (7-bit address in [6:0])
    write_reg(`REG_SLV_ADDRL, {1'b0, slave_addr});

    // Configure Mode (Standard 100 kHz, 7-bit mode -> 3'b000)
    write_reg(`REG_MODE, 3'b000);

    // Queue TX Data Bytes (Pushed to Command FIFO as CMD_TX)
    if (data_bytes.size() == 0) begin
      data_bytes = '{8'h11, 8'h22, 8'h33, 8'h44};
    end

    foreach (data_bytes[i]) begin
      `uvm_info("WRITE_SEQ", $sformatf("Queuing TX data byte [%0d]: 0x%02h", i, data_bytes[i]), UVM_MEDIUM)
      write_reg(`REG_TX_DATA, data_bytes[i]);
    end

    // Poll TX_COUNT_LOW (offset 0x12) until all bytes have completed
    `uvm_info("WRITE_SEQ", $sformatf("Waiting for TX_COUNT to reach %0d...", data_bytes.size()), UVM_LOW)
    poll_reg(`REG_TX_COUNT_LOW, data_bytes.size(), 2000);

    // Read back final status
    read_reg(`REG_TX_COUNT_LOW, tx_cnt);
    `uvm_info("WRITE_SEQ", $sformatf("I2C Write Sequence Complete! Final TX_COUNT = %0d", tx_cnt), UVM_LOW)

    // Allow time for STOP condition to settle on bus (as per spec Section 6.10: ~15us in Standard mode)
    #20us;
  endtask

endclass

`endif // I2C_WRITE_SEQ_SV

