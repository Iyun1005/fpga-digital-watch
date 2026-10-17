
`timescale 1ns / 1ps

module user_top_watch_v4 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic clk,
    /* verilator lint_off UNUSED */
    input logic [3:0] button,
    input logic [9:0] sw,
    /* verilator lint_on UNUSED */
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds
);

  // ------------------
  // Internal Signals
  // ------------------

  logic seconds_tick;
  logic minutes_tick;
  logic hours_tick;

  logic [5:0] seconds;
  logic [5:0] minutes;
  logic [4:0] hours;

  logic seconds_edit;
  logic minutes_edit;
  logic hours_edit;

  logic seconds_inc;
  logic minutes_inc;
  logic hours_inc;

  logic seconds_dec;
  logic minutes_dec;
  logic hours_dec;

  logic [2:0] mode_enable;
  logic pwm_out;

  logic inc_pulse;
  logic dec_pulse;

  logic seconds_run;
  logic previous_seconds_mode;

  // ------------------
  // Accurate Time Setting
  // ------------------

  initial previous_seconds_mode = 1'b0;

  always_ff @(posedge clk) begin
    previous_seconds_mode <= mode_enable[0];
  end

  // Restart the one-second timer when
  // changing from seconds to minutes mode
  assign seconds_run = !(previous_seconds_mode && mode_enable[1]);

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_rate_generator (
      .clk (clk),
      .run (seconds_run),
      .tick(seconds_tick)
  );

  // ------------------
  // Counter Cascading
  // ------------------

  assign minutes_tick = seconds_tick && (seconds == 6'd59);
  assign hours_tick   = minutes_tick && (minutes == 6'd59);

  // ------------------
  // Seconds Counter
  // ------------------

  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_seconds (
      .clk      (clk),
      .tick     (seconds_tick),
      .edit_mode(seconds_edit),
      .inc      (seconds_inc),
      .dec      (seconds_dec),
      .count    (seconds)
  );

  // ------------------
  // Minutes Counter
  // ------------------

  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_minutes (
      .clk      (clk),
      .tick     (minutes_tick),
      .edit_mode(minutes_edit),
      .inc      (minutes_inc),
      .dec      (minutes_dec),
      .count    (minutes)
  );

  // ------------------
  // Hours Counter
  // ------------------

  editable_counter #(
      .N(24),
      .WIDTH(5)
  ) u_hours (
      .clk      (clk),
      .tick     (hours_tick),
      .edit_mode(hours_edit),
      .inc      (hours_inc),
      .dec      (hours_dec),
      .count    (hours)
  );

  // ------------------
  // Display Outputs
  // ------------------

  assign hours_disp = {2'b00, hours};
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};

  assign led = 10'b0;

  // ------------------
  // Mode Selection
  // ------------------

  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)
  ) u_mode_selector (
      .clk        (clk),
      .button     (button[3]),
      .mode_enable(mode_enable)
  );

  // ------------------
  // Display Flashing
  // ------------------

  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),
      .DUTY_CYCLES  (2 * CYCLES_PER_SECOND / 5)
  ) u_pwm_generator (
      .clk    (clk),
      .rst    (1'b0),
      .pwm_out(pwm_out)
  );

  assign blank_seconds = mode_enable[0] && !pwm_out;
  assign blank_minutes = mode_enable[1] && !pwm_out;
  assign blank_hours   = mode_enable[2] && !pwm_out;

  // ------------------
  // Button Auto-Repeat
  // ------------------

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_inc_repeat (
      .clk   (clk),
      .button(button[1]),
      .pulse (inc_pulse)
  );

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_dec_repeat (
      .clk   (clk),
      .button(button[0]),
      .pulse (dec_pulse)
  );

  // ------------------
  // Edit Mode Logic
  // ------------------

  assign seconds_edit = mode_enable[0];

  assign minutes_edit = mode_enable[0] || mode_enable[1];

  assign hours_edit = |mode_enable;

  // Increment selected field
  assign seconds_inc = mode_enable[0] && inc_pulse;
  assign minutes_inc = mode_enable[1] && inc_pulse;
  assign hours_inc = mode_enable[2] && inc_pulse;

  // Decrement selected field
  assign seconds_dec = mode_enable[0] && dec_pulse;
  assign minutes_dec = mode_enable[1] && dec_pulse;
  assign hours_dec = mode_enable[2] && dec_pulse;

endmodule
