`timescale 1ns / 1ps

module user_top_stopwatch_v1 #(
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

  // ------------------------------------
  // 1. Button rising-edge detectors
  // ------------------------------------

  logic rise_start_stop;
  logic rise_lap;

  rising_edge_detector u_start_stop (
      .clk   (clk),
      .sig_in(button[0]),
      .rise  (rise_start_stop)
  );

  rising_edge_detector u_lap (
      .clk   (clk),
      .sig_in(button[1]),
      .rise  (rise_lap)
  );

  // ------------------------------------
  // 2. Stopwatch control FSM
  // ------------------------------------

  logic counter_rst;
  logic counter_enable;
  logic lap_hold;

  stopwatch_control u_control (
      .clk            (clk),
      .rise_start_stop(rise_start_stop),
      .rise_lap       (rise_lap),
      .counter_rst    (counter_rst),
      .counter_enable (counter_enable),
      .lap_hold       (lap_hold)
  );

  // ------------------------------------
  // 3. Stopwatch counter
  // ------------------------------------

  logic [6:0] minutes;
  logic [5:0] seconds;
  logic [6:0] centiseconds;

  stopwatch_counter #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_counter (
      .clk         (clk),
      .rst         (counter_rst),
      .enable      (counter_enable),
      .minutes     (minutes),
      .seconds     (seconds),
      .centiseconds(centiseconds)
  );

  // ------------------------------------
  // 4. Snapshot multiplexer
  // ------------------------------------

  logic [19:0] live_time;
  logic [19:0] display_time;

  assign live_time = {minutes, seconds, centiseconds};

  snapshot_mux #(
      .WIDTH(20)
  ) u_snapshot (
      .clk (clk),
      .hold(lap_hold),
      .d   (live_time),
      .q   (display_time)
  );

  // ------------------------------------
  // 5. Display outputs (MM:SS:CC)
  // ------------------------------------

  assign hours_disp = display_time[19:13];
  assign minutes_disp = {1'b0, display_time[12:7]};
  assign seconds_disp = display_time[6:0];

  // ------------------------------------
  // 6. Unused outputs
  // ------------------------------------

  assign led = 10'b0;

  assign blank_hours = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

  // Suppress unused input warnings
  /* verilator lint_off UNUSEDSIGNAL */
  wire unused_inputs = &{button[3:2], sw};
  /* verilator lint_on UNUSEDSIGNAL */

endmodule
