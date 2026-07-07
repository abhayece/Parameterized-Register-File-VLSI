`timescale 1ns/1ps

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

    // Synchronous Write Logic
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

    // Asynchronous Combinational Reads
    assign read_data1 = (read_address1 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : rf[read_address1];
    assign read_data2 = (read_address2 == {ADDR_WIDTH{1'b0}}) ? {DATA_WIDTH{1'b0}} : rf[read_address2];

endmodule
