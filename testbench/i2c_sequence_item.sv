`ifndef I2C_SEQUENCE_ITEM_SV
`define I2C_SEQUENCE_ITEM_SV

typedef enum bit {
  I2C_WRITE = 1'b0,
  I2C_READ  = 1'b1
} i2c_op_e;

typedef enum bit {
  I2C_ACK  = 1'b0,
  I2C_NACK = 1'b1
} i2c_ack_e;

typedef enum bit [1:0] {
  I2C_CMD_NORMAL    = 2'b00,
  I2C_CMD_START     = 2'b01,
  I2C_CMD_REP_START = 2'b10,
  I2C_CMD_STOP      = 2'b11
} i2c_cmd_type_e;

class i2c_seq_item extends uvm_sequence_item;

  // Transaction Fields
  rand logic [9:0]        addr;           // 7-bit [6:0] or 10-bit [9:0]
  rand bit                is_10bit;       // 0: 7-bit addressing, 1: 10-bit addressing
  rand i2c_op_e           op;             // I2C_WRITE or I2C_READ
  rand logic [7:0]        data_q[$];      // Queue of payload bytes
  rand i2c_ack_e          ack_status;     // Overall or address ACK/NACK status
  rand i2c_cmd_type_e     cmd_type;       // Normal / Start / Repeated Start / Stop

  // Reactive Slave & Error Injection Controls
  rand int unsigned       stretch_cycles; // SCL clock stretch cycles (0 = no stretch)
  rand bit                inject_nack;    // 1: Force a NACK
  rand int                nack_at_byte;   // -1: None, 0: Addr phase, 1..N: Data byte index

  // Monitor Feedback Fields
  bit                     repeated_start; // Set by monitor if preceded by Sr
  bit                     stop_detected;  // Set by monitor if followed by P
  i2c_ack_e               data_ack_q[$];  // ACK/NACK observed for each data byte

  `uvm_object_utils_begin(i2c_seq_item)
    `uvm_field_int       (addr,           UVM_ALL_ON)
    `uvm_field_int       (is_10bit,        UVM_ALL_ON)
    `uvm_field_enum      (i2c_op_e, op,    UVM_ALL_ON)
    `uvm_field_queue_int (data_q,          UVM_ALL_ON)
    `uvm_field_enum      (i2c_ack_e, ack_status, UVM_ALL_ON)
    `uvm_field_enum      (i2c_cmd_type_e, cmd_type, UVM_ALL_ON)
    `uvm_field_int       (stretch_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int       (inject_nack,    UVM_ALL_ON)
    `uvm_field_int       (nack_at_byte,   UVM_ALL_ON | UVM_DEC)
    `uvm_field_int       (repeated_start, UVM_ALL_ON)
    `uvm_field_int       (stop_detected,  UVM_ALL_ON)
  `uvm_object_utils_end

  // Constructor
  function new(string name = "i2c_seq_item");
    super.new(name);
    stretch_cycles = 0;
    inject_nack    = 0;
    nack_at_byte   = -1;
    ack_status     = I2C_ACK;
    cmd_type       = I2C_CMD_NORMAL;
    repeated_start = 0;
    stop_detected  = 1;
  endfunction

  constraint c_default_i2c {
    // 7-bit vs 10-bit address range
    if (!is_10bit) {
      addr[9:7] == 3'b000;
      addr[6:0] inside {[7'h08 : 7'h77]}; // Valid standard 7-bit slave addresses
    } else {
      addr inside {[10'h001 : 10'h3FF]};  // Full 10-bit address range
    }

    data_q.size() inside {[1 : 16]};

    soft inject_nack    == 0;
    soft nack_at_byte   == -1;
    soft stretch_cycles == 0;
    soft ack_status     == I2C_ACK;
    soft cmd_type       == I2C_CMD_NORMAL;
  }

endclass

typedef i2c_seq_item i2c_sequence_item;

`endif 
