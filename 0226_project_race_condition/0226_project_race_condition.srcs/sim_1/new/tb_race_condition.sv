`timescale 1ns / 1ps

module tb_race_condition();

    logic p, q;

    assign p = q; //0

    initial begin
        q = 1;
        #1; 
        q = 0;
        $display("%d", p); 
        //q = 0도 1ns이고 display도 1ns이기 때문에 0이 나올 수도 있고 1이 나올 수도 있음
        //race condition 
        //display는 assign과 동시 실행이기 때문에 race condition 발생 
        $stop;
    end

endmodule
