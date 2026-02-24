`timescale 1ns / 1ps

module sv_adder (
    input  [31:0] a,
    input  [31:0] b,
    input         mode,
    output [31:0] s,
    output        c
);

    assign {c, s} = (mode) ? a - b : a + b;

endmodule
