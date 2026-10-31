//sync_2ff

module sync_2ff (clk,rst_n,din,dout);

  input clk,rst_n,din;
  output reg dout;
  
  wire d1;
  reg q ;
  
  always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) {dout,q} <= 0;
    else {dout,q} <= {q,din}; 
  end 

endmodule
