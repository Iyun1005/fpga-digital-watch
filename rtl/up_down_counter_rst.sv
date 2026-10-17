
`timescale 1ns / 1ps

module up_down_counter_rst #(
    parameter int MAX   = 2,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic up,
    output logic [WIDTH-1:0] count
);

  initial count = '0;

  always_ff @(posedge clk) begin
    if (rst) begin
      count <= '0;
    end else if (enable) begin
      if (up) begin
        if (count == WIDTH'(MAX)) count <= '0;
        else count <= count + 1'b1;
      end else begin
        if (count == '0) count <= WIDTH'(MAX);
        else count <= count - 1'b1;
      end
    end
  end

endmodule
