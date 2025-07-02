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
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Map pins from the tt_um_top module to the testbench signals
  assign clk = ui_in[0];
  wire tx = uo_out[0];
  wire led0_r = uo_out[1];
  wire led0_g = uo_out[2];
  wire led0_b = uo_out[3];
  wire [3:0] led = uo_out[7:4];
  wire ds18b20_dq;

  // Handle bidirectional pin for ds18b20_dq
  assign ds18b20_dq = uio_oe[0] ? uio_out[0] : 1'bz;
  assign uio_in[0] = ds18b20_dq;

  // Instantiate the tt_um_top module
  tt_um_top user_project (
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

endmodule
