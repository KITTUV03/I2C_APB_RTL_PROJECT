`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

// ============================================================================
// APB Master Driver: Implements standard 2-phase APB4 transfers
// Spec Section 6.2: SETUP cycle followed by ACCESS cycle.
// ============================================================================
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
    // Initialize APB bus signals to idle
    vif.PSEL    <= 1'b0;
    vif.PENABLE <= 1'b0;
    vif.PADDR   <= '0;
    vif.PWRITE  <= 1'b0;
    vif.PWDATA  <= '0;

    // Wait until reset is released
    wait (vif.PRESETn === `RESET_DEASSERT);
    @(posedge vif.PCLK);

    // Main driver loop
    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask

  // Executes a single APB read or write transfer
  virtual task drive_transfer(apb_seq_item item);
    // Step 1: SETUP Cycle
    @(posedge vif.PCLK);
    vif.PSEL    <= 1'b1;
    vif.PENABLE <= 1'b0;
    vif.PADDR   <= item.paddr;
    vif.PWRITE  <= item.pwrite;
    if (item.pwrite)
      vif.PWDATA <= item.pwdata;
    else
      vif.PWDATA <= '0;

    // Step 2: ACCESS Cycle
    @(posedge vif.PCLK);
    vif.PENABLE <= 1'b1;

    // Wait for PREADY (Spec: PREADY is tied high, but loop ensures standard APB compliance)
    while (!vif.PREADY) begin
      @(posedge vif.PCLK);
    end

    // Capture read data or error response
    if (!item.pwrite) begin
      item.prdata = vif.PRDATA;
    end
    item.pslverr = vif.PSLVERR;

    // Step 3: Deassert control signals to return to IDLE
    @(posedge vif.PCLK);
    vif.PSEL    <= 1'b0;
    vif.PENABLE <= 1'b0;
  endtask

endclass

`endif // APB_DRIVER_SV
