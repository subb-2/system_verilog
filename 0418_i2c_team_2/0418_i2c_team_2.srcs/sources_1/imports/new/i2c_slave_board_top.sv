`timescale 1ns / 1ps

module i2c_slave_board_top (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] sw,
    input  logic        scl,
    inout  wire         sda,
    output logic [3:0]  fnd_digit,
    output logic [7:0]  fnd_data
);

    logic [7:0] rx_data;
    logic       rx_done;
    logic       rx_valid;
    logic [13:0] fnd_in_data;

    assign fnd_in_data = rx_valid ? {6'd0, rx_data} : 14'd0;

    i2c_slave U_I2C_SLAVE (
        .clk    (clk),
        .rst    (rst),
        .tx_data(8'h00),
        .rx_data(rx_data),
        .done   (rx_done),
        .scl    (scl),
        .sda    (sda)
    );

    fnd_controller U_FND_CONTROLLER (
        .clk        (clk),
        .reset      (rst),
        .fnd_in_data(fnd_in_data),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            rx_valid <= 1'b0;
        end else if (rx_done) begin
            rx_valid <= 1'b1;
        end
    end

endmodule
