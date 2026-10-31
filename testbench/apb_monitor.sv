`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor extends uvm_monitor;

  `uvm_component_utils(apb_monitor)

  virtual apb_if vif;
  uvm_analysis_port #(apb_seq_item) item_collected_port;

  function new(string name = "apb_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif)) begin
      `uvm_fatal("APB_MON", "Could not get virtual interface 'apb_vif' from config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    apb_seq_item item;

    wait (vif.PRESETn === `RESET_DEASSERT);

    forever begin
      @(posedge vif.PCLK);
      
      if (vif.PRESETn === `RESET_DEASSERT && vif.PSEL && vif.PENABLE && vif.PREADY) begin
        item = apb_seq_item::type_id::create("monitored_apb_item");
        item.paddr   = vif.PADDR;
        item.pwrite  = vif.PWRITE;
        item.pslverr = vif.PSLVERR;
        if (vif.PWRITE)
          item.pwdata = vif.PWDATA;
        else
          item.prdata = vif.PRDATA;

        item_collected_port.write(item);
      end
    end
  endtask

endclass

`endif 

