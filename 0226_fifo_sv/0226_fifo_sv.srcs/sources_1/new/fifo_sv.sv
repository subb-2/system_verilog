`timescale 1ns / 1ps

module fifo_sv (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] wdata,
    input  logic       push,
    input  logic       pop,
    output logic       full,
    output logic       empty,
    output logic [7:0] rdata
);

    logic [1:0] w_wptr, w_rptr;

    register_file U_REGISTER_FILE (
        .clk  (clk),
        .wdata(wdata),  //push
        .waddr(w_wptr),
        .we ((~full) & push),
        .raddr(w_rptr),  //pop
        .rdata(rdata)
    );

    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .push(push),
        .pop(pop),
        .wptr(w_wptr),
        .rptr(w_rptr),
        .full(full),
        .empty(empty)
);


endmodule

//register file
module register_file (
    input  logic       clk,
    input  logic [7:0] wdata,  //push
    input  logic [1:0] waddr,
    input  logic       we,
    input  logic [1:0] raddr,  //pop
    output logic [7:0] rdata
);

    //ram
    logic [7:0] register_file[0:3];

    always_ff @(posedge clk) begin
        if (we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata = register_file[raddr];


endmodule

//control unit 
module control_unit (
    input  logic       clk,
    input  logic       rst,
    input  logic       push,
    input  logic       pop,
    output logic [1:0] wptr,
    output logic [1:0] rptr,
    output logic       full,
    output logic       empty
);

    //state 선언
    logic [1:0] c_state, n_state;
    logic [1:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
    logic full_reg, full_next, empty_reg, empty_next;

    assign wptr  = wptr_reg;
    assign rptr  = rptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state   <= 2'd0;
            wptr_reg  <= 1'b0;
            rptr_reg  <= 1'b0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            c_state    <= n_state;
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin
        n_state = c_state;
        wptr_next = wptr_reg;
        rptr_next = rptr_reg;
        full_next = full_reg;
        empty_next = empty_reg;

        case ({
            push, pop
        })
            //push 
            2'b10: begin
                if (!full) begin
                    wptr_next++;
                    empty_next = 0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1;
                    end
                end
            end
            //pop
            2'b01: begin
                if (!empty) begin
                    rptr_next++;
                    full_next = 0;
                    if (rptr_next == wptr_reg) begin
                        empty_next = 1;
                    end
                end
            end
            //push & pop
            2'b11: begin
                if (full) begin
                    rptr_next++;
                    full_next = 0;
                end else if (empty) begin
                    wptr_next++;
                    empty_next = 0;
                end else begin
                    wptr_next++;
                    rptr_next++;
                end
            end

        endcase

    end


endmodule
