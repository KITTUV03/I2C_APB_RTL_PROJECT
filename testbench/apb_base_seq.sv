`ifndef APB_BASE_SEQ_SV
`define APB_BASE_SEQ_SV

class apb_base_seq extends uvm_sequence #(apb_seq_item);

  `uvm_object_utils(apb_base_seq)

  function new(string name = "apb_base_seq");
    super.new(name);
  endfunction

  virtual task write_reg(bit [`ADDR_WIDTH-1:0] addr, bit [`DATA_WIDTH-1:0] data);
    req = apb_seq_item::type_id::create("apb_write_item");
    start_item(req);
    req.paddr  = addr;
    req.pwdata = data;
    req.pwrite = 1'b1;
    finish_item(req);
  endtask

  virtual task read_reg(bit [`ADDR_WIDTH-1:0] addr, output bit [`DATA_WIDTH-1:0] data);
    req = apb_seq_item::type_id::create("apb_read_item");
    start_item(req);
    req.paddr  = addr;
    req.pwrite = 1'b0;
    finish_item(req);
    data = req.prdata;
  endtask

  virtual task poll_reg(bit [`ADDR_WIDTH-1:0] addr, bit [`DATA_WIDTH-1:0] expected_val, int max_polls = 500);
    bit [`DATA_WIDTH-1:0] val;
    int count = 0;
    while (count < max_polls) begin
      read_reg(addr, val);
      if (val === expected_val) break;
      #1us;
      count++;
    end
    if (count == max_polls) begin
      `uvm_warning("POLL_TIMEOUT", $sformatf("Polling addr 0x%02h timed out! Last value=0x%02h, Expected=0x%02h",
                   addr, val, expected_val))
    end
  endtask

endclass

`endif 

