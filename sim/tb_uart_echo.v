`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/03 22:13:49
// Design Name: 
// Module Name: tb_uart_echo
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


module tb_uart_echo;

    // ============================================================
    // Simulation parameters
    // ============================================================
    localparam integer CLK_FREQ_HZ = 125_000_000;
    localparam integer BAUD_RATE   = 115_200;

    localparam integer CLK_PERIOD_NS = 8;  // 125 MHz = 8 ns
    localparam integer BAUD_DIV      = CLK_FREQ_HZ / BAUD_RATE;
    localparam integer BIT_PERIOD_NS = CLK_PERIOD_NS * BAUD_DIV;

    // ============================================================
    // DUT signals
    // ============================================================
    reg  clk;
    reg  rst_n;

    reg  uart_rx_i;
    wire uart_tx_o;

    // ============================================================
    // Test variables
    // ============================================================
    reg [7:0] rx_byte;

    // ============================================================
    // Clock generation
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    // ============================================================
    // DUT
    // ============================================================
    uart_echo_top #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE  (BAUD_RATE)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .uart_rx_i (uart_rx_i),
        .uart_tx_o (uart_tx_o)
    );

    // ============================================================
    // Reset task
    // ============================================================
    task reset_dut;
        begin
            rst_n     = 1'b0;
            uart_rx_i = 1'b1;   // UART idle = high

            repeat (20) @(posedge clk);

            rst_n = 1'b1;

            repeat (20) @(posedge clk);
        end
    endtask

    // ============================================================
    // PC sends one UART byte to FPGA RX
    // UART format: 8N1, LSB first
    // ============================================================
    task uart_send_byte;
        input [7:0] data;
        integer i;
        begin
            // Idle
            uart_rx_i = 1'b1;
            #(BIT_PERIOD_NS);

            // Start bit
            uart_rx_i = 1'b0;
            #(BIT_PERIOD_NS);

            // Data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_i = data[i];
                #(BIT_PERIOD_NS);
            end

            // Stop bit
            uart_rx_i = 1'b1;
            #(BIT_PERIOD_NS);
        end
    endtask

    // ============================================================
    // PC receives one UART byte from FPGA TX
    // UART format: 8N1, LSB first
    // ============================================================
    task uart_recv_byte;
        output [7:0] data;
        integer i;
        begin
            data = 8'd0;

            // Wait for start bit falling edge
            @(negedge uart_tx_o);

            // Move to middle of bit0
            #(BIT_PERIOD_NS + BIT_PERIOD_NS / 2);

            // Sample data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                data[i] = uart_tx_o;
                #(BIT_PERIOD_NS);
            end

            // Now should be around middle of stop bit
            if (uart_tx_o !== 1'b1) begin
                $display("[ERROR] Stop bit is not high at time %0t", $time);
            end
        end
    endtask

    // ============================================================
    // Check one echo byte
    // ============================================================
    task check_echo;
        input [7:0] tx_byte;
        begin
            fork
                begin
                    uart_send_byte(tx_byte);
                end

                begin
                    uart_recv_byte(rx_byte);
                end
            join

            if (rx_byte == tx_byte) begin
                $display("[PASS] TX = 0x%02h, RX = 0x%02h, time = %0t",
                         tx_byte, rx_byte, $time);
            end else begin
                $display("[FAIL] TX = 0x%02h, RX = 0x%02h, time = %0t",
                         tx_byte, rx_byte, $time);
                $stop;
            end

            #(BIT_PERIOD_NS * 3);
        end
    endtask

    // ============================================================
    // Main test
    // ============================================================
    initial begin
        $display("========================================");
        $display(" UART Echo Testbench Start");
        $display(" CLK_FREQ_HZ   = %0d", CLK_FREQ_HZ);
        $display(" BAUD_RATE     = %0d", BAUD_RATE);
        $display(" BAUD_DIV      = %0d", BAUD_DIV);
        $display(" BIT_PERIOD_NS = %0d", BIT_PERIOD_NS);
        $display("========================================");

        reset_dut();

        check_echo(8'h41);  // A
        check_echo(8'h55);
        check_echo(8'hA5);

        $display("========================================");
        $display(" UART Echo Test PASS");
        $display("========================================");

        $finish;
    end

endmodule