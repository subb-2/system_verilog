`timescale 1ns / 1ps

module tb_i2c_Top ();

    //logic clk, rst, cmd_start, cmd_write, cmd_read, cmd_stop;
    //logic ack_in, done, ack_out, busy, scl;
    //logic [7:0] m_tx_data, m_rx_data;
    //logic [7:0] s_tx_data, s_rx_data;
    ////wire sda;
    //tri1 sda;

    logic       clk;
    logic       rst;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] m_tx_data;
    logic [7:0] m_rx_data;
    logic       done;
    logic [7:0] s_tx_data;
    logic [7:0] s_rx_data;

    top_i2c dut (
        .clk(clk),
        .rst(rst),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read(cmd_read),
        .cmd_stop(cmd_stop),
        .m_tx_data(m_tx_data),
        .m_rx_data(m_rx_data),
        .s_tx_data(s_tx_data),
        .s_rx_data(s_rx_data),
        .done(done)
    );

    //    I2C_Master_top dut (
    //        .*,
    //        .tx_data(m_tx_data),
    //        .rx_data(m_rx_data),
    //        .scl(scl),
    //        .sda(sda)
    //    );
    //
    //    i2c_slave dut_s (
    //        .clk(clk),
    //        .rst(rst),
    //        .tx_data(s_tx_data),
    //        .rx_data(s_rx_data),
    //        .scl(scl),
    //        .sda(sda)
    //    );

    //pull up 저항 나타낸 것?
    //assign scl = 1'b1;
    //assign sda = 1'b1;

    //slave addr 
    localparam SLA = 8'h12;

    always #5 clk = ~clk;

    task i2c_start();
        //Start 
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        //done이 오면, start 끝난 것 
        wait (done);
        @(posedge clk);
    endtask  //i2c_start

    task i2c_addr(byte addr);
        //tx_data = Address(8'h12) + read or write
        //shift 1번 하고 rw 넣기
        m_tx_data = addr;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        //ack 까지 다 받은 done 
        wait (done);  //wait ack 
        @(posedge clk);
    endtask  //i2c_write

    task i2c_write(byte data);
        // tx_data = data (실제 데이터 보내기)
        m_tx_data = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  //wait ack 
        @(posedge clk);
    endtask  //i2c_write

    task i2c_read(byte data);
        s_tx_data = data;
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);  //wait ack 
        @(posedge clk);
    endtask  //i2c_read

    task i2c_stop();
        //stop
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask  //i2c_stop

    initial begin
        clk = 0;
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        i2c_start();
        i2c_addr((SLA << 1) + 1'b0);
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

        i2c_start();
        i2c_addr((SLA << 1) + 1'b1);  // R/W = 1 (Read)
        i2c_read(8'h55);
        i2c_read(8'haa);
        i2c_read(8'h01);
        i2c_read(8'h02);
        i2c_read(8'h03);
        i2c_read(8'h04);
        i2c_read(8'h05);
        i2c_read(8'h06);
        i2c_read(8'hff);
        i2c_stop();

        //IDLE state
        #100;
        $finish;

    end

endmodule
