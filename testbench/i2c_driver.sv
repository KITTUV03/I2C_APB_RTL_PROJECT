`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

// ============================================================================
// I2C Reactive Slave Driver (EEPROM Memory Model)
// - Responds to Master transfers on the I2C bus
// - Address matching & data handling are virtual methods for Factory Overriding
// ============================================================================
class i2c_driver extends uvm_driver #(i2c_seq_item);

  `uvm_component_utils(i2c_driver)

  virtual i2c_if vif;

  // Slave address (default 7'h50)
  logic [6:0] slave_addr = 7'h50;

  // Slave internal memory array
  logic [7:0] memory [0:255];
  int         mem_ptr = 0;

  function new(string name = "i2c_driver", uvm_component parent = null);
    super.new(name, parent);
    // Initialize default memory content
    for (int i = 0; i < 256; i++) begin
      memory[i] = 8'h00;
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

  // Detect START condition: SDA falling while SCL is HIGH
  virtual task wait_for_start();
    while (1) begin
      @(negedge vif.sda);
      if (vif.scl === 1'b1) begin
        `uvm_info("I2C_DRV", "START condition detected on bus", UVM_HIGH)
        break;
      end
    end
  endtask

  // Handle a complete I2C transaction
  virtual task handle_transaction();
    logic [7:0] header;
    logic [6:0] addr;
    bit         rw;

    // Reset memory pointer at start of each transaction
    // This ensures read-after-write reads starting from address 0
    mem_ptr = 0;

    // Read 8-bit address header from master
    read_byte(header);
    addr = header[7:1];
    rw   = header[0];

    // Check if address matches our slave address (virtual for factory override)
    if (is_addr_match(addr)) begin
      `uvm_info("I2C_DRV", $sformatf("Address MATCH (0x%02h, RW=%0d). Sending ACK.", addr, rw), UVM_MEDIUM)
      send_ack();
    end else begin
      `uvm_info("I2C_DRV", $sformatf("Address MISMATCH (0x%02h). Sending NACK.", addr), UVM_MEDIUM)
      send_nack();
      return; // End transaction on mismatch
    end

    // Data Phase
    if (rw == 1'b0) begin
      handle_slave_rx(); // Master Write (Slave receives data)
    end else begin
      handle_slave_tx(); // Master Read (Slave transmits data)
    end
  endtask

  // Slave Receive: Receives bytes from Master and writes into internal memory
  virtual task handle_slave_rx();
    logic [7:0] rx_byte;
    bit         stop_detected;

    forever begin
      read_byte_or_stop(rx_byte, stop_detected);
      if (stop_detected) begin
        `uvm_info("I2C_DRV", "STOP condition detected. Slave write complete.", UVM_HIGH)
        break;
      end

      // Store byte in memory
      memory[mem_ptr] = rx_byte;
      `uvm_info("I2C_DRV", $sformatf("Slave stored byte 0x%02h at mem[%0d]", rx_byte, mem_ptr), UVM_MEDIUM)
      mem_ptr = (mem_ptr + 1) % 256;

      // Acknowledge the received data byte
      send_ack();
    end
  endtask

  // Slave Transmit: Transmits bytes from internal memory to Master
  virtual task handle_slave_tx();
    logic [7:0] tx_byte;
    bit         master_nack;

    forever begin
      tx_byte = get_memory_data(mem_ptr);
      `uvm_info("I2C_DRV", $sformatf("Slave sending byte 0x%02h from mem[%0d]", tx_byte, mem_ptr), UVM_MEDIUM)
      mem_ptr = (mem_ptr + 1) % 256;

      // Transmit 8 bits to master
      write_byte(tx_byte);

      // Sample Master's ACK/NACK on 9th clock (Spec 6.5: Master NACKs on last byte)
      sample_master_ack(master_nack);
      if (master_nack) begin
        `uvm_info("I2C_DRV", "Master NACKed - Slave read transfer complete", UVM_MEDIUM)
        break;
      end
    end
  endtask

  // ==========================================================================
  // Virtual Helper Methods (Can be overridden via UVM Factory)
  // ==========================================================================
  virtual function bit is_addr_match(bit [6:0] addr);
    return (addr == slave_addr);
  endfunction

  virtual function logic [7:0] get_memory_data(int ptr);
    return memory[ptr];
  endfunction

  // Read 1 byte from Master on SDA
  virtual task read_byte(output logic [7:0] data);
    for (int i = 7; i >= 0; i--) begin
      @(posedge vif.scl);
      data[i] = vif.sda;
      @(negedge vif.scl);
    end
  endtask

  // Read 1 byte or exit if STOP condition occurs
  virtual task read_byte_or_stop(output logic [7:0] data, output bit stop_detected);
    stop_detected = 1'b0;
    for (int i = 7; i >= 0; i--) begin
      fork
        begin : wait_clk
          @(posedge vif.scl);
        end
        begin : wait_stop
          while (1) begin
            @(posedge vif.sda);
            if (vif.scl === 1'b1) begin
              stop_detected = 1'b1;
              break;
            end
          end
        end
      join_any
      disable fork;

      if (stop_detected) return;

      data[i] = vif.sda;
      @(negedge vif.scl);
    end
  endtask

  // Transmit 1 byte to Master MSB first
  virtual task write_byte(input logic [7:0] data);
    for (int i = 7; i >= 0; i--) begin
      if (data[i] == 1'b0)
        vif.sda_drive_low <= 1'b1;
      else
        vif.sda_drive_low <= 1'b0;

      @(posedge vif.scl);
      @(negedge vif.scl);
    end
    vif.sda_drive_low <= 1'b0; // Release SDA for ACK phase
  endtask

  // Drive ACK (pull SDA low during 9th clock)
  virtual task send_ack();
    vif.sda_drive_low <= 1'b1;
    @(posedge vif.scl);
    @(negedge vif.scl);
    vif.sda_drive_low <= 1'b0; // Release SDA
  endtask

  // Send NACK (leave SDA high during 9th clock)
  virtual task send_nack();
    vif.sda_drive_low <= 1'b0;
    @(posedge vif.scl);
    @(negedge vif.scl);
  endtask

  // Sample Master's ACK/NACK (9th clock of read)
  virtual task sample_master_ack(output bit nack);
    vif.sda_drive_low <= 1'b0; // Ensure SDA is released
    @(posedge vif.scl);
    nack = (vif.sda === 1'b1); // 1 = NACK, 0 = ACK
    @(negedge vif.scl);
  endtask

endclass

`endif // I2C_DRIVER_SV
