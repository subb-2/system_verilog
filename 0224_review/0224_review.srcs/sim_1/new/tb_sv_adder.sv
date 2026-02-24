`timescale 1ns / 1ps

interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic        mode;
    logic [31:0] s;
    logic        c;

endinterface  //adder_interf

//transaction : random 값 담긴 곳 
class transaction;
    rand bit [31:0] a;
    rand bit [31:0] b;
    rand bit        mode;
    logic    [31:0] s;
    logic           c;
endclass  //transaction

//generator : randomrize 하는 곳 
class generator;
    //randomrize를 위해 random 값 가져와야 함 
    transaction tr;
    virtual adder_interface adder_interf_gen;

    function new(virtual adder_interface adder_interf_ext);
        this.adder_interf_gen = adder_interf_ext;
    endfunction  //new()

    task run();
        tr = new();
        tr.randomize();

        adder_interf_gen.a = tr.a;
        adder_interf_gen.b = tr.b;
        adder_interf_gen.mode = tr.mode;

        #10;

    endtask  //run
endclass  //generator

module tb_sv_adder ();


    adder_interface adder_interf ();

    generator gen;

    sv_adder dut (
        .a(adder_interf.a),
        .b(adder_interf.b),
        .mode(adder_interf.mode),
        .s(adder_interf.s),
        .c(adder_interf.c)
    );

    initial begin
        gen = new(adder_interf);
        gen.run();
        $stop;
    end

endmodule
