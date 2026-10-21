module main_decoder (
    input  logic [6:0] opcode,

    output logic       reg_write,
    output logic       alu_src,
    output logic       mem_write,
    output logic       mem_read,
    output logic       branch,
    output logic       jump,
    output logic [2:0] imm_sel,
    output logic [1:0] alu_op
);

    always_comb begin

        // Default values
        reg_write = 1'b0;
        alu_src   = 1'b0;
        mem_write = 1'b0;
        mem_read  = 1'b0;
        branch    = 1'b0;
        jump      = 1'b0;
        imm_sel   = 3'b000;
        alu_op    = 2'b00;

        case (opcode)

            // R-type: ADD, SUB, AND, OR, XOR, etc.
            7'b0110011: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end

            // I-type ALU: ADDI, ANDI, ORI, XORI, etc.
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = 3'b000;
                alu_op    = 2'b11;
            end

            // Load: LB, LH, LW, LBU, LHU
            7'b0000011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                mem_read  = 1'b1;
                imm_sel   = 3'b000;
                alu_op    = 2'b00;
            end

            // Store: SB, SH, SW
            7'b0100011: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                imm_sel   = 3'b001;
                alu_op    = 2'b00;
            end

            // Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU
            7'b1100011: begin
                alu_src = 1'b0;
                branch  = 1'b1;
                imm_sel = 3'b010;
                alu_op  = 2'b01;
            end

            // JAL
            7'b1101111: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                imm_sel   = 3'b100;
            end

            // JALR
            7'b1100111: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = 3'b000;
            end

            // LUI
            7'b0110111: begin
                reg_write = 1'b1;
                imm_sel   = 3'b011;
            end

            // AUIPC
            7'b0010111: begin
                reg_write = 1'b1;
                imm_sel   = 3'b011;
            end

            default: begin
                // Keep default control values
            end

        endcase

    end

endmodule
