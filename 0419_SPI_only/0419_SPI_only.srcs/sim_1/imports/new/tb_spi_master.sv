`timescale 1ns / 1ps

module tb_spi_master ();

    //logic clk, rst;
    //logic cpol, cpha;
    //logic [7:0] clk_div, tx_data, rx_data;
    //logic start, done, busy, sclk, mosi, miso, cs_n;

    logic       clk;
    logic       rst;
    logic       cpol;
    logic       cpha;
    logic [7:0] clk_div;
    logic       m_start;
    logic [7:0] m_tx_data;
    logic [7:0] m_rx_data;
    logic       m_done;
    logic       m_busy;
    logic [7:0] s_tx_data;
    logic [7:0] s_rx_data;
    logic       s_rx_done;

    spi_top dut (
        .clk      (clk),
        .rst      (rst),
        .cpol     (cpol),
        .cpha     (cpha),
        .clk_div  (clk_div),
        .m_start  (m_start),
        .m_tx_data(m_tx_data),
        .m_rx_data(m_rx_data),
        .m_done   (m_done),
        .m_busy   (m_busy),
        .s_tx_data(s_tx_data),
        .s_rx_data(s_rx_data),
        .s_rx_done(s_rx_done)
    );

    //spi_master dut (
    //    .clk(clk),
    //    .rst(rst),
    //    .cpol(cpol),
    //    .cpha(cpha),
    //    .clk_div(clk_div),
    //    .tx_data(tx_data),
    //    .start(start),
    //    .rx_data(rx_data),
    //    .done(done),
    //    .busy(busy),
    //    .sclk(sclk),
    //    .mosi(mosi),
    //    .miso(miso),
    //    .cs_n(cs_n)
    //);

    always #5 clk = ~clk;

    //loop 
    //assign miso = mosi;

    task spi_set_mode(logic [1:0] mode);
        {cpol, cpha} = mode;
        @(posedge clk);
    endtask  //spi_set_mode

    task spi_send_data(logic [7:0] m_data, logic [7:0] s_data);
        m_tx_data = m_data;
        s_tx_data = s_data;
        m_start   = 1'b1;
        @(posedge clk);
        m_start = 1'b0;
        @(posedge clk);
        wait (m_done);
        @(posedge clk);
    endtask  //spi_send

    initial begin
        clk = 0;
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        clk_div = 4;  // sclk = 10MHz : (100MHz / (10MHz * 2)) - 1
        //miso = 1'b0;
        @(posedge clk);

        spi_set_mode(0);
        spi_send_data(8'h55, 8'haa);

        spi_set_mode(0);
        spi_send_data(8'h12, 8'h34);

        spi_set_mode(0);
        spi_send_data(8'hFF, 8'hcc);

        spi_set_mode(0);
        spi_send_data(8'ha5, 8'h5a);

        @(posedge clk);
        #60;
        $stop;
    end

endmodule
