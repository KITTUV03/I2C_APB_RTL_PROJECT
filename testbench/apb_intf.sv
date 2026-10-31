`ifndef APB_IF_SV
`define APB_IF_SV

interface apb_if (input logic PCLK, input logic PRESETn);

  logic [`ADDR_WIDTH-1:0]  PADDR;
  logic        PSEL;
  logic        PENABLE;
  logic        PWRITE;
  logic [`DATA_WIDTH-1:0]  PWDATA;
  logic [`DATA_WIDTH-1:0]  PRDATA;
  logic        PREADY;
  logic        PSLVERR;
  logic        irq;

  clocking drv_cb @(posedge PCLK);
    default input #1step output #1step;
    output PADDR;
    output PSEL;
    output PENABLE;
    output PWRITE;
    output PWDATA;
    input  PRDATA;
    input  PREADY;
    input  PSLVERR;
    input  irq;
  endclocking

  clocking mon_cb @(posedge PCLK);
    default input #1step;
    input PADDR;
    input PSEL;
    input PENABLE;
    input PWRITE;
    input PWDATA;
    input PRDATA;
    input PREADY;
    input PSLVERR;
    input irq;
  endclocking

  modport master_mp (clocking drv_cb, input PRESETn);
  modport monitor_mp (clocking mon_cb, input PRESETn);

endinterface 

`endif
