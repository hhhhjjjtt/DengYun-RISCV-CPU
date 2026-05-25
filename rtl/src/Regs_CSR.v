`include "defines.v"

module Regs_CSR (
    input wire                  i_Clk,
	input wire                  i_reset,
    
	// from EX
	input wire                  i_ex_csr_wr_en,
	input wire[`CSRAddrBus]     i_ex_csr_wr_addr,
	input wire[`DataBus]        i_ex_csr_wr_data,

    // I/O with ID
    input wire[`CSRAddrBus]     i_id_csr_rd_addr,                    
	output reg[`DataBus]        o_id_csr_rd_data,

	// I/O with Trap_Unit, read
    input wire[`DataAddrBus]    i_trap_csr_rd_addr,
	output reg[`DataBus]        o_trap_csr_rd_data,
    // I/O with Trap_Unit, write
    input wire                  i_trap_csr_wr_en,
    input wire[`DataAddrBus]    i_trap_csr_wr_addr,
    input wire[`DataBus]        i_trap_csr_wr_data,
    // to Trap_Unit
	output reg[`DataBus]        o_csr_mtvec,
    output reg[`DataBus]        o_csr_mepc,
    output reg[`DataBus]        o_csr_mie,
    output reg[`DataBus]        o_csr_mstatus,
	output reg                  o_global_int_en
);

    reg [63:0] cycle;

    reg [`DataBus] mtvec;
    reg [`DataBus] mcause;
    reg [`DataBus] mepc;
    reg [`DataBus] mie;
    reg [`DataBus] mstatus;
    reg [`DataBus] mscratch;

    always @(*) begin
        o_csr_mtvec     = mtvec;
        o_csr_mepc      = mepc;
        o_csr_mie       = mie;
        o_csr_mstatus   = mstatus;
        o_global_int_en = mstatus[3];
    end

    // cycle counter
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset == `Enable) begin
            cycle <= 64'b0;
        end else begin
            cycle <= cycle + 64'b1;
        end
    end

    // CSR write
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            mtvec    <= `ZeroWord;
            mcause   <= `ZeroWord;
            mepc     <= `ZeroWord;
            mie      <= `ZeroWord;
            mstatus  <= `ZeroWord;
            mscratch <= `ZeroWord;
        end 
        else begin
            // normal CSR instruction write has priority
            if (i_ex_csr_wr_en) begin
                case (i_ex_csr_wr_addr)
                    `CSR_MTVEC:    mtvec    <= i_ex_csr_wr_data;
                    `CSR_MCAUSE:   mcause   <= i_ex_csr_wr_data;
                    `CSR_MEPC:     mepc     <= i_ex_csr_wr_data;
                    `CSR_MIE:      mie      <= i_ex_csr_wr_data;
                    `CSR_MSTATUS:  mstatus  <= i_ex_csr_wr_data;
                    `CSR_MSCRATCH: mscratch <= i_ex_csr_wr_data;
                    default: begin
                    end
                endcase
            end 
            // Trap_Unit write
            else if (i_trap_csr_wr_en) begin
                case (i_trap_csr_wr_addr)
                    `CSR_MTVEC:    mtvec    <= i_trap_csr_wr_data;
                    `CSR_MCAUSE:   mcause   <= i_trap_csr_wr_data;
                    `CSR_MEPC:     mepc     <= i_trap_csr_wr_data;
                    `CSR_MIE:      mie      <= i_trap_csr_wr_data;
                    `CSR_MSTATUS:  mstatus  <= i_trap_csr_wr_data;
                    `CSR_MSCRATCH: mscratch <= i_trap_csr_wr_data;
                    default: begin
                    end
                endcase
            end
        end
    end

    // ID-stage CSR read
    always @(*) begin
        // bypass same-cycle EX CSR write
        if ((i_ex_csr_wr_en) && (i_ex_csr_wr_addr == i_id_csr_rd_addr)) begin
            o_id_csr_rd_data = i_ex_csr_wr_data;
        end 
        else begin
            case (i_id_csr_rd_addr)
                `CSR_CYCLE:    o_id_csr_rd_data = cycle[31:0];
                `CSR_CYCLEH:   o_id_csr_rd_data = cycle[63:32];
                `CSR_MTVEC:    o_id_csr_rd_data = mtvec;
                `CSR_MCAUSE:   o_id_csr_rd_data = mcause;
                `CSR_MEPC:     o_id_csr_rd_data = mepc;
                `CSR_MIE:      o_id_csr_rd_data = mie;
                `CSR_MSTATUS:  o_id_csr_rd_data = mstatus;
                `CSR_MSCRATCH: o_id_csr_rd_data = mscratch;
                default:       o_id_csr_rd_data = `ZeroWord;
            endcase
        end
    end

    // Trap_Unit CSR read
    always @(*) begin
        // bypass same-cycle CLINT CSR write
        if ((i_trap_csr_wr_en) && (i_trap_csr_wr_addr == i_trap_csr_rd_addr)) begin
            o_trap_csr_rd_data = i_trap_csr_wr_data;
        end 
        else begin
            case (i_trap_csr_rd_addr)
                `CSR_CYCLE:    o_trap_csr_rd_data = cycle[31:0];
                `CSR_CYCLEH:   o_trap_csr_rd_data = cycle[63:32];
                `CSR_MTVEC:    o_trap_csr_rd_data = mtvec;
                `CSR_MCAUSE:   o_trap_csr_rd_data = mcause;
                `CSR_MEPC:     o_trap_csr_rd_data = mepc;
                `CSR_MIE:      o_trap_csr_rd_data = mie;
                `CSR_MSTATUS:  o_trap_csr_rd_data = mstatus;
                `CSR_MSCRATCH: o_trap_csr_rd_data = mscratch;
                default:       o_trap_csr_rd_data = `ZeroWord;
            endcase
        end
    end

endmodule
