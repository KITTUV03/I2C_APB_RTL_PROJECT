`timescale 1ns/1ps

`include "uvm_macros.svh"
`include "i2c_apb_package.sv"

// ============================================================================
// Top-Level Testbench Module (tb_top)
// ============================================================================
module tb_top;

  import uvm_pkg::*;
  import pkg::*;

  // Functional clock and reset
  bit   clk;
  logic rst_n;

  // 100 MHz clock generation (Period = 10ns per Spec Section 4 & 9)
  always #(`PCLK_PERIOD/2) clk = ~clk;

  // Interface instances
  apb_if apb_vif (
    .PCLK    (clk),
    .PRESETn (rst_n)
  );

  i2c_if i2c_vif ();

  // DUT Instance (Spec Section 3 & 9)
  i2c_top #(
    .CLK_FREQ_MHZ     (100),
    .FILTER_LEN       (3),
    .GLITCH_FILTER_EN (1),
    .CMD_FIFO_DEPTH   (1024),
    .RX_FIFO_DEPTH    (1024)
  ) dut (
    .PCLK    (clk),
    .PRESETn (rst_n),
    .PADDR   (apb_vif.PADDR),
    .PSEL    (apb_vif.PSEL),
    .PENABLE (apb_vif.PENABLE),
    .PWRITE  (apb_vif.PWRITE),
    .PWDATA  (apb_vif.PWDATA),
    .PRDATA  (apb_vif.PRDATA),
    .PREADY  (apb_vif.PREADY),
    .PSLVERR (apb_vif.PSLVERR),
    .irq     (apb_vif.irq),
    .scl     (i2c_vif.scl),
    .sda     (i2c_vif.sda)
  );

  // Reset Task (Spec Section 4: PRESETn active low)
  task automatic apply_reset;
    rst_n = `RESET_ASSERT;
    repeat (10) @(posedge clk);
    rst_n = `RESET_DEASSERT;
    $display("[%0t] Reset Released", $time);
  endtask

  initial begin
    // Store virtual interfaces in UVM config DB
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb_vif);
    uvm_config_db#(virtual i2c_if)::set(null, "*", "i2c_vif", i2c_vif);

    // Default test is i2c_write_read_test (can be overridden via +UVM_TESTNAME=<name>)
    run_test("i2c_write_read_test");
  end

  initial begin
    rst_n = `RESET_ASSERT;
    apply_reset();
  end

  `WAVEFORM

endmodule
