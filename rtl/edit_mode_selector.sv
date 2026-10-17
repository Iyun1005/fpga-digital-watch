
`timescale 1ns / 1ps

module edit_mode_selector #(
    parameter int HOLD_CYCLES = 50_000_000
) (
    input logic clk,
    input logic button,
    output logic [2:0] mode_enable
);

  logic long_press;
  button_hold_pulse #(
      .HOLD_CYCLES(HOLD_CYCLES)
  ) u_hold_pulse (
      .clk(clk),
      .button(button),
      .pulse(long_press)
  );

  logic press;
  rising_edge_detector u_detector (
      .clk(clk),
      .sig_in(button),
      .rise(press)
  );

  logic armed;
  logic disarm;
  arming_latch u_latch (
      .clk(clk),
      .arm(long_press),
      .disarm(disarm),
      .armed(armed)
  );

  logic reset_counter;
  logic enable_counter;
  logic [1:0] count;
  mod_n_counter #(
      .N(3),
      .WIDTH(2)
  ) u_mod_3_counter (
      .clk(clk),
      .rst(reset_counter),
      .enable(enable_counter),
      .count(count)
  );


  assign enable_counter = armed && press;
  assign reset_counter = !armed;


  assign disarm = enable_counter && (count == 2'd2);


  always_comb begin
    mode_enable = 3'b000;

    if (armed) begin
      case (count)
        2'd0: mode_enable = 3'b001;  // Edit seconds
        2'd1: mode_enable = 3'b010;  // Edit minutes
        2'd2: mode_enable = 3'b100;  // Edit hours
        default: mode_enable = 3'b000;
      endcase
    end
  end

endmodule
