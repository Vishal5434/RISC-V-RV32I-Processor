module cpu_tb;

    logic clk;
    logic reset;

    integer p, i;
    integer failures;
    integer target_byte;
    logic [31:0] expected_jal_link;
    logic [31:0] expected_jalr_link;
    logic [31:0] expected_auipc;

    cpu dut (
        .clk(clk),
        .reset(reset)
    );

    // 10 ns clock period
    always #5 clk = ~clk;


    // =========================================
    // INSTRUCTION ENCODING FUNCTIONS
    // =========================================

    function automatic [31:0] enc_r(
        input [6:0] f7,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] f3,
        input [4:0] rd
    );
        enc_r = {f7, rs2, rs1, f3, rd, 7'b0110011};
    endfunction

    function automatic [31:0] enc_i(
        input [11:0] imm,
        input [4:0] rs1,
        input [2:0] f3,
        input [4:0] rd,
        input [6:0] opc
    );
        enc_i = {imm, rs1, f3, rd, opc};
    endfunction

    function automatic [31:0] enc_s(
        input [11:0] imm,
        input [4:0] rs2,
        input [4:0] rs1
    );
        enc_s = {
            imm[11:5], rs2, rs1, 3'b010,
            imm[4:0], 7'b0100011
        };
    endfunction

    function automatic [31:0] enc_b(
        input [12:0] imm,
        input [4:0] rs2,
        input [4:0] rs1,
        input [2:0] f3
    );
        enc_b = {
            imm[12], imm[10:5], rs2, rs1,
            f3, imm[4:1], imm[11], 7'b1100011
        };
    endfunction

    function automatic [31:0] enc_u(
        input [19:0] imm,
        input [4:0] rd,
        input [6:0] opc
    );
        enc_u = {imm, rd, opc};
    endfunction

    function automatic [31:0] enc_j(
        input [20:0] imm,
        input [4:0] rd
    );
        enc_j = {
            imm[20], imm[10:1], imm[11],
            imm[19:12], rd, 7'b1101111
        };
    endfunction


    // =========================================
    // REGISTER CHECK TASK
    // =========================================

    task check_reg(
        input integer index,
        input [31:0] expected
    );
        begin
            if (dut.reg_file.registers[index] !== expected) begin
                $display(
                    "FAIL: x%0d expected %0d (0x%08h), got %0d (0x%08h)",
                    index, expected, expected,
                    dut.reg_file.registers[index],
                    dut.reg_file.registers[index]
                );
                failures = failures + 1;
            end
            else begin
                $display(
                    "PASS: x%0d = %0d (0x%08h)",
                    index, expected, expected
                );
            end
        end
    endtask


    // =========================================
    // TEST PROGRAM
    // =========================================

    initial begin
        clk = 0;
        reset = 1;
        failures = 0;
        p = 0;

        // Fill instruction memory with NOPs
        for (i = 0; i < 256; i = i + 1)
            dut.instr_mem.memory[i] = 32'h00000013;


        // ---- Initial register values ----

        // x1 = 10
        dut.instr_mem.memory[p] =
            enc_i(12'd10, 5'd0, 3'b000, 5'd1, 7'b0010011);
        p = p + 1;

        // x2 = 3
        dut.instr_mem.memory[p] =
            enc_i(12'd3, 5'd0, 3'b000, 5'd2, 7'b0010011);
        p = p + 1;

        // x22 = -5
        dut.instr_mem.memory[p] =
            enc_i(12'hFFB, 5'd0, 3'b000, 5'd22, 7'b0010011);
        p = p + 1;


        // ---- R-type ALU instructions ----

        // ADD x3, x1, x2 = 13
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 2, 1, 3'b000, 3);
        p = p + 1;

        // SUB x4, x1, x2 = 7
        dut.instr_mem.memory[p] =
            enc_r(7'b0100000, 2, 1, 3'b000, 4);
        p = p + 1;

        // AND x5, x1, x2 = 2
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 2, 1, 3'b111, 5);
        p = p + 1;

        // OR x6, x1, x2 = 11
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 2, 1, 3'b110, 6);
        p = p + 1;

        // XOR x7, x1, x2 = 9
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 2, 1, 3'b100, 7);
        p = p + 1;

        // SLL x8, x1, x2 = 80
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 2, 1, 3'b001, 8);
        p = p + 1;

        // SRL x9, x22, x2
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 2, 22, 3'b101, 9);
        p = p + 1;

        // SRA x10, x22, x2
        dut.instr_mem.memory[p] =
            enc_r(7'b0100000, 2, 22, 3'b101, 10);
        p = p + 1;

        // SLT x11, x2, x1 = 1
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 1, 2, 3'b010, 11);
        p = p + 1;

        // SLTU x12, x1, x2 = 0
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 2, 1, 3'b011, 12);
        p = p + 1;


        // ---- Immediate ALU instructions ----

        // ADDI x14, x1, -3 = 7
        dut.instr_mem.memory[p] =
            enc_i(12'hFFD, 1, 3'b000, 14, 7'b0010011);
        p = p + 1;

        // SLLI x31, x1, 2 = 40
        dut.instr_mem.memory[p] =
            enc_i(12'h002, 1, 3'b001, 31, 7'b0010011);
        p = p + 1;

        // SRLI x15, x1, 1 = 5
        dut.instr_mem.memory[p] =
            enc_i(12'h001, 1, 3'b101, 15, 7'b0010011);
        p = p + 1;

        // SRAI x16, x22, 1 = -3
        dut.instr_mem.memory[p] =
            enc_i(12'h401, 22, 3'b101, 16, 7'b0010011);
        p = p + 1;

        // SLTI x23, x22, 0 = 1
        dut.instr_mem.memory[p] =
            enc_i(12'h000, 22, 3'b010, 23, 7'b0010011);
        p = p + 1;

        // SLTIU x24, x22, 1 = 0
        dut.instr_mem.memory[p] =
            enc_i(12'h001, 22, 3'b011, 24, 7'b0010011);
        p = p + 1;

        // SLT x25, x22, x2 = 1
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 2, 22, 3'b010, 25);
        p = p + 1;

        // SLTU x26, x22, x2 = 0
        dut.instr_mem.memory[p] =
            enc_r(7'b0000000, 2, 22, 3'b011, 26);
        p = p + 1;

        // ANDI x27, x1, 6 = 2
        dut.instr_mem.memory[p] =
            enc_i(12'd6, 1, 3'b111, 27, 7'b0010011);
        p = p + 1;

        // ORI x28, x1, 5 = 15
        dut.instr_mem.memory[p] =
            enc_i(12'd5, 1, 3'b110, 28, 7'b0010011);
        p = p + 1;

        // XORI x29, x1, 3 = 9
        dut.instr_mem.memory[p] =
            enc_i(12'd3, 1, 3'b100, 29, 7'b0010011);
        p = p + 1;


        // ---- Data memory ----

        // x20 = 64 (base address)
        dut.instr_mem.memory[p] =
            enc_i(12'd64, 0, 3'b000, 20, 7'b0010011);
        p = p + 1;

        // SW x1, 0(x20)
        dut.instr_mem.memory[p] =
            enc_s(12'd0, 1, 20);
        p = p + 1;

        // LW x13, 0(x20)
        dut.instr_mem.memory[p] =
            enc_i(12'd0, 20, 3'b010, 13, 7'b0000011);
        p = p + 1;


        // ---- Initialize branch/jump failure counter ----

        // x30 = 0
        dut.instr_mem.memory[p] =
            enc_i(12'd0, 0, 3'b000, 30, 7'b0010011);
        p = p + 1;


        // ---- Conditional branches ----
        // Each taken branch skips the next instruction.
        // If it fails, that instruction increments x30.

        // BEQ x1, x1, +8 (taken)
        dut.instr_mem.memory[p] = enc_b(13'd8, 1, 1, 3'b000);
        p = p + 1;
        dut.instr_mem.memory[p] =
            enc_i(12'd1, 30, 3'b000, 30, 7'b0010011);
        p = p + 1;

        // BNE x1, x2, +8 (taken)
        dut.instr_mem.memory[p] = enc_b(13'd8, 2, 1, 3'b001);
        p = p + 1;
        dut.instr_mem.memory[p] =
            enc_i(12'd1, 30, 3'b000, 30, 7'b0010011);
        p = p + 1;

        // BLT x2, x1, +8 (taken)
        dut.instr_mem.memory[p] = enc_b(13'd8, 1, 2, 3'b100);
        p = p + 1;
        dut.instr_mem.memory[p] =
            enc_i(12'd1, 30, 3'b000, 30, 7'b0010011);
        p = p + 1;

        // BGE x1, x2, +8 (taken)
        dut.instr_mem.memory[p] = enc_b(13'd8, 2, 1, 3'b101);
        p = p + 1;
        dut.instr_mem.memory[p] =
            enc_i(12'd1, 30, 3'b000, 30, 7'b0010011);
        p = p + 1;

        // BLTU x2, x1, +8 (taken)
        dut.instr_mem.memory[p] = enc_b(13'd8, 1, 2, 3'b110);
        p = p + 1;
        dut.instr_mem.memory[p] =
            enc_i(12'd1, 30, 3'b000, 30, 7'b0010011);
        p = p + 1;

        // BGEU x1, x2, +8 (taken)
        dut.instr_mem.memory[p] = enc_b(13'd8, 2, 1, 3'b111);
        p = p + 1;
        dut.instr_mem.memory[p] =
            enc_i(12'd1, 30, 3'b000, 30, 7'b0010011);
        p = p + 1;

        // BEQ x1, x2, +8 (NOT taken)
        dut.instr_mem.memory[p] = enc_b(13'd8, 2, 1, 3'b000);
        p = p + 1;

        // This must execute because the branch is not taken.
        dut.instr_mem.memory[p] =
            enc_i(12'd21, 0, 3'b000, 21, 7'b0010011);
        p = p + 1;


        // ---- JAL ----

        expected_jal_link = p * 4 + 4;

        // JAL x17, +8
        dut.instr_mem.memory[p] = enc_j(21'd8, 17);
        p = p + 1;

        // Must be skipped by JAL
        dut.instr_mem.memory[p] =
            enc_i(12'd1, 30, 3'b000, 30, 7'b0010011);
        p = p + 1;


        // ---- JALR ----

        // JALR target is the instruction after the failure sentinel.
        target_byte = (p + 3) * 4;

        // Set x19 to the target byte address
        dut.instr_mem.memory[p] =
            enc_i(target_byte[11:0], 0, 3'b000, 19, 7'b0010011);
        p = p + 1;

        expected_jalr_link = p * 4 + 4;

        // JALR x18, 0(x19)
        dut.instr_mem.memory[p] =
            enc_i(12'd0, 19, 3'b000, 18, 7'b1100111);
        p = p + 1;

        // Must be skipped by JALR
        dut.instr_mem.memory[p] =
            enc_i(12'd1, 30, 3'b000, 30, 7'b0010011);
        p = p + 1;


        // ---- LUI and AUIPC ----

        // LUI x14, 0x12345
        dut.instr_mem.memory[p] =
            enc_u(20'h12345, 14, 7'b0110111);
        p = p + 1;

        expected_auipc = (p * 4) + 32'h00001000;

        // AUIPC x19, 0x1
        dut.instr_mem.memory[p] =
            enc_u(20'h00001, 19, 7'b0010111);
        p = p + 1;


        // =========================================
        // RUN CPU
        // =========================================

        #20;
        reset = 0;

        // Allow all instructions to execute
        #700;


        // =========================================
        // CHECK RESULTS
        // =========================================

        $display("\n========== CPU TEST RESULTS ==========");

        check_reg(1,  32'd10);
        check_reg(2,  32'd3);
        check_reg(3,  32'd13);
        check_reg(4,  32'd7);
        check_reg(5,  32'd2);
        check_reg(6,  32'd11);
        check_reg(7,  32'd9);
        check_reg(8,  32'd80);

        check_reg(9,  32'h1FFFFFFF);
        check_reg(10, 32'hFFFFFFFF);
        check_reg(11, 32'd1);
        check_reg(12, 32'd0);

        check_reg(13, 32'd10);
        check_reg(14, 32'h12345000);
        check_reg(15, 32'd5);
        check_reg(16, 32'hFFFFFFFD);

        check_reg(17, expected_jal_link);
        check_reg(18, expected_jalr_link);
        check_reg(19, expected_auipc);

        check_reg(21, 32'd21);
        check_reg(22, 32'hFFFFFFFB);
        check_reg(23, 32'd1);
        check_reg(24, 32'd0);
        check_reg(25, 32'd1);
        check_reg(26, 32'd0);
        check_reg(27, 32'd2);
        check_reg(28, 32'd15);
        check_reg(29, 32'd9);

        check_reg(30, 32'd0);
        check_reg(31, 32'd40);

        // Data memory address 64 selects word index 16.
        if (dut.data_mem.memory[16] !== 32'd10) begin
            $display("FAIL: memory[16] expected 10, got %0d",
                     dut.data_mem.memory[16]);
            failures = failures + 1;
        end
        else begin
            $display("PASS: data memory word 16 = 10");
        end

        $display("--------------------------------------");

        if (failures == 0)
            $display("ALL CHECKS PASSED!");
        else
            $display("FAILED CHECKS: %0d", failures);

        $display("======================================\n");

        $finish;
    end

endmodule
