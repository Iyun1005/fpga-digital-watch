`timescale 1ns / 1ps

module rising_edge_detector (
    input  logic clk,
    input  logic sig_in,
    output logic rise
);

  logic sig_in_prev;

  always_ff @(posedge clk) begin
    sig_in_prev <= sig_in;
  end

  assign rise = sig_in && ~sig_in_prev;

endmodule
