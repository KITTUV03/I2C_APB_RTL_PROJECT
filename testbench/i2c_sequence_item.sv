`ifndef I2C_SEQUENCE_ITEM_SV
`define I2C_SEQUENCE_ITEM_SV

// ============================================================================
// I2C Sequence Item: Simple transaction model for I2C bus activity
// ============================================================================
class i2c_seq_item extends uvm_sequence_item;

  rand bit [6:0]      addr;        // 7-bit slave address
  rand bit            rw;          // 0 = Write (Master -> Slave), 1 = Read (Slave -> Master)
  rand bit [7:0]      data_q[$];   // Data bytes payload
  rand bit            ack;         // 0 = ACK, 1 = NACK

  `uvm_object_utils_begin(i2c_seq_item)
    `uvm_field_int       (addr,   UVM_ALL_ON | UVM_HEX)
    `uvm_field_int       (rw,     UVM_ALL_ON | UVM_BIN)
    `uvm_field_queue_int (data_q, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int       (ack,    UVM_ALL_ON | UVM_BIN)
  `uvm_object_utils_end

  function new(string name = "i2c_seq_item");
    super.new(name);
    ack = 1'b0; // Default: ACK
  endfunction

  virtual function string convert2string();
    return $sformatf("I2C_ITEM: ADDR=0x%02h, %s, BYTES=%0d, ACK=%0b",
                     addr, (rw ? "READ" : "WRITE"), data_q.size(), ack);
  endfunction

endclass

// Typedef for legacy/alternative naming
typedef i2c_seq_item i2c_sequence_item;

`endif // I2C_SEQUENCE_ITEM_SV
