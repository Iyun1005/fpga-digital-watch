
`timescale 1ns / 1ps

module snapshot_mux #(
    parameter int WIDTH = 1
) (
    input logic clk,
    input logic hold,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

  logic [WIDTH-1:0] snapshot = '0;

  // Capture the input on every rising clock edge
  // while hold is low.
  always_ff @(posedge clk) begin
    if (!hold) snapshot <= d;
  end

  // Select live input or stored snapshot.
  assign q = hold ? snapshot : d;

endmodule
