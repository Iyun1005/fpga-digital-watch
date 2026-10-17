`timescale 1ns / 1ps

module stopwatch_control (
    input  logic clk,
    input  logic rise_start_stop,
    input  logic rise_lap,
    output logic counter_rst,
    output logic counter_enable,
    output logic lap_hold
);

  // FSM state outputs, initially stopped and live
  initial begin
    counter_rst    = 1'b0;
    counter_enable = 1'b0;
    lap_hold       = 1'b0;
  end

  // Next-state signals
  logic next_rst;
  logic next_enable;
  logic next_hold;

  // Both buttons pressed simultaneously: ignore both
  logic valid_start_stop;
  logic valid_lap;

  assign valid_start_stop = rise_start_stop && !rise_lap;
  assign valid_lap = rise_lap && !rise_start_stop;

  // Start/Stop toggles running without changing lap_hold
  assign next_enable = counter_enable ^ valid_start_stop;

  // Lap toggles the display hold when appropriate
  assign next_hold = lap_hold ^ (valid_lap && (counter_enable || lap_hold));

  // Reset only when stopped with a live display
  always_comb begin
    next_rst = 1'b0;

    if (valid_lap && !counter_enable && !lap_hold) next_rst = 1'b1;
  end

  // Update FSM on each rising clock edge
  always_ff @(posedge clk) begin
    counter_rst    <= next_rst;
    counter_enable <= next_enable;
    lap_hold       <= next_hold;
  end

endmodule
