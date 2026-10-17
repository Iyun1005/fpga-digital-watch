
`timescale 1ns / 1ps

module user_top_watch_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic clk,
    input logic [3:0] button,
    input logic [9:0] sw,
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds
);

  // ------------------
  // Internal signals
  // ------------------

  logic seconds_tick;
  logic minutes_tick;
  logic hours_tick;

  logic [5:0] seconds;
  logic [5:0] minutes;
  logic [4:0] hours;

  // ------------------
  // One-second tick
  // ------------------

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_rate_generator (
      .clk (clk),
      .run (1'b1),
      .tick(seconds_tick)
  );

  // ------------------
  // Counter cascading
  // ------------------

  assign minutes_tick = seconds_tick && (seconds == 6'd59);
  assign hours_tick   = minutes_tick && (minutes == 6'd59);

  // ------------------
  // Seconds counter
  // ------------------

  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_seconds (
      .clk      (clk),
      .tick     (seconds_tick),
      .edit_mode(1'b0),
      .inc      (1'b0),
      .dec      (1'b0),
      .count    (seconds)
  );

  // ------------------
  // Minutes counter
  // ------------------

  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_minutes (
      .clk      (clk),
      .tick     (minutes_tick),
      .edit_mode(1'b0),
      .inc      (1'b0),
      .dec      (1'b0),
      .count    (minutes)
  );

  // ------------------
  // Hours counter
  // ------------------

  editable_counter #(
      .N(24),
      .WIDTH(5)
  ) u_hours (
      .clk      (clk),
      .tick     (hours_tick),
      .edit_mode(1'b0),
      .inc      (1'b0),
      .dec      (1'b0),
      .count    (hours)
  );

  // ------------------
  // Display outputs
  // ------------------

  assign hours_disp = {2'b00, hours};
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};

  // ------------------
  // Other outputs
  // ------------------

  assign led = 10'b0;

  assign blank_hours = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

  // Suppress warnings for unused inputs
  wire unused_inputs = &{1'b0, button, sw};

endmodule
