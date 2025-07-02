`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  wire led0_r;
  wire led0_g;
  wire led0_b;
  wire [3:0] led;
  wire tx;
  wire ds18b20_dq;

  // Instantiate the top module
  top user_project (
      .clk(clk),
      .led0_r(led0_r),
      .led0_g(led0_g),
      .led0_b(led0_b),
      .led(led),
      .tx(tx),
      .ds18b20_dq(ds18b20_dq)
  );

endmodule
