`timescale 1ns / 1ps

module top_time_display_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic CLOCK_50,
    input logic [1:0] SW,
    output logic [6:0] HEX5,
    output logic [6:0] HEX4,
    output logic [6:0] HEX3,
    output logic [6:0] HEX2,
    output logic [6:0] HEX1,
    output logic [6:0] HEX0
);

  // Local parameters
  localparam int Ticks1Hz = 1;
  localparam int Ticks25Hz = 25;
  localparam int Ticks1000Hz = 1000;

  localparam int Cyclecount1Hz = CYCLES_PER_SECOND / Ticks1Hz;
  localparam int Cyclecount25Hz = CYCLES_PER_SECOND / Ticks25Hz;
  localparam int Cyclecount1000Hz = CYCLES_PER_SECOND / Ticks1000Hz;

  // how many cycles of the 50 MHz clock would
  //go by per tick (1000Hz = 1000 ticks per second)

  // Internal signals
  logic tick_1Hz;
  logic tick_25Hz;
  logic tick_1000Hz;
  logic current_tick;

  logic [4:0] hours;
  logic [5:0] minutes;
  logic [5:0] seconds;

  logic [3:0] bcd_seconds_tens;
  logic [3:0] bcd_seconds_ones;
  logic [3:0] bcd_minutes_tens;
  logic [3:0] bcd_minutes_ones;
  logic [3:0] bcd_hours_tens;
  logic [3:0] bcd_hours_ones;


  // Rate Generators Instantiation
  restartable_rate_generator #(
      .CYCLE_COUNT(Cyclecount1Hz)
  ) u_rate_1Hz (
      .clk (CLOCK_50),
      .run (1'b1),
      .tick(tick_1Hz)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(Cyclecount25Hz)
  ) u_rate_25Hz (
      .clk (CLOCK_50),
      .run (1'b1),
      .tick(tick_25Hz)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(Cyclecount1000Hz)
  ) u_rate_1000Hz (
      .clk (CLOCK_50),
      .run (1'b1),
      .tick(tick_1000Hz)
  );

  // Deciding which speed to go using switches

  always_comb begin
    case (SW)
      2'b00:   current_tick = tick_1Hz;
      2'b01:   current_tick = tick_25Hz;
      2'b10:   current_tick = tick_1000Hz;
      2'b11:   current_tick = 1'b1;
      default: current_tick = tick_1Hz;
    endcase
  end

  // Timekeeper

  hms_counter hms (
      .clk(CLOCK_50),
      .enable(current_tick),
      .hours(hours),
      .minutes(minutes),
      .seconds(seconds)
  );

  // Binary to BCD

  binary_to_bcd bcd_seconds (
      .bin ({1'b0, seconds}),   // trying to make sure this is 7 bits wide for bcd converter
      .tens(bcd_seconds_tens),
      .ones(bcd_seconds_ones)
  );

  binary_to_bcd bcd_minutes (
      .bin ({1'b0, minutes}),
      .tens(bcd_minutes_tens),
      .ones(bcd_minutes_ones)
  );

  binary_to_bcd bcd_hours (
      .bin ({2'b00, hours}),
      .tens(bcd_hours_tens),
      .ones(bcd_hours_ones)
  );

  // Seven Segment Display

  // HEX0 - seconds (ones digit)
  seven_segment #(
      .ACTIVE_LOW(1)
  ) seconds_ones_hex0 (
      .digit(bcd_seconds_ones),
      .blank(1'b0),
      .segments(HEX0)
  );

  // HEX1 - seconds (tens digit)
  seven_segment #(
      .ACTIVE_LOW(1)
  ) seconds_tens_hex1 (
      .digit(bcd_seconds_tens),
      .blank(1'b0),
      .segments(HEX1)
  );

  // HEX2 - minutes (ones digit)
  seven_segment #(
      .ACTIVE_LOW(1)
  ) minutes_ones_hex2 (
      .digit(bcd_minutes_ones),
      .blank(1'b0),
      .segments(HEX2)
  );

  // HEX3 - minutes (tens digit)
  seven_segment #(
      .ACTIVE_LOW(1)
  ) minutes_tens_hex3 (
      .digit(bcd_minutes_tens),
      .blank(1'b0),
      .segments(HEX3)
  );

  // HEX4 - hours (ones digit)
  seven_segment #(
      .ACTIVE_LOW(1)
  ) hours_ones_hex4 (
      .digit(bcd_hours_ones),
      .blank(1'b0),
      .segments(HEX4)
  );

  // HEX5 - hours (tens digit)
  seven_segment #(
      .ACTIVE_LOW(1)
  ) hours_tens_hex5 (
      .digit(bcd_hours_tens),
      .blank(1'b0),
      .segments(HEX5)
  );

endmodule
