`timescale 1ns / 1ps

module slave_top (
    input  logic       clk,
    input  logic       rst,
    input  logic       btn,
    input  logic       sclk,
    input  logic       cs_n,
    input  logic       mosi,
    output logic       miso,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);

    logic rx_done;

    logic [7:0] rx_data, tx_data;

    fnd_unit U_FND_UNIT (
        .clk(clk),
        .rst(rst),
        .btn(btn),
        .rx_done(rx_done),
        .rx_data(rx_data),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );

    spi_slave U_SPI_SLAVE (
        .clk(clk),
        .rst(rst),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        //.busy(busy),
        .cs_n(cs_n),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    btn_debounce U_BTN_DEBOUNCE (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn),
        .o_btn(o_btn)
    );
endmodule
