module alu_decoder (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output logic [3:0] alu_control
);

    always_comb begin

        // Default: ADD
        alu_control = 4'b0000;

        case (alu_op)

            // Loads, stores, JALR, etc.
            2'b00: begin
                alu_control = 4'b0000;   // ADD
            end

            // Branches
            2'b01: begin
                case (funct3)
                    3'b000: alu_control = 4'b0001; // BEQ → SUB/compare
                    3'b001: alu_control = 4'b0001; // BNE
                    3'b100: alu_control = 4'b1000; // BLT
                    3'b101: alu_control = 4'b1000; // BGE
                    3'b110: alu_control = 4'b1001; // BLTU
                    3'b111: alu_control = 4'b1001; // BGEU
                    default: alu_control = 4'b0000;
                endcase
            end

            // R-type
            2'b10: begin
                case (funct3)

                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_control = 4'b0001; // SUB
                        else
                            alu_control = 4'b0000; // ADD
                    end

                    3'b001: alu_control = 4'b0101; // SLL
                    3'b010: alu_control = 4'b1000; // SLT
                    3'b011: alu_control = 4'b1001; // SLTU
                    3'b100: alu_control = 4'b0100; // XOR
                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_control = 4'b0111; // SRA
                        else
                            alu_control = 4'b0110; // SRL
                    end
                    3'b110: alu_control = 4'b0011; // OR
                    3'b111: alu_control = 4'b0010; // AND

                    default: alu_control = 4'b0000;

                endcase
            end

            // I-type ALU
            2'b11: begin
                case (funct3)

                    3'b000: alu_control = 4'b0000; // ADDI
                    3'b010: alu_control = 4'b1000; // SLTI
                    3'b011: alu_control = 4'b1001; // SLTIU
                    3'b100: alu_control = 4'b0100; // XORI
                    3'b110: alu_control = 4'b0011; // ORI
                    3'b111: alu_control = 4'b0010; // ANDI
                    3'b001: alu_control = 4'b0101; // SLLI

                    3'b101: begin
                        if (funct7 == 7'b0100000)
                            alu_control = 4'b0111; // SRAI
                        else
                            alu_control = 4'b0110; // SRLI
                    end

                    default: alu_control = 4'b0000;

                endcase
            end

            default:
                alu_control = 4'b0000;

        endcase

    end

endmodule
