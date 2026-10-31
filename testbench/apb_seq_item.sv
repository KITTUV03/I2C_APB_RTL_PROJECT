`ifndef APB_SEQ_ITEM_SV
`define APB_SEQ_ITEM_SV

class apb_seq_item extends uvm_sequence_item;

  rand bit [`ADDR_WIDTH-1:0] paddr;
  rand bit [`DATA_WIDTH-1:0] pwdata;
  rand bit                   pwrite; // 1 = Write, 0 = Read
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

  virtual function string convert2string();
    return $sformatf("APB_ITEM: %s ADDR=0x%02h, %s=0x%02h, PSLVERR=%0b",
                     (pwrite ? "WRITE" : "READ"),
                     paddr,
                     (pwrite ? "WDATA" : "RDATA"),
                     (pwrite ? pwdata : prdata),
                     pslverr);
  endfunction

endclass

`endif 

