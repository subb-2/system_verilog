`timescale 1ns / 1ps

module tb_dedicated_cpu1 ();

    logic clk, rst;
    logic [7:0] out;

    dedicated_cpu1 dut (
        .clk(clk),
        .rst(rst),
        .out(out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(posedge clk);
        @(negedge clk);
        rst = 0;
        repeat (50) @(posedge clk);
        $stop;
    end

endmodule
