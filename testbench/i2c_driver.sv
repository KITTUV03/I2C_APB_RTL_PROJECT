`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

class i2c_driver extends uvm_driver #(i2c_seq_item);

  `uvm_component_utils(i2c_driver)

  virtual i2c_if vif;

  // Configurable Slave Address 
  logic [6:0] slave_addr_7bit = 7'h50;
  logic [9:0] slave_addr_10bit = 10'h150;

  // Internal Slave Memory Model 
  logic [7:0] memory[int];
  int         current_mem_ptr = 0;

  // Error Injection / Clock Stretch Knobs
  int unsigned stretch_ns = 0;
  bit          force_addr_nack = 1'b0;
  bit          force_data_nack = 1'b0;

  function new(string name = "i2c_driver", uvm_component parent = null);
    super.new(name, parent);
    // Initialize default memory content
    for (int i = 0; i < 256; i++) begin
      memory[i] = 8'hA0 + i;
    end
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i2c_vif", vif)) begin
      `uvm_fatal("I2C_DRV", "Could not get virtual interface 'i2c_vif' from config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.scl_drive_low <= 1'b0;
    vif.sda_drive_low <= 1'b0;

    forever begin
      wait_for_start();
      handle_transaction();
    end
  endtask

  // Detect START or Repeated START condition: SDA falling while SCL is high
  virtual task wait_for_start();
    while (1) begin
      @(negedge vif.sda);
      if (vif.scl === 1'b1) begin
        `uvm_info("I2C_DRV", "START / Repeated START detected on bus", UVM_HIGH)
        break;
      end
    end
  endtask

  // Handle Complete I2C Transaction
  virtual task handle_transaction();
    logic [7:0] raw_header;
    bit         rw_bit;
    bit [6:0]   sampled_addr;
    bit         ack_sent;

    // Read first 8 bits (Address + R/W bit)
    read_byte_from_bus(raw_header);
    rw_bit       = raw_header[0];
    sampled_addr = raw_header[7:1];

    // Check if address matches
    if (should_ack_address(sampled_addr, 1'b0) && !force_addr_nack) begin
      `uvm_info("I2C_DRV", $sformatf("Address MATCH (0x%02h, RW=%0b). Sending ACK.", sampled_addr, rw_bit), UVM_MEDIUM)
      send_ack();
      ack_sent = 1'b1;
    end else begin
      `uvm_info("I2C_DRV", $sformatf("Address MISMATCH / NACK (0x%02h). Sending NACK.", sampled_addr), UVM_MEDIUM)
      send_nack();
      ack_sent = 1'b0;
      return; // End transaction on address NACK
    end

    // Data Phase
    if (rw_bit == 1'b0) begin
      handle_slave_rx();
    end else begin
      handle_slave_tx();
    end
  endtask

  // Virtual methods for Factory Overriding
  virtual function bit should_ack_address(bit [9:0] addr, bit is_10bit);
    if (!is_10bit)
      return (addr[6:0] == slave_addr_7bit);
    else
      return (addr == slave_addr_10bit);
  endfunction

  virtual function logic [7:0] get_read_data(int ptr);
    if (memory.exists(ptr))
      return memory[ptr];
    else
      return 8'h00;
  endfunction

  virtual task optional_clock_stretch();
    if (stretch_ns > 0) begin
      vif.scl_drive_low <= 1'b1;
      #(stretch_ns);
      vif.scl_drive_low <= 1'b0;
    end
  endtask

  // Read 1 byte from Master on SDA
  virtual task read_byte_from_bus(output logic [7:0] data_byte);
    for (int i = 7; i >= 0; i--) begin
      @(posedge vif.scl);
      data_byte[i] = vif.sda;
      @(negedge vif.scl);
    end
  endtask

  // Drive ACK (pull SDA low on 9th clock)
  virtual task send_ack();
    // After 8th bit fall, pull SDA low before SCL rises
    vif.sda_drive_low <= 1'b1;
    optional_clock_stretch();
    @(posedge vif.scl);
    @(negedge vif.scl);
    vif.sda_drive_low <= 1'b0; // Release SDA
  endtask

  //Send NACK (leave SDA high on 9th clock)
  virtual task send_nack();
    vif.sda_drive_low <= 1'b0;
    optional_clock_stretch();
    @(posedge vif.scl);
    @(negedge vif.scl);
  endtask

  // Slave Receive 
  virtual task handle_slave_rx();
    logic [7:0] rx_byte;
    fork
      begin : rx_loop
        forever begin
          read_byte_from_bus(rx_byte);
          memory[current_mem_ptr] = rx_byte;
          `uvm_info("I2C_DRV", $sformatf("Slave stored byte 0x%02h at mem[0x%02h]", rx_byte, current_mem_ptr), UVM_HIGH)
          current_mem_ptr++;

          if (!force_data_nack)
            send_ack();
          else
            send_nack();
        end
      end
      begin : detect_end
        while (1) begin
          @(vif.sda);
          if (vif.scl === 1'b1) begin
            `uvm_info("I2C_DRV", "STOP or Repeated START condition detected during Slave RX", UVM_HIGH)
            break;
          end
        end
      end
    join_any
    disable fork;
  endtask

  virtual task handle_slave_tx();
    logic [7:0] tx_byte;
    bit         master_nack;

    while (1) begin
      tx_byte = get_read_data(current_mem_ptr);
      `uvm_info("I2C_DRV", $sformatf("Slave driving byte 0x%02h from mem[0x%02h]", tx_byte, current_mem_ptr), UVM_HIGH)
      current_mem_ptr++;

      for (int i = 7; i >= 0; i--) begin
        if (tx_byte[i] == 1'b0)
          vif.sda_drive_low <= 1'b1;
        else
          vif.sda_drive_low <= 1'b0;

        @(posedge vif.scl);
        @(negedge vif.scl);
      end

      // Release SDA for Master's ACK/NACK (9th clock)
      vif.sda_drive_low <= 1'b0;
      @(posedge vif.scl);
      master_nack = (vif.sda === 1'b1);
      @(negedge vif.scl);

      if (master_nack) begin
        `uvm_info("I2C_DRV", "Master NACKed - ending Slave TX", UVM_MEDIUM)
        break; 
      end
    end
  endtask

endclass

`endif 
