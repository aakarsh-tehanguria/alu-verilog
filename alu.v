module alu #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [3:0]        opcode,
    output reg [WIDTH-1:0] result,
    output reg           carry_out,
    output reg           zero_flag,
    output reg           overflow_flag
);

    // Opcodes
    localparam ADD = 4'b0000;
    localparam SUB = 4'b0001;
    localparam AND_OP = 4'b0010;
    localparam OR_OP  = 4'b0011;
    localparam XOR_OP = 4'b0100;
    localparam NOT_OP = 4'b0101;
    localparam SHL    = 4'b0110;
    localparam SHR    = 4'b0111;
    localparam CMP    = 4'b1000;

    reg [WIDTH:0] temp; // one extra bit to catch carry/borrow

    always @(*) begin
        // defaults every eval, avoids latches
        temp          = {1'b0, {WIDTH{1'b0}}};
        result        = {WIDTH{1'b0}};
        carry_out     = 1'b0;
        overflow_flag = 1'b0;

        case (opcode)
            ADD: begin
                temp = {1'b0, a} + {1'b0, b};
                result = temp[WIDTH-1:0];
                carry_out = temp[WIDTH];
                // signed overflow: both operands same sign, result differs
                overflow_flag = (a[WIDTH-1] == b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end

            SUB: begin
                temp = {1'b0, a} - {1'b0, b};
                result = temp[WIDTH-1:0];
                carry_out = temp[WIDTH]; // borrow flag here
                overflow_flag = (a[WIDTH-1] != b[WIDTH-1]) && (result[WIDTH-1] != a[WIDTH-1]);
            end

            AND_OP: result = a & b;
            OR_OP:  result = a | b;
            XOR_OP: result = a ^ b;
            NOT_OP: result = ~a;

            SHL: begin
                temp = {a, 1'b0}; // shift left by 1, capture bit shifted out
                result = a << 1;
                carry_out = a[WIDTH-1];
            end

            SHR: begin
                result = a >> 1;
                carry_out = a[0];
            end

            CMP: result = (a == b) ? {{(WIDTH-1){1'b0}}, 1'b1} : {WIDTH{1'b0}};

            default: result = {WIDTH{1'b0}};
        endcase

        zero_flag = (result == {WIDTH{1'b0}});
    end

endmodule