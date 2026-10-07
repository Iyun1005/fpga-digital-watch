// This module introduces the function of making the counter count up or down based on the input signal 'up'
// Only moves when 'enable' is HIGH


`timescale 1ns / 1ps

module up_down_counter #(
    parameter int MAX   = 2,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic enable,
    input logic up,
    output logic [WIDTH-1:0] count = '0
);

  localparam logic [WIDTH-1:0] Max = WIDTH'(MAX);

  logic [WIDTH-1:0] next_count;

  always_ff @(posedge clk) begin
    if (enable) begin
      count <= next_count;
    end
  end

  always_comb begin
    if (up) begin
      next_count = (count == Max) ? 0 : count + WIDTH'(1);
    end else begin
      next_count = (count == 0) ? Max : count - WIDTH'(1);
    end
  end
endmodule

