`timescale 1ns / 1ps

module button_auto_repeat #(
    parameter int HOLD_CYCLES   = 50_000_000,
    // REPEAT_CYCLES must be smaller than HOLD_CYCLES
    parameter int REPEAT_CYCLES = 5_000_000
) (
    input  logic clk,
    input  logic button,
    output logic pulse
);

  // Internal interconnect signals as specified in Section 7.5
  logic rise;
  logic held;
  logic pulse_train;
  logic held_prev = 1'b0;

  // Submodule 1: Brief press detector (button -> rising_edge_detector -> rise)
  rising_edge_detector u_rising_edge_detector (
      .clk   (clk),
      .sig_in(button),
      .rise  (rise)
  );

  // Submodule 2: Hold detector (button -> button_hold_detect -> held)
  button_hold_detect #(
      .HOLD_CYCLES(HOLD_CYCLES)
  ) u_button_hold_detect (
      .clk   (clk),
      .button(button),
      .held  (held)
  );

  // Submodule 3: Repeat pulse generator (held -> restartable_rate_generator -> pulse_train)
  restartable_rate_generator #(
      .CYCLE_COUNT(REPEAT_CYCLES)
  ) u_restartable_rate_generator (
      .clk (clk),
      .run (held_prev),
      .tick(pulse_train)
  );

  // Combination output logic: immediate pulse on initial press OR pulse train during hold
  always_ff @(posedge clk) begin
    held_prev <= held;
  end

  assign pulse = rise | (button & pulse_train) | (button & held & ~held_prev);

endmodule
