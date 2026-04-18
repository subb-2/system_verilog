`timescale 1ns / 1ps

module top_i2c (
    input  logic       clk,
    input  logic       rst,
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] m_tx_data,
    output logic [7:0] m_rx_data,
    output logic       done
);

    logic [7:0] s_tx_data;
    logic [7:0] s_rx_data;
    logic       s_done;
    logic       ack_in;
    logic       ack_out;
    logic       busy;
    logic       scl;
    wire        sda;

    assign ack_in    = 1'b1;
    assign s_tx_data = 8'h00;

    pullup (sda);

    I2C_Master_top U_I2C_MASTER_TOP (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (m_tx_data),
        .ack_in   (ack_in),
        .rx_data  (m_rx_data),
        .done     (done),
        .ack_out  (ack_out),
        .busy     (busy),
        .scl      (scl),
        .sda      (sda)
    );

    i2c_slave U_I2C_SLAVE (
        .clk    (clk),
        .rst    (rst),
        .tx_data(s_tx_data),
        .rx_data(s_rx_data),
        .done   (s_done),
        .scl    (scl),
        .sda    (sda)
    );

endmodule
