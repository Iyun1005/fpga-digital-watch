`timescale 1ns / 1ps

module user_top_brightness_timepiece #(
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
  // 1. Integrated timepiece
  // ------------------------------------

  logic app_blank_hours;
  logic app_blank_minutes;
  logic app_blank_seconds;

  user_top_timepiece_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_watch (
      .clk          (clk),
      .button       (button),
      .sw           (sw),
      .led          (led),
      .hours_disp   (hours_disp),
      .minutes_disp (minutes_disp),
      .seconds_disp (seconds_disp),
      .blank_hours  (app_blank_hours),
      .blank_minutes(app_blank_minutes),
      .blank_seconds(app_blank_seconds)
  );

  // ------------------------------------
  // 2. PWM counter: 1 ms period
  // ------------------------------------

  localparam int PwmPeriod = CYCLES_PER_SECOND / 1000;
  localparam int PwmWidth = (PwmPeriod > 1) ? $clog2(PwmPeriod) : 1;

  logic [PwmWidth-1:0] pwm_count;

  mod_n_counter #(
      .N    (PwmPeriod),
      .WIDTH(PwmWidth)
  ) u_pwm_counter (
      .clk   (clk),
      .rst   (1'b0),
      .enable(1'b1),
      .count (pwm_count)
  );

  // ------------------------------------
  // 3. Brightness selection
  // ------------------------------------

  logic pwm_blank;
  logic [1:0] brightness_sel;

  assign brightness_sel = sw[9:8];

  assign pwm_blank =
      (brightness_sel == 2'b00) ? (pwm_count >= PwmWidth'(PwmPeriod / 8)) :
      (brightness_sel == 2'b01) ? (pwm_count >= PwmWidth'(PwmPeriod / 4)) :
      (brightness_sel == 2'b11) ? (pwm_count >= PwmWidth'(PwmPeriod / 2)) :
      1'b0;

  // ------------------------------------
  // 4. Combine app blanking with PWM
  // ------------------------------------

  assign blank_hours = app_blank_hours | pwm_blank;
  assign blank_minutes = app_blank_minutes | pwm_blank;
  assign blank_seconds = app_blank_seconds | pwm_blank;

endmodule
