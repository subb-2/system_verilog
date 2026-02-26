`timescale 1ns / 1ps

interface ram_interface (
    input clk
);  //interface에 port 제작

    //logic       clk;
    logic       we;
    logic [4:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;

endinterface  //ram_interface

class transaction;

    rand bit [3:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    logic    [7:0] rdata;

    function void display(string name);
        $display("%t : [%s] we = %d, addr = %2h, wdata = %2h, rdata = %2h",
                 $time, name, we, addr, wdata, rdata);
    endfunction  //new()
endclass  //transaction

class generator;

    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    event                  gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.display("gen");
            @(gen_next_ev);
        end
    endtask  //run()

endclass  //generator

class driver;

    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual ram_interface  ram_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual ram_interface ram_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ram_if = ram_if;
    endfunction  //new()

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge ram_if.clk);
            ram_if.addr = tr.addr;
            ram_if.wdata = tr.wdata;
            ram_if.we = tr.we; //여기에 rma_if.we로 잘못 넣어서 X로 나옴 
            tr.display("drv");
        end
    endtask  //run()

endclass  //driver

class monitor;

    transaction            tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface  ram_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual ram_interface ram_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ram_if = ram_if;
    endfunction  //new()

    task run();
        forever begin
            @(posedge ram_if.clk); //posedge마다 매번 report 
            #1; //상승엣지에서 값이 나오기 때문에 rc 발생한 거 같음 
            tr       = new();
            tr.addr  = ram_if.addr;
            tr.we    = ram_if.we;
            tr.wdata = ram_if.wdata;
            tr.rdata = ram_if.rdata;
            tr.display("mon");
            mon2scb_mbox.put(tr);
        end
    endtask  //run()

endclass  //monitor

class scorboard;

    transaction                  tr;
    mailbox #(transaction)       mon2scb_mbox;
    event                        gen_next_ev;

    //coverage
    covergroup cg_sram;
        cp_addr: coverpoint tr.addr {
            bins min = {0}; //bins : 대상 
            bins max = {15};
            bins mid = {[1:14]};
        }
    endgroup

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
        cg_sram = new();
    endfunction  //new()

    task run();
        logic [7:0] expected_ram [0:15];
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");

            cg_sram.sample(); //자동 업데이트 
            // pass, fail
            if (tr.we) begin
                expected_ram[tr.addr] = tr.wdata;
                //$display("%2h", expected_ram[tr.addr]);
                //coverage 추가하면 이거 없어도 돼?
            end else begin
                if (expected_ram[tr.addr] === tr.rdata) begin
                    $display("Pass");
                end else begin
                    $display("Fail : expected data = %2h, rdata = %2h", expected_ram[tr.addr], tr.rdata);
                end
            end
            -> gen_next_ev;
        end
    endtask  //run()

endclass  //scorboard

class environment;
    
    //선언 
    generator              gen;
    driver                 drv;
    monitor                mon;
    scorboard              scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event                  gen_next_ev;

    function new(virtual ram_interface ram_if);

        gen2drv_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, ram_if);
        mon = new(mon2scb_mbox, ram_if);
        scb = new(mon2scb_mbox, gen_next_ev);

    endfunction  //new()

    task run();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any

        #10;
        //coverage 몇 개 test 해보았는지 출력 
        $display("coverage addr = %d", scb.cg_sram.get_inst_coverage()); 
        $stop;
    endtask  //run
endclass  //environment


module tb_sram_sv ();

    logic clk;

    ram_interface ram_if (clk);
    environment env;

    sram_sv dut (
        .clk(clk),
        .we(ram_if.we),
        .addr(ram_if.addr),
        .wdata(ram_if.wdata),
        .rdata(ram_if.rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(ram_if);
        env.run();
    end

endmodule
