`timescale 1ns / 1ps

module tb_i2c_Top ();

    logic clk, rst, cmd_start, cmd_write, cmd_read, cmd_stop;
    logic ack_in, done, ack_out, busy, scl;
    logic [7:0] tx_data, rx_data;
    wire sda;

    I2C_Master_top dut (
        .*,
        .scl(scl),
        .sda(sda)
    );

    //pull up 저항 나타낸 것?
    //assign scl = 1'b1;
    //assign sda = 1'b1;

    //slave addr 
    localparam SLA = 8'h12;

    always #5 clk = ~clk;

    task i2c_start ();
        //Start 
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        //done이 오면, start 끝난 것 
        wait (done);
        @(posedge clk);
    endtask //i2c_start

    task i2c_addr (byte addr);
        //tx_data = Address(8'h12) + read or write
        //shift 1번 하고 rw 넣기
        tx_data = addr; 
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read = 1'b0;
        cmd_stop = 1'b0;
        @(posedge clk);
        //ack 까지 다 받은 done 
        wait (done);  //wait ack 
        @(posedge clk);
    endtask //i2c_write

    task i2c_write (byte data);
        // tx_data = data (실제 데이터 보내기)
        tx_data   = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  //wait ack 
        @(posedge clk);
    endtask //i2c_write

    task i2c_read ();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  //wait ack 
        @(posedge clk);
    endtask //i2c_read

    task i2c_stop ();
        //stop
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask //i2c_stop

    initial begin
        clk = 0;
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        i2c_start();
        i2c_addr(SLA << 1 + 1'b0);
        i2c_write(8'h55);
        i2c_write(8'haa);
        i2c_write(8'h01);
        i2c_write(8'h02);
        i2c_write(8'h03);
        i2c_write(8'h04);
        i2c_write(8'h05);
        i2c_write(8'h06);
        i2c_write(8'hff);
        i2c_stop();

        //IDLE state
        #100;
        $finish;

    end

endmodule
