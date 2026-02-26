`timescale 1ns / 1ps

module register_8bit (
    input              clk,
    input              rst,
    input  logic       we,
    input  logic [7:0] wdata,
    output logic [7:0] rdata
);

    always_ff @(posedge clk, posedge rst) begin : register_8
        //blockname은 event, sim 제어에 사용
        if (rst) begin
            rdata <= 8'd0;
        end else begin
            if (we) begin
                rdata <= wdata;
            end
        end
    end
endmodule
