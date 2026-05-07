`include "defines.v"

module Divider (
    input wire                  i_Clk,
    input wire                  i_reset,

    // from ctrl
    input wire                  i_div_result_accept,

    // I/O with EX
    input wire[`DataBus]        i_dividend_data,
    input wire[`DataBus]        i_divisor_data,
    input wire                  i_div_valid,
    input wire                  i_div_signed,
    output reg[`DataBus]        o_quotient_data,
    output reg[`DataBus]        o_remainder_data,
    output reg                  o_div_ready
);

    localparam S_IDLE = 2'b00;
    localparam S_RUN  = 2'b01;
    localparam S_DONE = 2'b10;

    reg [1:0]  r_state;

    reg [5:0]  r_count;        // Need 0 to 31 for 32 iterations

    reg [31:0] r_divisor_abs;
    reg [63:0] r_rem_quot;     // upper 32 bits: remainder, lower 32 bits: quotient

    reg        r_quotient_neg;
    reg        r_remainder_neg;

    // Temporary variable used inside sequential block
    reg [63:0] shifted;

    // Absolute value helper
    function [31:0] abs32;
        input [31:0] value;
        input        is_signed;
        begin
            if (is_signed && value[31])
                abs32 = ~value + 32'd1;
            else
                abs32 = value;
        end
    endfunction

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            r_state            <= S_IDLE;
            r_count            <= 6'd0;
            r_divisor_abs      <= 32'd0;
            r_rem_quot         <= 64'd0;
            r_quotient_neg     <= 1'b0;
            r_remainder_neg    <= 1'b0;

            o_quotient_data    <= 32'd0;
            o_remainder_data   <= 32'd0;
            o_div_ready <= 1'b0;
        end
        else begin
            case (r_state)
                S_IDLE: begin           // Wait for start
                    o_div_ready <= 1'b0;

                    if (i_div_valid) begin

                        // Divide by zero
                        if (i_divisor_data == 32'd0) begin
                            o_quotient_data    <= 32'hffff_ffff;
                            o_remainder_data   <= i_dividend_data;
                            o_div_ready <= 1'b1;
                            r_state            <= S_DONE;
                        end

                        // Overflow
                        else if (
                            i_div_signed &&
                            (i_dividend_data == 32'h8000_0000) &&
                            (i_divisor_data  == 32'hffff_ffff)
                        ) begin
                            o_quotient_data    <= 32'h8000_0000;
                            o_remainder_data   <= 32'd0;
                            o_div_ready <= 1'b1;
                            r_state            <= S_DONE;
                        end

                        // Normal division
                        else begin
                            r_count         <= 6'd0;

                            r_divisor_abs   <= abs32(i_divisor_data, i_div_signed);

                            // r_rem_quot starts as:
                            // upper 32 bits = 0
                            // lower 32 bits = absolute dividend
                            r_rem_quot      <= {32'd0, abs32(i_dividend_data, i_div_signed)};

                            // Quotient sign:
                            // negative if signed division and operands have opposite signs
                            r_quotient_neg  <= i_div_signed &&
                                               (i_dividend_data[31] ^ i_divisor_data[31]);

                            // Remainder sign:
                            // same sign as dividend
                            r_remainder_neg <= i_div_signed && i_dividend_data[31];

                            o_div_ready <= 1'b0;
                            r_state            <= S_RUN;
                        end
                    end
                end

                // 32-cycle shift-subtract division
                S_RUN: begin
                    o_div_ready <= 1'b0;

                    // Shift left by 1. This shifts the next dividend bit into the remainder region,
                    // and creates space for the next quotient bit at bit 0.
                    shifted = {r_rem_quot[62:0], 1'b0};

                    // If current remainder >= divisor:
                    // remainder = remainder - divisor
                    // quotient bit = 1
                    if (shifted[63:32] >= r_divisor_abs) begin
                        shifted[63:32] = shifted[63:32] - r_divisor_abs;
                        shifted[0]     = 1'b1;
                    end

                    r_rem_quot <= shifted;

                    // After 32 iterations, division is complete
                    if (r_count == 6'd31) begin
                        r_count <= 6'd0;
                        r_state <= S_DONE;

                        // Apply quotient sign
                        if (r_quotient_neg)
                            o_quotient_data <= ~shifted[31:0] + 32'd1;
                        else
                            o_quotient_data <= shifted[31:0];

                        // Apply remainder sign
                        if (r_remainder_neg)
                            o_remainder_data <= ~shifted[63:32] + 32'd1;
                        else
                            o_remainder_data <= shifted[63:32];

                        o_div_ready <= 1'b1;
                    end
                    else begin
                        r_count <= r_count + 6'd1;
                    end
                end

                S_DONE: begin
                    o_div_ready <= 1'b1;

                    if (i_div_result_accept) begin
                        o_div_ready <= 1'b0;
                        r_state     <= S_IDLE;
                    end
                end

                default: begin
                    r_state <= S_IDLE;
                end

            endcase
        end
    end

endmodule