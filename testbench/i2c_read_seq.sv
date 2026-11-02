`ifndef I2C_READ_SEQ_SV
`define I2C_READ_SEQ_SV

class i2c_read_seq extends apb_base_seq;

  `uvm_object_utils(i2c_read_seq)

  rand bit [6:0] slave_addr;
  rand int       num_bytes;

  constraint c_read_defaults {
    soft slave_addr == 7'h50;
    soft num_bytes  == 4;
  }

  function new(string name = "i2c_read_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [7:0] rx_cnt;
    bit [7:0] rx_val;

    `uvm_info("READ_SEQ", "Starting I2C Master Read Sequence...", UVM_LOW)

    write_reg(`REG_SLV_ADDRL, {1'b0, slave_addr});

    write_reg(`REG_MODE, 3'b000);

    for (int i = 0; i < num_bytes; i++) begin
      `uvm_info("READ_SEQ", $sformatf("Queuing CMD_RX request [%0d/%0d]", i+1, num_bytes), UVM_MEDIUM)
      write_reg(`REG_RX_DATA, 8'h00);
    end

    `uvm_info("READ_SEQ", $sformatf("Waiting for RX_COUNT to reach %0d...", num_bytes), UVM_LOW)
    poll_reg(`REG_RX_COUNT_LOW, num_bytes, 2000);

    read_reg(`REG_RX_COUNT_LOW, rx_cnt);
    `uvm_info("READ_SEQ", $sformatf("RX_COUNT reached %0d! Now draining RX_FIFO...", rx_cnt), UVM_LOW)

    for (int i = 0; i < num_bytes; i++) begin
      read_reg(`REG_RX_FIFO, rx_val);
      `uvm_info("READ_SEQ", $sformatf("Popped byte [%0d] from RX_FIFO = 0x%02h", i, rx_val), UVM_LOW)
    end

    #20us;
  endtask

endclass

`endif 

