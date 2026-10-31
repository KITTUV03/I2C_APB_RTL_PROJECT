`timescale 1ns/1ps

`include "uvm_macros.svh"
`include "i2c_apb_package.sv"

module tb_top;

  import uvm_pkg::*;
  import pkg::*;

  bit   clk;
  logic rst_n;

  always #(`PCLK_PERIOD/2) clk = ~clk;

  apb_if apb_vif (
    .PCLK    (clk),
    .PRESETn (rst_n)
  );

  i2c_if i2c_vif ();

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

  task automatic apply_reset;
    rst_n = `RESET_ASSERT;
    repeat (10) @(posedge clk);
    rst_n = `RESET_DEASSERT;
    $display("[%0t] Reset Released", $time);
  endtask

  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb_vif);
    uvm_config_db#(virtual i2c_if)::set(null, "*", "i2c_vif", i2c_vif);

    run_test("i2c_write_test");
  end

  initial begin
    rst_n = `RESET_ASSERT;
    apply_reset();
  end

  `WAVEFORM

endmodule
