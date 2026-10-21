
module cpu (
    input logic clk,
    input logic reset
);

    // -------------------------------
    // Internal signals
    // -------------------------------

    logic [31:0] pc_current;
    logic [31:0] pc_next;
    logic [31:0] pc_plus4;

    logic [31:0] instruction;

    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;
    logic [6:0] funct7;

    logic reg_write;
    logic alu_src;
    logic mem_write;
    logic mem_read;
    logic branch;
    logic jump;
    logic [2:0] imm_sel;
    logic [1:0] alu_op_class;

    logic [31:0] immediate;
    logic [31:0] rs1_data, rs2_data;
    logic [31:0] alu_b;
    logic [31:0] alu_result;
    logic [3:0] alu_control;

    logic [31:0] mem_read_data;
    logic [31:0] writeback_data;
    logic branch_condition;

    // -------------------------------
    // Program Counter
    // -------------------------------

    pc pc_unit (
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc(pc_current)
    );

    assign pc_plus4 = pc_current + 32'd4;

    // -------------------------------
    // Instruction Memory
    // -------------------------------

    instruction_memory instr_mem (
        .address(pc_current),
        .instruction(instruction)
    );

    // -------------------------------
    // Instruction Field Decoder
    // -------------------------------

    instruction_decoder instr_dec (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .funct3(funct3),
        .funct7(funct7)
    );

    // -------------------------------
    // Main Decoder
    // -------------------------------

    main_decoder main_dec (
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .branch(branch),
        .jump(jump),
        .imm_sel(imm_sel),
        .alu_op(alu_op_class)
    );

    // -------------------------------
    // Immediate Generator
    // -------------------------------

    immediate_generator imm_gen (
        .instruction(instruction),
        .imm_sel(imm_sel),
        .immediate(immediate)
    );

    // -------------------------------
    // Register File
    // -------------------------------

    registers reg_file (
        .clk(clk),
        .we(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .wd(writeback_data),
        .rd1(rs1_data),
        .rd2(rs2_data)
    );

    // -------------------------------
    // ALU Operand Selection
    // -------------------------------

    assign alu_b = alu_src ? immediate : rs2_data;

    // -------------------------------
    // ALU Decoder
    // -------------------------------

    alu_decoder alu_dec (
        .alu_op(alu_op_class),
        .funct3(funct3),
        .funct7(funct7),
        .alu_control(alu_control)
    );

    // -------------------------------
    // ALU
    // -------------------------------

    alu alu_unit (
        .a(rs1_data),
        .b(alu_b),
        .alu_op(alu_control),
        .result(alu_result)
    );

    // -------------------------------
    // Data Memory
    // -------------------------------

    data_memory data_mem (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .address(alu_result),
        .write_data(rs2_data),
        .read_data(mem_read_data)
    );

    // -------------------------------
    // Branch Condition
    // -------------------------------

    always_comb begin
        branch_condition = 1'b0;

        case (funct3)
            3'b000:
                branch_condition = (rs1_data == rs2_data); // BEQ

            3'b001:
                branch_condition = (rs1_data != rs2_data); // BNE

            3'b100:
                branch_condition =
                    ($signed(rs1_data) < $signed(rs2_data)); // BLT

            3'b101:
                branch_condition =
                    ($signed(rs1_data) >= $signed(rs2_data)); // BGE

            3'b110:
                branch_condition = (rs1_data < rs2_data); // BLTU

            3'b111:
                branch_condition = (rs1_data >= rs2_data); // BGEU

            default:
                branch_condition = 1'b0;
        endcase
    end

    // -------------------------------
    // Next PC Selection
    // -------------------------------

    always_comb begin
        pc_next = pc_plus4;

        if (jump && opcode == 7'b1100111) begin
            // JALR
            pc_next =
                (rs1_data + immediate) & 32'hFFFFFFFE;
        end
        else if (jump && opcode == 7'b1101111) begin
            // JAL
            pc_next = pc_current + immediate;
        end
        else if (branch && branch_condition) begin
            // Taken branch
            pc_next = pc_current + immediate;
        end
    end

    // -------------------------------
    // Writeback Selection
    // -------------------------------

    always_comb begin
        case (opcode)
            7'b0000011:
                writeback_data = mem_read_data; // Load

            7'b1101111,
            7'b1100111:
                writeback_data = pc_plus4; // JAL / JALR

            7'b0110111:
                writeback_data = immediate; // LUI

            7'b0010111:
                writeback_data =
                    pc_current + immediate; // AUIPC

            default:
                writeback_data = alu_result;
        endcase
    end

endmodule
