`timescale 1ns / 1ps

interface ram_if (
    input logic clk
);
    logic       we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface  //ram_if

//class 는 sw로, sw가 hw를 test하는 코드로 변화한 것 
class test;

    virtual ram_if r_if;


    function new(virtual ram_if r_if);
        this.r_if = r_if;
    endfunction  //new()

    virtual task write(logic [7:0] waddr, logic [7:0] data);
        r_if.we    = 1;
        r_if.addr  = waddr;
        r_if.wdata = data;
        @(posedge r_if.clk);
    endtask
    //
    virtual task read(logic [7:0] raddr);
        r_if.we   = 0;
        r_if.addr = raddr;
        @(posedge r_if.clk);
    endtask
endclass  //test

class test_burst extends test; // test 기능을 유지하면서 확장하겠다는 의미 

    function new(virtual ram_if r_if);
        super.new(
            r_if); //부모 class 의 new를 말하는 것  super = 부모 class 
    endfunction  //new()

    task write_burst(logic [7:0] waddr, logic [7:0] data,
                     int len);  //재정의 
        //주소, 데이터, 몇개를 할 것이냐
        for (int i = 0; i < len; i++) begin
            super.write(waddr, data);  //부모 class의 write 사용 
            waddr++;
        end
    endtask  //write_burst

    task write(logic [7:0] waddr, logic [7:0] data);
        r_if.we    = 1;
        r_if.addr  = waddr + 1;
        r_if.wdata = data;
        @(posedge r_if.clk);
    endtask  //write
endclass  //test_burst extends test

class transaction;
    logic            we;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic      [7:0] rdata;

    constraint c_addr {
        addr inside {[8'h00:8'h10]};
    }

    constraint c_wdata {
        wdata inside {[8'h10:8'h20]};
    }

    function print(string name);
        $display("[name] we : %0d, addr : 0x%0x, wdata : 0x%0x, rdata : 0x%0x",
                 name, we, addr, wdata, rdata);
    endfunction  //new()
endclass  //transaction

class test_rand extends test;
    transaction tr; //stack 영역에 메모리 공간 잡힘 

    function new(virtual ram_if r_if);
        super.new(r_if);
    endfunction

    task write_rand(int loop);
        repeat (loop) begin
            tr = new(); // heap 영역에 class 코드가 잡힘 실체화 시키면서 메모리 공간 잡음 
            tr.randomize();
            r_if.we    = 1;
            r_if.addr  = tr.addr; //tr 멤버인 addr 값을 인터페이스의 addr 값으로 넣는다는 의미
            r_if.wdata = tr.wdata;
            @(posedge r_if.clk);
        end
    endtask  //write_rand

endclass


module tb_ram ();
    logic clk;
    test  BTS; //test는 객체가 아니라, 객체를 만들기 위한 조건 , BTS가 객체 
    test_rand BlackPink;

    ram_if r_if (clk);

    //test target 
    //sw가 hw인 dut에 신호를 줘야함
    //이때 interface 사용 
    ram dut (
        .clk(r_if.clk),
        .we(r_if.we),
        .addr(r_if.addr),
        .wdata(r_if.wdata),
        .rdata(r_if.rdata)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    //write 요소들을 하나로 묶음 
    //task write(logic [7:0] waddr, logic [7:0] data);
    //    we    = 1;
    //    addr  = waddr;
    //    wdata = data;
    //    @(posedge clk);
    //endtask
    //
    //task read(logic [7:0] raddr);
    //    we    = 0;
    //    addr  = raddr;
    //    @(posedge clk);
    //endtask

    initial begin
        repeat (5) @(posedge clk);  //clk 5번 기다림
        //write 하고 싶음
        //ram_write(8'h00, 8'h01); 
        // 코드도 줄어들고 역할도 알 수 있게 됨
        //하나의 추상화
        //ram_write(8'h01, 8'h02); 
        //ram_write(8'h02, 8'h03); 
        //ram_write(8'h03, 8'h04); 
        //
        //ram_read(8'h00);
        //ram_read(8'h01);
        //ram_read(8'h02);
        //ram_read(8'h03);

        BTS = new(r_if);
        BlackPink = new(r_if);
        $display("addr = 0x%0h", BTS);
        $display("addr = 0x%0h", BlackPink);
        BTS.write(8'h00, 8'h01);
        BTS.write(8'h01, 8'h02);
        BTS.write(8'h02, 8'h03);
        BTS.write(8'h03, 8'h04);

        BlackPink.write_rand(10);  //새로운 기능 추가 

        BTS.read(8'h00);
        BTS.read(8'h01);
        BTS.read(8'h02);
        BTS.read(8'h03);

        #20;
        $finish;
    end

endmodule
