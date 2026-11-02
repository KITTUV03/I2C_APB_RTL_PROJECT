`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

class apb_driver extends uvm_driver #(apb_seq_item);

  `uvm_component_utils(apb_driver)

  virtual apb_if vif;

  function new(string name = "apb_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif)) begin
      `uvm_fatal("APB_DRV", "Could not get virtual interface 'apb_vif' from config_db")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    reset_signals();

    while(!`RESET_DEASSERT)
    //wait (vif.PRESETn === `RESET_DEASSERT);
    @(posedge vif.PCLK);

    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task reset_signals();
    vif.PSEL    <= 1'b0;
    vif.PENABLE <= 1'b0;
    vif.PWRITE  <= 1'b0;
    vif.PADDR   <= '0;
    vif.PWDATA  <= '0;
  endtask

  virtual task drive_transfer(apb_seq_item item);
    // SETUP Cycle
    @(posedge vif.PCLK);
    vif.PSEL    <= 1'b1;
    vif.PENABLE <= 1'b0;
    vif.PADDR   <= item.paddr;
    vif.PWRITE  <= item.pwrite;
    if (item.pwrite)
      vif.PWDATA <= item.pwdata;
    else
      vif.PWDATA <= '0;

    // ACCESS Cycle
    @(posedge vif.PCLK);
    vif.PENABLE <= 1'b1;

    // Wait until PREADY is high
    while (!vif.PREADY) begin
      @(posedge vif.PCLK);
    end

    if (!item.pwrite) begin
      item.prdata = vif.PRDATA;
    end
    item.pslverr = vif.PSLVERR;

    @(posedge vif.PCLK);
    vif.PSEL    <= 1'b0;
    vif.PENABLE <= 1'b0;
  endtask

endclass

`endif 

