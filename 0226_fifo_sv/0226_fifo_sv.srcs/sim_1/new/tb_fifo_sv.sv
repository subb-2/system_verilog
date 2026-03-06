`timescale 1ns / 1ps

interface fifo_interface (
    input logic clk
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

    logic          rst;
    logic          full;
    logic          empty;
    logic    [7:0] rdata;

    function void display(string name);
        $display(
            "%t : [%s] push = %h, wdata = %2h, full = %h, pop = %h, rdata = %2h, empty = %h",
            $time, name, push, wdata, full, pop, rdata, empty);
    endfunction  //new()
endclass  //transaction

class generator;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    // 시나리오 1. empty -> full: fifo를 먼저 가득 채움
    task fill_fifo();
        $display("=== [Scenario 2] Full FIFO ===");
        repeat (16) begin // 주소 깊이가 16이므로 16번 push
            tr = new;
            tr.randomize() with { push == 1; pop == 0; };
            gen2drv_mbox.put(tr);
            tr.display("gen_S1_full");
            @(gen_next_ev);
        end
    endtask

    // 시나리오 2. full -> empty: 가득 찬 fifo를 완전 비움
    task empty_fifo();
        $display("=== [Scenario 4] Empty FIFO ===");
        repeat (16) begin // 16번 pop
            tr = new;
            tr.randomize() with { push == 0; pop == 1; };
            gen2drv_mbox.put(tr);
            tr.display("gen_S2_empty");
            @(gen_next_ev);
        end
    endtask

    // 시나리오 3. full 상태의 fifo에 대해서 동시 입출력 처리
    task test_full_simultaneous();
        $display("=== [Scenario 3] Full Simultaneous ===");
        tr = new;
        tr.randomize() with { push == 1; pop == 1; };
        gen2drv_mbox.put(tr);
        tr.display("gen_S3_simul");
        @(gen_next_ev);
    endtask

    // 시나리오 4. empty 상태의 fifo에 대해서 동시 입출력 처리
    task test_empty_simultaneous();
        $display("=== [Scenario 1] Empty Simultaneous ===");
        tr = new;
        tr.randomize() with { push == 1; pop == 1; };
        gen2drv_mbox.put(tr);
        tr.display("gen_S4_simul");
        @(gen_next_ev);
    endtask

    task run(int run_count);
        // 이미지 주석에 명시된 시나리오 순서: 4 -> 1 -> 3 -> 2 -> 5
        
        // 4. 리셋 직후 empty 상태에서 동시 입출력 테스트
        test_empty_simultaneous(); 
        
        // 1. 그 다음 1을 실행해서 바로 fifo 가득 채움
        fill_fifo();               
        
        // 3. 그 다음 3 실행해서 동시 입출력 테스트
        test_full_simultaneous();  
        
        // 2. 그 다음 2번(이미지 주석의 4번은 2번의 오타로 보임) 실행해서 empty 깨끗이 비움
        empty_fifo();              
        
        // 5. empty 상태로 초기화되었으므로 그다음 무작위 테스트(신뢰성) 진행
        $display("=== [Scenario 5] Random Stress Test ===");
        repeat (run_count) begin
            tr = new;
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.display("gen_S5_rand");
            @(gen_next_ev);
        end

    endtask

    //task run(int run_count);
    //    repeat (run_count) begin
    //        tr = new;
    //        tr.randomize();
    //        //assert (tr.randomize())
    //        //else $display("[gen] tr.randomize() error!!!");
    //        gen2drv_mbox.put(tr);
    //        tr.display("gen");
    //        @(gen_next_ev);
    //    end
    //endtask  //run

endclass  //generator

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual fifo_interface fifo_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual fifo_interface fifo_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task preset();
        fifo_if.rst   = 1;
        fifo_if.wdata = 0;
        fifo_if.push  = 0;
        fifo_if.pop   = 0;
        @(negedge fifo_if.clk);
        @(negedge fifo_if.clk);
        fifo_if.rst = 0;
        @(negedge fifo_if.clk);
        //tr.display("mon_preset");
        //add assertion 
    endtask  //preset

    task push();
        //interface 해주기
        fifo_if.push  = tr.push;
        fifo_if.wdata = tr.wdata;
        fifo_if.pop   = tr.pop;  //push만 하고 싶을 때를 위해 제작 
    endtask  //push

    task pop();
        fifo_if.push  = tr.push;
        fifo_if.wdata = tr.wdata;
        fifo_if.pop   = tr.pop;
    endtask  //pop

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_if.clk);
            #1;
            tr.display("drv");
            if (tr.push) begin
                push();
            end else begin
                fifo_if.push = 0;
            end
            if (tr.pop) begin
                pop();
            end else begin
                fifo_if.pop = 0;
            end
            //fifo_if.wdata = tr.wdata;
            //fifo_if.push  = tr.push;
            //fifo_if.pop   = tr.pop;
        end
    endtask  //run


endclass  //driver

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface fifo_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual fifo_interface fifo_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task run();
        forever begin
            tr = new;
            @(negedge fifo_if.clk);
            tr.push  = fifo_if.push;
            tr.pop   = fifo_if.pop;
            tr.wdata = fifo_if.wdata;
            tr.rdata = fifo_if.rdata;
            tr.full  = fifo_if.full;
            tr.empty = fifo_if.empty;
            tr.display("mon");
            mon2scb_mbox.put(tr);
        end
    endtask  //run

endclass  //monitor

class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    // queue 
    logic [7:0] fifo_queue[$:16];  // size 16으로 지정 
    logic [7:0] compare_data;

    // 💡 패스와 페일 횟수를 저장할 변수 추가
    int pass_cnt;
    int fail_cnt;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
        // 초기화
        this.pass_cnt = 0;
        this.fail_cnt = 0;
    endfunction  //new()

    task run();
        logic actual_push;
        logic actual_pop;

        forever begin
            mon2scb_mbox.get(tr);
            
            if (tr.push && tr.pop) begin
                if (tr.full) begin
                    actual_push = 0; 
                    actual_pop  = 1; 
                end else if (tr.empty) begin
                    actual_push = 1; 
                    actual_pop  = 0; 
                end else begin
                    actual_push = 1; 
                    actual_pop  = 1;
                end
            end else begin
                actual_push = tr.push & (!tr.full);
                actual_pop  = tr.pop & (!tr.empty);
            end

            // 1. 실제 Push 동작
            if (actual_push) begin
                fifo_queue.push_front(tr.wdata);
            end

            // 2. 실제 Pop 동작 및 검증
            if (actual_pop) begin
                compare_data = fifo_queue.pop_back();
                if (compare_data === tr.rdata) begin
                    $display("[PASS] Pop OK! Expected/Actual: %h", tr.rdata);
                    pass_cnt++; // 💡 성공 카운트 1 증가
                end else begin
                    $display("[FAIL] Pop Error! Expected: %h, Actual: %h", compare_data, tr.rdata);
                    fail_cnt++; // 💡 에러 카운트 1 증가
                end
            end
            
            ->gen_next_ev;
        end
    endtask  //run

endclass  //scoreboard

//class scoreboard;
//
//    transaction tr;
//    mailbox #(transaction) mon2scb_mbox;
//    event gen_next_ev;
//
//    //queue 
//    logic [7:0] fifo_queue[$:16];  //size 지정 안하면 무한대 
//    logic [7:0] compare_data;
//
//    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
//        this.mon2scb_mbox = mon2scb_mbox;
//        this.gen_next_ev  = gen_next_ev;
//    endfunction  //new()
//
//    task run();
//        forever begin
//            mon2scb_mbox.get(tr);
//            tr.display("scb");
//            // push : 데이터 들어가는 것 판별 불가 
//            if (tr.push & (!tr.full)) begin
//                fifo_queue.push_front(tr.wdata);
//            end
//            // pop : data나옴 : pop할 때 판별 
//            if (tr.pop & (!tr.empty)) begin
//                //pass/fail
//                compare_data = fifo_queue.pop_back();
//                if (compare_data == tr.rdata) begin
//                    $display("pass");
//                end else begin
//                    $display("fail");
//                end
//            end
//            ->gen_next_ev;
//        end
//    endtask  //run
//
//endclass  //scorboard

class environment;
    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event gen_next_ev;

    function new(virtual fifo_interface fifo_if);
        gen2drv_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, gen_next_ev);
        drv = new(gen2drv_mbox, fifo_if);
        mon = new(mon2scb_mbox, fifo_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task  run();
        drv.preset();
        fork
            gen.run(10); // 랜덤 테스트 256번 수행
            drv.run();
            mon.run();
            scb.run();
        join_any
        
        disable fork; 
        
        #10;
        // 💡 최종 결산 출력 
        $display("\n========================================");
        $display("   [ TEST REPORT ] SIMULATION FINISHED! ");
        $display("----------------------------------------");
        $display("   Total PASS Count : %0d", scb.pass_cnt);
        $display("   Total FAIL Count : %0d", scb.fail_cnt);
        
        if (scb.fail_cnt == 0) begin
            $display("   Result : PERFECT SUCCESS! ");
        end else begin
            $display("   Result : DESIGN HAS BUGS! ");
        end
        $display("========================================\n");
        $stop;
    endtask 

endclass  //environment

module tb_fifo_sv ();

    logic clk;

    fifo_interface fifo_if (clk);
    environment env;

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

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(fifo_if);
        env.run();
    end

endmodule
