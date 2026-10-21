module registers (
    input  logic        clk,
    input  logic        we,

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,

    input  logic [31:0] wd,

    output logic [31:0] rd1,
    output logic [31:0] rd2
);

    // 32 registers, each 32 bits wide
    logic [31:0] registers [0:31];

    // Read ports
    assign rd1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

    // Write port
    always_ff @(posedge clk) begin
        if (we && (rd != 5'd0))
            registers[rd] <= wd;
    end

endmodule
