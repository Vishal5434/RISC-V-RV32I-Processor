module pc (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] pc_next,
    output logic [31:0] pc
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

endmodule
