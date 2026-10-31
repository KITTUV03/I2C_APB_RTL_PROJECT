DUT-to-interface connection mapping
Here is the mapping for verification.
DUT signal	Interface signal	Direction

PCLK	    clk					Input
PRESETn		rst_n				Input
PADDR		apb_vif.PADDR		Input
PSEL		apb_vif.PSEL		Input
PENABLE		apb_vif.PENABLE		Input
PWRITE		apb_vif.PWRITE		Input
PWDATA		apb_vif.PWDATA		Input
PRDATA		apb_vif.PRDATA		Output
PREADY		apb_vif.PREADY		Output
PSLVERR		apb_vif.PSLVERR		Output
irq			apb_vif.irq			Output
scl			i2c_vif.scl			Inout
sda			i2c_vif.sda			Inout
