`timescale 1ns / 1ps

module alu_tb;

    parameter WIDTH = 8;

    reg  [WIDTH-1:0] a, b;
    reg  [3:0]        opcode;
    wire [WIDTH-1:0] result;
    wire              carry_out;
    wire              zero_flag;
    wire              overflow_flag;

    integer pass_count = 0;
    integer fail_count = 0;
    integer i;

    // instantiate DUT (device under test)
    alu #(.WIDTH(WIDTH)) dut (
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result),
        .carry_out(carry_out),
        .zero_flag(zero_flag),
        .overflow_flag(overflow_flag)
    );

    // reference model - independent expected-value calculation
    reg [WIDTH-1:0] expected_result;
    reg             expected_zero;

    task check_result;
        input [127:0] test_name;
        begin
            #5; // small delay to let combinational logic settle
            expected_zero = (result == {WIDTH{1'b0}});
            if (result === expected_result && zero_flag === expected_zero) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL [%0s] a=%d b=%d opcode=%b | got result=%d zero=%b | expected result=%d zero=%b",
                          test_name, a, b, opcode, result, zero_flag, expected_result, expected_zero);
            end
        end
    endtask

    initial begin
        $display("Starting ALU Testbench...");

        // ---- Directed tests: known edge cases ----

        // ADD basic
        a = 8'd10; b = 8'd20; opcode = 4'b0000;
        expected_result = a + b;
        check_result("ADD_basic");

        // ADD overflow case: two large positives overflow into negative (signed)
        a = 8'd127; b = 8'd1; opcode = 4'b0000; // 127+1 signed overflow
        expected_result = a + b;
        check_result("ADD_overflow");

        // SUB basic
        a = 8'd50; b = 8'd20; opcode = 4'b0001;
        expected_result = a - b;
        check_result("SUB_basic");

        // SUB underflow (borrow)
        a = 8'd0; b = 8'd1; opcode = 4'b0001;
        expected_result = a - b;
        check_result("SUB_underflow");

        // AND
        a = 8'b10101010; b = 8'b11001100; opcode = 4'b0010;
        expected_result = a & b;
        check_result("AND_test");

        // OR
        a = 8'b10101010; b = 8'b11001100; opcode = 4'b0011;
        expected_result = a | b;
        check_result("OR_test");

        // XOR
        a = 8'b10101010; b = 8'b11001100; opcode = 4'b0100;
        expected_result = a ^ b;
        check_result("XOR_test");

        // NOT
        a = 8'b10101010; b = 8'd0; opcode = 4'b0101;
        expected_result = ~a;
        check_result("NOT_test");

        // SHL
        a = 8'b00000001; b = 8'd0; opcode = 4'b0110;
        expected_result = a << 1;
        check_result("SHL_test");

        // SHR
        a = 8'b10000000; b = 8'd0; opcode = 4'b0111;
        expected_result = a >> 1;
        check_result("SHR_test");

        // CMP equal
        a = 8'd42; b = 8'd42; opcode = 4'b1000;
        expected_result = {{(WIDTH-1){1'b0}}, 1'b1};
        check_result("CMP_equal");

        // CMP not equal
        a = 8'd42; b = 8'd43; opcode = 4'b1000;
        expected_result = {WIDTH{1'b0}};
        check_result("CMP_not_equal");

        // Zero flag check
        a = 8'd5; b = 8'd5; opcode = 4'b0001; // 5-5=0
        expected_result = a - b;
        check_result("ZERO_flag");

        // ---- Randomized regression: 50 iterations ----
        for (i = 0; i < 50; i = i + 1) begin
            a = $random;
            b = $random;
            opcode = $random % 8; // valid opcodes 0-7 (skip CMP for arithmetic-style check simplicity)

            case (opcode)
                4'b0000: expected_result = a + b;
                4'b0001: expected_result = a - b;
                4'b0010: expected_result = a & b;
                4'b0011: expected_result = a | b;
                4'b0100: expected_result = a ^ b;
                4'b0101: expected_result = ~a;
                4'b0110: expected_result = a << 1;
                4'b0111: expected_result = a >> 1;
                default: expected_result = {WIDTH{1'b0}};
            endcase

            check_result("RANDOM");
        end

        $display("----------------------------------------");
        $display("TEST SUMMARY: %0d PASSED, %0d FAILED out of %0d", pass_count, fail_count, pass_count+fail_count);
        $display("----------------------------------------");

        $finish;
    end

endmodule