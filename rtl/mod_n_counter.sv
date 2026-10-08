`timescale 1ns / 1ps

module mod_n_counter #(
    parameter int N = 4,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic rst,
    input logic enable,
    output logic [WIDTH-1:0] count = '0
);

  localparam logic [WIDTH-1:0] Max = WIDTH'(N - 1);

  logic [WIDTH-1:0] next_count;

  always_ff @(posedge clk) begin
    if (rst) begin
      count <= '0;
    end else if (enable) begin
      count <= next_count;
    end
  end

  always_comb begin
    if (count == Max) begin
      next_count = '0;
    end else begin
      next_count = count + WIDTH'(1);
    end
  end
endmodule
