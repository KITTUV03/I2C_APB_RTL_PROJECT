`ifndef I2C_IF_SV
`define I2C_IF_SV

interface i2c_if;

  wire scl;
  wire sda;

  logic scl_drive_low = 1'b0;
  logic sda_drive_low = 1'b0;

  pullup p1 (scl);
  pullup p2 (sda);

  assign scl = (scl_drive_low) ? 1'b0 : 1'bz;
  assign sda = (sda_drive_low) ? 1'b0 : 1'bz;

  modport slave_mp (
    inout scl,
    inout sda,
    input scl_drive_low,
    input sda_drive_low
  );
  
  modport monitor_mp (
    input scl,
    input sda
  );

endinterface

`endif // I2C_IF_SV
