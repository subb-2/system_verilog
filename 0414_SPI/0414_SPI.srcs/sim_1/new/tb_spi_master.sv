`timescale 1ns / 1ps

module tb_spi_master ();

    logic clk, rst;
    logic [7:0] clk_div, tx_data, rx_data;
    logic start, done, busy, sclk, mosi, miso, cs_n;

    spi_master dut (
        .clk(clk),
        .rst(rst),
        .clk_div(clk_div),
        .tx_data(tx_data),
        .start(start),
        .rx_data(rx_data),
        .done(done),
        .busy(busy),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs_n(cs_n)
    );

    always #5 clk = ~clk;

    //loop 
    assign miso = mosi;

    initial begin
        clk = 0;
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        clk_div = 4;
        //miso = 1'b0;
        @(posedge clk);
        //한 번만 보냄 
        tx_data = 8'haa;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        @(posedge clk);
        wait(done);

        @(posedge clk);
        tx_data = 8'h55;
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        @(posedge clk);
        wait(done);

        @(posedge clk);
        #20;
        $stop;
    end

endmodule
