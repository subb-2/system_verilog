`timescale 1ns / 1ps

module tb_fifo_v();

reg clk, rst, push, pop;
reg [7:0] wdata;
wire [7:0] rdata;
wire full, empty;

reg rand_pop, rand_push;
reg [7:0] rand_data;
reg [7:0] compare_data[0:15];
reg [3:0] push_cnt, pop_cnt;
//random pop 1일 때마다 비교 판단 

integer i, pass_cnt, fail_cnt;

fifo_sv dut (
    .clk(clk),
    .rst(rst),
    .push(push),
    .pop(pop),
    .wdata(wdata),
    .rdata(rdata),
    .full(full),
    .empty(empty)
);

    always #5 clk = ~clk;
    
    initial begin
        #0;
        clk = 0;
        rst = 1;
        wdata = 0;
        push = 0;
        pop = 0;
        
        i = 0;
        pass_cnt = 0;
        fail_cnt = 0;
        rand_data = 0;
        rand_pop = 0;
        rand_push = 0;

        push_cnt = 0;
        pop_cnt = 0;

        //timing 은 negative edge
        @(negedge clk);
        @(negedge clk);
        rst = 0;
        
        //push 5times 
        for (i = 0;i <= 16 ;i = i + 1 ) begin
           push = 1;
           wdata = 8'h61 + i; //'a'
           @(negedge clk);
        end
        push = 0;

        //pop 5times 
        for (i = 0;i <= 16 ;i = i + 1 ) begin
           pop = 1;
           @(negedge clk);
        end
        pop = 0;

        //push
        push = 1;
        wdata = 8'haa;
        @(negedge clk);
        push = 0;
        @(negedge clk);

        for (i = 0;i < 16 ;i = i + 1 ) begin
            push = 1;
            pop = 1;
            wdata = i;
            @(negedge clk);
        end        

        push = 0;
        pop = 1;

        @(negedge clk);
        @(negedge clk);
        pop = 0;
        @(negedge clk);

        for (i = 0;i < 256 ;i = i + 1 ) begin
            //random test
            rand_push = $random % 2;
            rand_pop = $random % 2; //%256 : 0~255까지 나옴
            rand_data = $random % 256; // random data 가 8bit 이니까 

            push = rand_push;
            wdata = rand_data;
            pop = rand_pop;

            #4;

            if (!full & push) begin
                compare_data[push_cnt] = rand_data;
                push_cnt = push_cnt + 1;
            end

            if (!empty & pop == 1) begin
               if (rdata == compare_data[pop_cnt]) begin
                  $display("%t : Pass , rdata = %h, compare data = %h" , 
                        $time, rdata, compare_data[pop_cnt]);
                        pass_cnt = pass_cnt + 1;
               end else begin
                $display("%t : Fail!!!!!, rdata = %h, compare data = %h", 
                        $time, rdata, compare_data[pop_cnt]);
                        fail_cnt = fail_cnt + 1;
               end
               pop_cnt = pop_cnt + 1;
            end
            
            @(negedge clk);

        end

        $display ("%t : pass count = %d, fail count = %d", $time, pass_cnt, fail_cnt);

        
        repeat(5) @(negedge clk);
        
        $stop;
    end

endmodule
