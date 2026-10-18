`timescale 1ns / 1ps

module user_top_timer_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
`ifdef FORMAL
    output logic probe_running,
    output logic [2:0] probe_mode_enable,
`endif
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
  logic seconds_tick_raw;

  logic seconds_borrow;
  logic minutes_borrow;

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

  logic running = 1'b0;
  logic rise_start_stop;
  logic time_zero;

  // ------------------
  // Timer Running Control
  // ------------------

  assign time_zero = (hours == 5'd0) && (minutes == 6'd0) && (seconds == 6'd0);

  rising_edge_detector u_start_stop (
      .clk   (clk),
      .sig_in(button[0]),
      .rise  (rise_start_stop)
  );

  always_ff @(posedge clk) begin
    if (|mode_enable) running <= 1'b0;
    else if (time_zero) running <= 1'b0;
    else if (rise_start_stop) running <= ~running;
  end

  // ------------------
  // One-Second Countdown
  // ------------------

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_rate_generator (
      .clk (clk),
      .run (running),
      .tick(seconds_tick_raw)
  );

  assign seconds_tick = seconds_tick_raw && running && !time_zero && !(|mode_enable);

  // ------------------
  // Counter Cascading
  // ------------------

  assign minutes_tick = seconds_borrow;
  assign hours_tick   = minutes_borrow;

  // ------------------
  // Seconds Counter
  // ------------------

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_seconds (
      .clk       (clk),
      .clr       (1'b0),
      .tick      (seconds_tick),
      .edit_mode (seconds_edit),
      .inc       (seconds_inc),
      .dec       (seconds_dec),
      .count     (seconds),
      .borrow_out(seconds_borrow)
  );

  // ------------------
  // Minutes Counter
  // ------------------

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_minutes (
      .clk       (clk),
      .clr       (1'b0),
      .tick      (minutes_tick),
      .edit_mode (minutes_edit),
      .inc       (minutes_inc),
      .dec       (minutes_dec),
      .count     (minutes),
      .borrow_out(minutes_borrow)
  );

  // ------------------
  // Hours Counter
  // ------------------


  editable_countdown #(
      .MAX  (23),
      .WIDTH(5)
  ) u_hours (
      .clk       (clk),
      .clr       (1'b0),
      .tick      (hours_tick),
      .edit_mode (hours_edit),
      .inc       (hours_inc),
      .dec       (hours_dec),
      .count     (hours),
      /* verilator lint_off PINCONNECTEMPTY */
      .borrow_out()
      /* verilator lint_on PINCONNECTEMPTY */
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
      .button     (button[3] && !running),
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

  // ------------------
  // Formal Verification
  // ------------------

`ifdef FORMAL
  assign probe_running = running;
  assign probe_mode_enable = mode_enable;
`endif

endmodule
