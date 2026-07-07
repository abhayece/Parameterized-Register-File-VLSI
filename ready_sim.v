`timescale 1ns/1ps

// ========================================================
// TOP LEVEL REGISTER FILE (Synthesizable & Tool-Compatible)
// ========================================================
module register_file #(
    parameter DATA_WIDTH = 8,
    parameter NUM_REGISTERS = 16,
    parameter ADDR_WIDTH = 4
)(
    input wire clk,
    input wire reset,
    input wire write_enable,
    input wire [ADDR_WIDTH-1:0] write_address,
    input wire [DATA_WIDTH-1:0] write_data,
    input wire [ADDR_WIDTH-1:0] read_address1,
    input wire [ADDR_WIDTH-1:0] read_address2,
    output wire [DATA_WIDTH-1:0] read_data1,
    output wire [DATA_WIDTH-1:0] read_data2
);

    // Core Register Array Storage
    reg [DATA_WIDTH-1:0] rf [NUM_REGISTERS-1:0];

    // Synchronous Write Logic (with Reset and R0 protection)
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < NUM_REGISTERS; i = i + 1) begin
                rf[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (write_enable && (write_address != {ADDR_WIDTH{1'b0}})) begin
            rf[write_address] <= write_data;
        end
    end

    // Asynchronous Combinational Reads (Force R0 to stay constant zero)
    assign read_data1 = (read_address1 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : rf[read_address1];
    assign read_data2 = (read_address2 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : rf[read_address2];

endmodule

// ========================================================
// TIMING-CORRECTED SELF-CHECKING TESTBENCH
// ========================================================
module tb_register_file;
    parameter DATA_WIDTH = 8;
    parameter NUM_REGISTERS = 16;
    parameter ADDR_WIDTH = 4;

    reg clk;
    reg reset;
    reg write_enable;
    reg [ADDR_WIDTH-1:0] write_address;
    reg [DATA_WIDTH-1:0] write_data;
    reg [ADDR_WIDTH-1:0] read_address1;
    reg [ADDR_WIDTH-1:0] read_address2;

    wire [DATA_WIDTH-1:0] read_data1;
    wire [DATA_WIDTH-1:0] read_data2;
    integer errors = 0;

    // Instantiate Unit Under Test
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGISTERS(NUM_REGISTERS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_address(write_address),
        .write_data(write_data),
        .read_address1(read_address1),
        .read_address2(read_address2),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Clock Generator (50MHz)
    always #10 clk = ~clk;

    initial begin
        $dumpfile("register_file_sim.vcd");
        $dumpvars(0, tb_register_file);

        // Initialization
        clk = 0; reset = 0; write_enable = 0;
        write_address = 0; write_data = 0;
        read_address1 = 0; read_address2 = 0;

        // TEST CASE 1: Reset Functionality
        $display("[TEST] Starting Reset Functionality Test...");
        reset = 1; #20; reset = 0; #5;
        read_address1 = 4'd5; read_address2 = 4'd12; #5;
        if (read_data1 !== 8'd0 || read_data2 !== 8'd0) begin
            $display("[FAIL] Reset verification failed!");
            errors = errors + 1;
        end else $display("[PASS] Reset functionality verified.");

        // TEST CASE 2: Single Register Write
        $display("[TEST] Testing Single Register Write...");
        @(posedge clk);
        #1; // Delay added to avoid clock-edge race condition
        write_address = 4'd3; write_data = 8'hA5; write_enable = 1;
        @(posedge clk); 
        #1;
        write_enable = 0; #5;
        read_address1 = 4'd3; #5;
        if (read_data1 !== 8'hA5) begin
            $display("[FAIL] Data write mismatch! Expected A5, Got %h", read_data1);
            errors = errors + 1;
        end else $display("[PASS] Single register write/read passed.");

        // TEST CASE 3: Dual Port Read and Overwrite
        $display("[TEST] Testing Multiple Register Writes and Dual Port Read...");
        @(posedge clk);
        #1;
        write_address = 4'd7; write_data = 8'h55; write_enable = 1;
        @(posedge clk);
        #1;
        write_address = 4'd3; write_data = 8'h11;
        @(posedge clk); 
        #1;
        write_enable = 0; #5;
        read_address1 = 4'd3; read_address2 = 4'd7; #5;
        if (read_data1 !== 8'h11 || read_data2 !== 8'h55) begin
            $display("[FAIL] Dual port matching failure! read1=%h, read2=%h", read_data1, read_data2);
            errors = errors + 1;
        end else $display("[PASS] Dual-Port concurrent validation passed.");

        // TEST CASE 4: Write Enable Protection
        $display("[TEST] Testing Write Enable Protection...");
        write_address = 4'd14; write_data = 8'hFF; write_enable = 0; 
        @(posedge clk); #5;
        read_address1 = 4'd14; #5;
        if (read_data1 === 8'hFF) begin
            $display("[FAIL] Register mutated without write enable active!");
            errors = errors + 1;
        end else $display("[PASS] Write enable logic protection verified.");

        // TEST CASE 5: Register 0 Constant Lock
        $display("[TEST] Testing Register 0 Zero Lock-Down...");
        @(posedge clk);
        #1;
        write_address = 4'd0; write_data = 8'hFF; write_enable = 1;
        @(posedge clk); 
        #1;
        write_enable = 0; #5;
        read_address1 = 4'd0; #5;
        if (read_data1 !== 8'd0) begin
            $display("[FAIL] R0 hardwire overwrite breach occurred!");
            errors = errors + 1;
        end else $display("[PASS] Register 0 absolute zero invariant verified.");

        // Final Summary Block
        if (errors == 0) begin
            $display("\n========================================");
            $display("       ALL SIMULATION TESTS PASSED       ");
            $display("========================================");
        end else begin
            $display("\n========================================");
            $display("       SIMULATION FAILED WITH %d ERRORS ", errors);
            $display("========================================");
        end
        $finish;
    end
endmodule
