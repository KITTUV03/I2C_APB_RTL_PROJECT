`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

// ============================================================================
// I2C Monitor: Observes transactions on the I2C bus (START, ADDR, DATA, STOP)
// ============================================================================
class i2c_monitor extends uvm_monitor;

  `uvm_component_utils(i2c_monitor)

  virtual i2c_if vif;
  uvm_analysis_port #(i2c_seq_item) item_collected_port;

  function new(string name = "i2c_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i2c_vif", vif)) begin
      `uvm_fatal("I2C_MON", "Could not get virtual interface 'i2c_vif' from config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    i2c_seq_item item;
    logic [7:0]  header_byte;
    logic [7:0]  data_byte;
    bit          ack_bit;

    forever begin
      wait_for_start();

      item = i2c_seq_item::type_id::create("monitored_i2c_item");

      // Sample Address Byte (7-bit address + 1-bit R/W) + 9th clock ACK
      sample_byte(header_byte, ack_bit);
      item.addr = header_byte[7:1];
      item.rw   = header_byte[0];
      item.ack  = ack_bit;

      `uvm_info("I2C_MON", $sformatf("Observed Address Phase: ADDR=0x%02h, %s, ACK=%0b",
                item.addr, (item.rw ? "READ" : "WRITE"), item.ack), UVM_MEDIUM)

      // If address was NACKed, transaction ends
      if (item.ack == 1'b1) begin
        item_collected_port.write(item);
        continue;
      end

      // Sample Data Bytes until STOP or Repeated START
      fork
        begin : data_loop
          forever begin
            sample_byte(data_byte, ack_bit);
            item.data_q.push_back(data_byte);
            `uvm_info("I2C_MON", $sformatf("Observed Data Byte: 0x%02h (ACK=%0b)", data_byte, ack_bit), UVM_HIGH)
          end
        end
        begin : stop_loop
          while (1) begin
            @(posedge vif.sda);
            if (vif.scl === 1'b1) begin
              `uvm_info("I2C_MON", "STOP condition observed on bus", UVM_MEDIUM)
              break;
            end
          end
        end
        begin : rep_start_loop
          while (1) begin
            @(negedge vif.sda);
            if (vif.scl === 1'b1) begin
              `uvm_info("I2C_MON", "Repeated START observed on bus", UVM_MEDIUM)
              break;
            end
          end
        end
      join_any
      disable fork;

      `uvm_info("I2C_MON", $sformatf("Completed Transaction: ADDR=0x%02h %s Bytes=%0d",
                item.addr, (item.rw ? "READ" : "WRITE"), item.data_q.size()), UVM_LOW)
      item_collected_port.write(item);
    end
  endtask

  // Detect START condition: SDA falling while SCL is HIGH
  virtual task wait_for_start();
    while (1) begin
      @(negedge vif.sda);
      if (vif.scl === 1'b1) break;
    end
  endtask

  // Sample 1 byte (8 bits) + 1 ACK bit (9th bit)
  virtual task sample_byte(output logic [7:0] byte_out, output bit ack_out);
    for (int i = 7; i >= 0; i--) begin
      @(posedge vif.scl);
      byte_out[i] = vif.sda;
      @(negedge vif.scl);
    end
    // Sample 9th clock (ACK bit)
    @(posedge vif.scl);
    ack_out = (vif.sda === 1'b1);
    @(negedge vif.scl);
  endtask

endclass

`endif // I2C_MONITOR_SV
