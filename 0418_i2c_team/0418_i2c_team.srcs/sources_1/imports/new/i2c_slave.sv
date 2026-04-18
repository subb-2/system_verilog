`timescale 1ns / 1ps

module i2c_slave (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done,
    input  logic       scl,
    inout  logic       sda
);

    localparam logic [6:0] SLAVE_ADDR = 7'h12;

    typedef enum logic [2:0] {
        IDLE,
        ADDR,
        ADDR_ACK,
        WRITE_DATA,
        DATA_ACK
    } i2c_state_e;

    i2c_state_e state;

    logic       sda_o;
    logic       sda_i;
    logic       scl_d;
    logic       sda_d;
    logic       scl_rise;
    logic       scl_fall;
    logic       sda_rise;
    logic       sda_fall;
    logic [7:0] shift_reg;
    logic [7:0] shift_next;
    logic [2:0] bit_cnt;

    assign sda_i      = sda;
    assign sda        = sda_o ? 1'bz : 1'b0;
    assign scl_rise   = ~scl_d & scl;
    assign scl_fall   = scl_d & ~scl;
    assign sda_rise   = ~sda_d & sda_i;
    assign sda_fall   = sda_d & ~sda_i;
    assign shift_next = {shift_reg[6:0], sda_i};

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            scl_d     <= 1'b1;
            sda_d     <= 1'b1;
            state     <= IDLE;
            sda_o     <= 1'b1;
            shift_reg <= 8'h00;
            rx_data   <= 8'h00;
            bit_cnt   <= 3'd0;
            done      <= 1'b0;
        end else begin
            scl_d <= scl;
            sda_d <= sda_i;
            done  <= 1'b0;

            if (sda_o && sda_fall && scl) begin
                state     <= ADDR;
                sda_o     <= 1'b1;
                shift_reg <= 8'h00;
                bit_cnt   <= 3'd0;
            end else if (sda_rise && scl) begin
                state   <= IDLE;
                sda_o   <= 1'b1;
                bit_cnt <= 3'd0;
            end else begin
                case (state)
                    IDLE: begin
                        sda_o <= 1'b1;
                    end

                    ADDR: begin
                        if (scl_rise) begin
                            shift_reg <= shift_next;

                            if (bit_cnt == 3'd7) begin
                                bit_cnt <= 3'd0;
                                if ((shift_next[7:1] == SLAVE_ADDR) && (shift_next[0] == 1'b0)) begin
                                    state <= ADDR_ACK;
                                end else begin
                                    state <= IDLE;
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end

                    ADDR_ACK: begin
                        if (scl_fall) begin
                            if (sda_o) begin
                                sda_o <= 1'b0;
                            end else begin
                                sda_o     <= 1'b1;
                                shift_reg <= 8'h00;
                                bit_cnt   <= 3'd0;
                                state     <= WRITE_DATA;
                            end
                        end
                    end

                    WRITE_DATA: begin
                        if (scl_rise) begin
                            shift_reg <= shift_next;
                            if (bit_cnt == 3'd7) begin
                                rx_data <= shift_next;
                                done    <= 1'b1;
                            end
                        end

                        if (scl_fall) begin
                            if (bit_cnt == 3'd7) begin
                                bit_cnt <= 3'd0;
                                sda_o   <= 1'b0;
                                state   <= DATA_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end

                    DATA_ACK: begin
                        sda_o <= 1'b0;
                        if (scl_fall) begin
                            sda_o     <= 1'b1;
                            shift_reg <= 8'h00;
                            bit_cnt   <= 3'd0;
                            state     <= WRITE_DATA;
                        end
                    end

                    default: begin
                        state <= IDLE;
                        sda_o <= 1'b1;
                    end
                endcase
            end
        end
    end

endmodule
