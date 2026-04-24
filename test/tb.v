`default_nettype none
`timescale 1ns / 1ps
module tb ();
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end
  reg clk;
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
  tt_um_traffic_light dut (
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );
  task display_state;
    begin
      $display("Time=%0t | State=%b | Main={R=%b,Y=%b,G=%b} | Side={R=%b,Y=%b,G=%b} | Timer=%d",
               $time,
               dut.state,
               uo_out[2], uo_out[1], uo_out[0],
               uo_out[5], uo_out[4], uo_out[3],
               uio_out[3:0]);
    end
  endtask
  initial begin
    rst_n = 0;
    ena = 1;
    ui_in = 8'b0;
    uio_in = 8'b0;
    $display("=== Traffic Light FSM Simulation ===");
    $display("");
    $display("Applying reset...");
    #20;
    rst_n = 1;
    #10;
    display_state();
    $display("");
    $display("Running traffic light cycles...");
    repeat (100) begin
      @(posedge clk);
      #1;
      if (dut.timer == 0 || $time < 100)
        display_state();
    end
    $display("");
    $display("Testing sensor input...");
    ui_in[0] = 1;
    repeat (50) begin
      @(posedge clk);
      #1;
      if (dut.timer == 0)
        display_state();
    end
    $display("");
    $display("=== Simulation Complete ===");
    $finish;
  end
endmodule
