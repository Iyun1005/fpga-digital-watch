// This module converts a 7-bit binary number (0-99) into its BCD representation, outputting the tens and ones digits separately.
// e.g
// input bin = 7'd45
// output tens = 4'(bin / 7'd10) = 4'd4 (0100)
// output ones = 4'(bin % 7'd10) = 4'd5 (0101)

// This feeds into the seven_segment module to display the decimal digits on a 7-segment display.

`timescale 1ns / 1ps

module binary_to_bcd (
    input  logic [6:0] bin,   // binary input 0-99
    output logic [3:0] tens,  // decimal tens digit (BCD)
    output logic [3:0] ones   // decimal ones digit (BCD)
);

  assign tens = 4'(bin / 7'd10);
  assign ones = 4'(bin % 7'd10);

endmodule

