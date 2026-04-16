`timescale 1ns / 1ps

module top (
    input  logic       clk,
    input  logic       rst,
    input  logic       t_idle,
    input  logic       ibtn,
    input  logic       sclk,
    input  logic       cs_n,
    input  logic       mosi,
    output logic       miso,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);

    logic [7:0] slave_tx_data;

    logic [7:0] master_rx_data;
    logic       master_done;
    logic       master_busy;
    logic [7:0] slave_rx_data;
    logic       slave_done;
    logic       slave_busy;

    logic       cpol;
    logic       cpha;
    //logic [7:0] clk_div;
    logic [7:0] master_tx_data;
    logic       master_start;

    logic       obtn;
    logic       osbtn;
    logic       sdone;
    logic [2:0] bit_cnt;
    logic [7:0] s_tx_data;
    logic [7:0] sw_data;

    SPI_slave u_slave (
        .clk    (clk),
        .sclk   (sclk),
        .rst    (rst),
        .mosi   (mosi),
        .tx_data(slave_tx_data),
        .rx_data(slave_rx_data),
        .miso   (miso),
        .cs_n   (cs_n),
        .sdone  (sdone),
        .t_idle (t_idle),
        .bit_cnt(bit_cnt)
    );


    fnd_controller u_fnd (
        .sum      (slave_rx_data),
        .btn      (),
        .clk      (clk),
        .rst      (rst),
        .done     (sdone),
        .ibtn     (obtn),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    btn_debounce u_btn_debounce_addr (
        .clk  (clk),
        .reset(rst),
        .i_btn(ibtn),
        .o_btn(obtn)
    );
endmodule

module btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);


    // clock divider for debounce shift register
    // 100MHZ -> 100khz
    // counter -> 100M/100K = 1000
    parameter CLK_DIV = 1000_000;
    parameter F_COUNT = 100_000_000 / CLK_DIV;
    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg clk_100khz_reg;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            clk_100khz_reg <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                clk_100khz_reg <= 1'b1;
            end else begin
                clk_100khz_reg <= 1'b0;
            end
        end
    end

    //series 8 tap F/F
    //1 reg [7:0] debounce_reg;
    reg [7:0] q_reg, q_next;
    wire debounce;

    //SL
    always @(posedge clk_100khz_reg, posedge reset) begin
        if (reset) begin
            //1 debounce_reg <= 0;
            q_reg <= 0;
        end else begin
            //shift register
            //1  debounce_reg <= {i_btn, debounce_reg[7:1]}
            q_reg <= q_next;
        end
    end

    //next CL
    always @(*) begin
        q_next = {i_btn, q_reg[7:1]};
    end

    //debounce, 8input AND
    assign debounce = &q_reg;

    reg edge_reg;
    //edge detection
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end
    assign o_btn = debounce & {~edge_reg};

endmodule


