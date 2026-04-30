`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/30 22:21:32
// Design Name: 
// Module Name: tb_uart_rx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_uart_rx;

localparam integer CLK_FREQ_HZ = 125_000_000;
localparam integer BAUD_RATE   = 115_200;
localparam integer BAUD_DIV    = CLK_FREQ_HZ / BAUD_RATE;
localparam integer CLK_PERIOD  = 8;   // 125 MHz = 8 ns

reg         clk;
reg         rst_n;
reg         rx_i;

wire [7:0]  rx_data_o;
wire        rx_valid_o;
wire        rx_busy_o;

integer error_count;

// ============================================================
// DUT
// ============================================================
uart_rx #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .BAUD_RATE  (BAUD_RATE)
) dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .rx_i       (rx_i),
    .rx_data_o  (rx_data_o),
    .rx_valid_o (rx_valid_o),
    .rx_busy_o  (rx_busy_o)
);

// ============================================================
// Clock generation
// ============================================================
initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) clk = ~clk;
end

// ============================================================
// Reset task
// ============================================================
task reset_dut;
begin
    rst_n = 1'b0;
    rx_i  = 1'b1;      // UART idle = high

    repeat (10) @(posedge clk);

    rst_n = 1'b1;

    repeat (10) @(posedge clk);
end
endtask

// ============================================================
// UART send byte task
// PC -> FPGA RX
// Format: start bit + 8 data bits + stop bit
// UART data order: LSB first
// ============================================================
task uart_send_byte;
    input [7:0] tx_data;
    integer i;
begin
    // Make transition away from clock edge
    @(negedge clk);

    // Start bit
    rx_i = 1'b0;
    repeat (BAUD_DIV) @(posedge clk);

    // Data bits, LSB first
    for (i = 0; i < 8; i = i + 1) begin
        rx_i = tx_data[i];
        repeat (BAUD_DIV) @(posedge clk);
    end

    // Stop bit
    rx_i = 1'b1;
    repeat (BAUD_DIV) @(posedge clk);

    // Idle gap
    repeat (BAUD_DIV) @(posedge clk);
end
endtask

// ============================================================
// Check one received byte
// ============================================================
task check_rx_byte;
    input [7:0] expected_data;
begin
    fork
        begin
            uart_send_byte(expected_data);
        end

        begin
            wait (rx_valid_o == 1'b1);
            #1;

            if (rx_data_o !== expected_data) begin
                $display("[FAIL] time=%0t expected=0x%02h got=0x%02h",
                         $time, expected_data, rx_data_o);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] time=%0t rx_data=0x%02h",
                         $time, rx_data_o);
            end

            @(posedge clk);
            #1;

            if (rx_valid_o !== 1'b0) begin
                $display("[FAIL] rx_valid_o is not one-clock pulse");
                error_count = error_count + 1;
            end
        end
    join
end
endtask

// ============================================================
// Main test
// ============================================================
initial begin
    error_count = 0;

    reset_dut();

    $display("========================================");
    $display("UART RX Test Start");
    $display("CLK_FREQ_HZ = %0d", CLK_FREQ_HZ);
    $display("BAUD_RATE   = %0d", BAUD_RATE);
    $display("BAUD_DIV    = %0d", BAUD_DIV);
    $display("========================================");

    check_rx_byte(8'h41);  // A
    check_rx_byte(8'h55);  // 01010101
    check_rx_byte(8'hAA);  // 10101010
    check_rx_byte(8'h00);
    check_rx_byte(8'hFF);

    repeat (20) @(posedge clk);

    if (error_count == 0) begin
        $display("========================================");
        $display("UART RX TEST PASS");
        $display("========================================");
    end else begin
        $display("========================================");
        $display("UART RX TEST FAIL, error_count = %0d", error_count);
        $display("========================================");
    end

    $stop;
end

endmodule