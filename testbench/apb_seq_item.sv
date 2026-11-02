`ifndef APB_SEQ_ITEM_SV
`define APB_SEQ_ITEM_SV

class apb_seq_item extends uvm_sequence_item;

  rand bit [`ADDR_WIDTH-1:0] paddr;
  rand bit [`DATA_WIDTH-1:0] pwdata;
  rand bit                   pwrite; 
  logic [`DATA_WIDTH-1:0]    prdata;
  logic                      pslverr;

  `uvm_object_utils_begin(apb_seq_item)
    `uvm_field_int(paddr,   UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(pwdata,  UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(pwrite,  UVM_ALL_ON | UVM_BIN)
    `uvm_field_int(prdata,  UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(pslverr, UVM_ALL_ON | UVM_BIN)
  `uvm_object_utils_end

  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction


endclass

`endif 

