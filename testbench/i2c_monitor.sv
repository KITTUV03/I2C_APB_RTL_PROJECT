`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

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

      // Sample Address Byte
      sample_byte(header_byte, ack_bit);
      item.addr       = header_byte[7:1];
      item.op         = header_byte[0] ? I2C_READ : I2C_WRITE;
      item.ack_status = ack_bit ? I2C_NACK : I2C_ACK;

      `uvm_info("I2C_MON", $sformatf("Observed Address Phase: ADDR=0x%02h, OP=%s, ACK=%s",
                item.addr, item.op.name(), item.ack_status.name()), UVM_MEDIUM)

      // If Address was NACKed, transaction ends
      if (item.ack_status == I2C_NACK) begin
        item.stop_detected = 1'b1;
        item_collected_port.write(item);
        continue;
      end

      // Sample Data Bytes until STOP or Repeated START
      fork
        begin 
          forever begin
            sample_byte(data_byte, ack_bit);
            item.data_q.push_back(data_byte);
            item.data_ack_q.push_back(ack_bit ? I2C_NACK : I2C_ACK);
            `uvm_info("I2C_MON", $sformatf("Observed Data Byte: 0x%02h, ACK=%s",
                      data_byte, (ack_bit ? "NACK" : "ACK")), UVM_HIGH)
          end
        end
        begin 
          while (1) begin
            @(posedge vif.sda);
            if (vif.scl === 1'b1) begin
              `uvm_info("I2C_MON", "STOP condition observed on bus", UVM_MEDIUM)
              item.stop_detected = 1'b1;
              break;
            end
          end
        end
        begin 
          while (1) begin
            @(negedge vif.sda);
            if (vif.scl === 1'b1) begin
              `uvm_info("I2C_MON", "Repeated START observed on bus", UVM_MEDIUM)
              item.repeated_start = 1'b1;
              break;
            end
          end
        end
      join_any
      disable fork;

      item_collected_port.write(item);
    end
  endtask

  virtual task wait_for_start();
    while (1) begin
      @(negedge vif.sda);
      if (vif.scl === 1'b1)
        break;
    end
  endtask

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

`endif 

