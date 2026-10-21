module instruction_memory (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    logic [31:0] memory [0:255];

    assign instruction = memory[address[9:2]];

endmodule
