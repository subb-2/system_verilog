`timescale 1ns / 1ps

interface fifo_interface (
    input clk
);
    logic       rst;
    logic [7:0] wdata;
    logic       push;
    logic       pop;
    logic       full;
    logic       empty;
    logic [7:0] rdata;
endinterface  //fifo_interface

class transaction;

    rand bit [7:0] wdata;
    rand bit       push;
    rand bit       pop;
    logic          full;
    logic          empty;
    logic    [7:0] rdata;
    function void display(string name);
        $display("%t : [%s] wdata = %8d, push = %d, pop = %d, full = %d, empty = %d, rdata = %8d",
                $time, name, wdata, push, pop, full, empty, rdata);
    endfunction  //new()
endclass  //transaction

class generator;

    

    function new();
        
    endfunction //new()
endclass //generator

module tb_fifo_sv ();

    fifo_interface fifo_if (clk);

    fifo_sv dut (
        .clk  (clk),
        .rst  (fifo_if.rst),
        .wdata(fifo_if.wdata),
        .push (fifo_if.push),
        .pop  (fifo_if.pop),
        .full (fifo_if.full),
        .empty(fifo_if.empty),
        .rdata(fifo_if.rdata)
    );

endmodule
