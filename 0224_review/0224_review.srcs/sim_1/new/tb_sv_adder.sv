`timescale 1ns / 1ps
//입력 / 분석 

interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic        mode;
    logic [31:0] s;
    logic        c;

endinterface  //adder_interf

//transaction : random 값 담긴 곳 
class transaction;
    randc bit [31:0] a;
    randc bit [31:0] b;
    randc bit mode;
    logic    [31:0] s; // rand로 생성 안하고 logic이므로 gen에서 x로 나타남 
    logic c;

    task display(string name);
        $display(
            "%t : [%s] a = %h, b = %h, mode = %h, sum = %h, carry = %h", $time,
            name, a, b, mode, s,
            c);  //모든 객체에 다 들어있으므로, 이곳에 제작 
    endtask  //display
    
    // 범위 지정 
    // constraint range {
    //     a >10;
    //     a > 32'hffff_0000;
    // }

    //확률 지정
    //constraint dist_pattern {
    //    a dist {
    //        0 :/80,
    //        32'hffff_ffff :/ 10,
    //        [1:32'hffff_fffe] :/ 10
    //    };
    //}

    //constraint list_pattern {
    //    a inside {0, 32'hffff_ffff, 32'h0000_ffff};
    //}

    constraint inside_pattern {a inside {[0 : 16]};}
endclass  //transaction

//generator : randomrize 하는 곳 
class generator;
    //randomrize를 위해 random 값 가져와야 함 
    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    event                  gen_next_ev;  //handler

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;  //env통해 event 받음 
    endfunction  //new()

    task run(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.display(
                "gen"); //event 전 후 위치 : 값 차이는 없지만, 시간 차이 있음 
            @(gen_next_ev); //event 올 때까지 대기 , 멈춘게 아니라 계속 감시 중 
        end

    endtask  //run
endclass  //generator

class driver;

    transaction             tr;
    virtual adder_interface adder_if;
    mailbox #(transaction)  gen2drv_mbox;
    event                   mon_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event mon_next_ev,
                 virtual adder_interface adder_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.mon_next_ev = mon_next_ev;
        this.adder_if = adder_if;
    endfunction  //new()

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            adder_if.a = tr.a;
            adder_if.b = tr.b;
            adder_if.mode = tr.mode;
            tr.display("drv");  // 10n 이후 값은 mon이 확인 
            #10;
            ->mon_next_ev;  //mon으로 event 전송 
        end
    endtask  //run()
endclass  //driver

class monitor;

    transaction tr;
    virtual adder_interface adder_if;
    mailbox #(transaction) mon2scb_mbox;
    event mon_next_ev;  //gen이 발생 

    function new(mailbox#(transaction) mon2scb_mbox, event mon_next_ev,
                 virtual adder_interface adder_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.mon_next_ev = mon_next_ev;
        this.adder_if = adder_if;
    endfunction  //new()

    task run();
        forever begin
            @(mon_next_ev);
            tr = new();
            tr.a = adder_if.a;
            tr.b = adder_if.b;
            tr.mode = adder_if.mode;
            tr.s = adder_if.s;
            tr.c = adder_if.c;
            mon2scb_mbox.put(tr);
            tr.display("mon");
        end

    endtask  //run
endclass  //monitor

class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    bit [31:0] expected_sum;
    bit expected_carry;
    int pass_cnt, fail_cnt;  //integer와 같은거야?

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;

    endfunction  //new()

    task run();
        //logic [32:0] scb_result;
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");
            // compare, pass, fail 
            // generate for compare expected data
            if (tr.mode == 0) begin
                {expected_carry, expected_sum} = tr.a + tr.b;
            end else begin
                {expected_carry, expected_sum} = tr.a - tr.b;
            end
            //compare 
            if ((expected_sum == tr.s) && (expected_carry == tr.c)) begin
                $display("[PASS] : a = %d, b = %d, mode = %d, s = %d, c = %d",
                         tr.a, tr.b, tr.mode, tr.s, tr.c);
                pass_cnt++;
            end else begin
                $display("[FAIL] : a = %d, b = %d, mode = %d, s = %d, c = %d",
                         tr.a, tr.b, tr.mode, tr.s, tr.c);
                fail_cnt++;
                $display("expected sum = %d", expected_sum);
                $display("expected carry = %d", expected_carry);
            end

            // if (tr.mode) begin
            //     scb_result = tr.a - tr.b;
            // end else begin
            //     scb_result = tr.a + tr.b;
            // end
            // if (scb_result == {tr.c, tr.s}) begin
            //     $display("[PASS!!!] : %t : a = %d, b = %d, mode = %d, s = %d, c = %d", $time, tr.a, tr.b, tr.mode, tr.s, tr.c);
            // end else begin
            //     $display("[FAIL!!!] : %t : a = %d, b = %d, mode = %d, s = %d, c = %d", $time, tr.a, tr.b, tr.mode, tr.s, tr.c);
            // end

            ->gen_next_ev;
        end

    endtask  //run

endclass  //scoreboard

class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    int i;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event gen_next_ev;
    event mon_next_ev;

    function new(virtual adder_interface adder_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, mon_next_ev, adder_if);
        mon = new(mon2scb_mbox, mon_next_ev, adder_if);
        scb = new(mon2scb_mbox, gen_next_ev);

    endfunction  //new()

    task run();
        i = 100; //i 값이 fork join 안에 있으면 동시 실행으로 race condition 발생함 
        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #20; // multitask라서 count값이 업데이트 될 때까지 기다림
        //gen만 끝나고 나오니까 
        $display("______________________________");
        $display("** 32bit Adder Verification **");
        $display("------------------------------");
        $display("** Total test cnt = %3d     **", i);
        $display("** Total pass cnt = %3d     **", scb.pass_cnt);
        $display("** Total fail cnt = %3d     **", scb.fail_cnt);
        $display("------------------------------");

        $stop;
    endtask  //run()
endclass  //environment

module tb_sv_adder ();


    adder_interface adder_if ();

    environment env;

    sv_adder dut (
        .a(adder_if.a),
        .b(adder_if.b),
        .mode(adder_if.mode),
        .s(adder_if.s),
        .c(adder_if.c)
    );

    initial begin
        env = new(adder_if);
        env.run();
    end

endmodule
