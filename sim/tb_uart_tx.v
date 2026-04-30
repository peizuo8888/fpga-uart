`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/29 19:06:50
// Design Name: 
// Module Name: tb_uart_tx
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


module tb_uart_tx;

// ============================================================
// Simulation Parameters
// ============================================================
// 模擬用小參數，跑比較快
// 不會影響你 RTL 裡面的 default 125MHz / 115200
localparam integer CLK_FREQ_HZ = 1_000_000;
localparam integer BAUD_RATE   = 100_000;
localparam integer BAUD_DIV    = CLK_FREQ_HZ / BAUD_RATE;

localparam real CLK_PERIOD_NS = 1_000_000_000.0 / CLK_FREQ_HZ;

// ============================================================
// DUT Signals
// ============================================================
reg        clk;
reg        rst_n;

reg        tx_start_i;
reg [7:0]  tx_data_i;

wire       tx_o;
wire       tx_busy_o;
wire       tx_done_o;

// ============================================================
// DUT Instance
// ============================================================
uart_tx #(
    .CLK_FREQ_HZ (CLK_FREQ_HZ),
    .BAUD_RATE   (BAUD_RATE)
) u_uart_tx (
    .clk        (clk),
    .rst_n      (rst_n),

    .tx_start_i (tx_start_i),
    .tx_data_i  (tx_data_i),

    .tx_o       (tx_o),
    .tx_busy_o  (tx_busy_o),
    .tx_done_o  (tx_done_o)
);

// ============================================================
// Clock Generation
// ============================================================
initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS / 2.0) clk = ~clk;
end

// ============================================================
// Reset Task
// ============================================================
task reset_dut;
begin
    rst_n      = 1'b0;
    tx_start_i = 1'b0;
    tx_data_i  = 8'h00;

    repeat (10) @(posedge clk);

    rst_n = 1'b1;

    repeat (10) @(posedge clk);
end
endtask

// ============================================================
// Send One Byte Task
// ============================================================
task send_byte;
input [7:0] data;
begin
    @(posedge clk);
    tx_data_i  <= data;
    tx_start_i <= 1'b1;

    @(posedge clk);
    tx_start_i <= 1'b0;
end
endtask

// ============================================================
// Wait Half Bit Time
// ============================================================
task wait_half_bit;
begin
    repeat (BAUD_DIV / 2) @(posedge clk);
end
endtask

// ============================================================
// Wait One Bit Time
// ============================================================
task wait_one_bit;
begin
    repeat (BAUD_DIV) @(posedge clk);
end
endtask

// ============================================================
// Check Signal Task
// ============================================================
task check_signal;
input       actual;
input       expected;
input [8*32-1:0] name;
begin
    #1;

    if (actual !== expected) begin
        $display("[FAIL] %s expected = %b, got = %b, time = %0t",
                 name, expected, actual, $time);
        $finish;
    end
    else begin
        $display("[PASS] %s = %b", name, actual);
    end
end
endtask

// ============================================================
// Check UART Frame Task
// ============================================================
task check_uart_frame;
input [7:0] expected_data;
integer i;
begin
    // 等 start bit 出現，也就是 tx_o 從 idle high 變 low
    @(negedge tx_o);

    // 在 start bit 中間取樣
    wait_half_bit();
    check_signal(tx_o, 1'b0, "start bit");

    // 檢查 8 個 data bit
    // UART 是 LSB first，所以從 expected_data[0] 開始
    for (i = 0; i < 8; i = i + 1) begin
        wait_one_bit();

        #1;

        if (tx_o !== expected_data[i]) begin
            $display("[FAIL] data bit %0d expected = %b, got = %b, time = %0t",
                     i, expected_data[i], tx_o, $time);
            $finish;
        end
        else begin
            $display("[PASS] data bit %0d = %b", i, tx_o);
        end
    end

    // 檢查 stop bit
    wait_one_bit();
    check_signal(tx_o, 1'b1, "stop bit");
end
endtask

// ============================================================
// Main Test
// ============================================================
initial begin
    $display("========================================");
    $display(" UART TX Testbench Start");
    $display(" CLK_FREQ_HZ = %0d", CLK_FREQ_HZ);
    $display(" BAUD_RATE   = %0d", BAUD_RATE);
    $display(" BAUD_DIV    = %0d", BAUD_DIV);
    $display("========================================");

    reset_dut();

    // --------------------------------------------------------
    // Check idle condition
    // --------------------------------------------------------
    check_signal(tx_o,       1'b1, "tx_o idle");
    check_signal(tx_busy_o,  1'b0, "tx_busy_o idle");
    check_signal(tx_done_o,  1'b0, "tx_done_o idle");

    // --------------------------------------------------------
    // Test 1: Send 8'h41
    // 8'h41 = 0100_0001
    //
    // UART LSB first:
    // bit0 = 1
    // bit1 = 0
    // bit2 = 0
    // bit3 = 0
    // bit4 = 0
    // bit5 = 0
    // bit6 = 1
    // bit7 = 0
    // --------------------------------------------------------
    $display("----------------------------------------");
    $display(" Test 1: Send 8'h41");
    $display("----------------------------------------");

    send_byte(8'h41);

    // 進入傳送後 busy 應該為 1
    wait_half_bit();
    check_signal(tx_busy_o, 1'b1, "tx_busy_o during TX");

    // 回到 start bit 起點重新檢查完整 frame
    // 注意：因為上面已經等過 half bit，所以這裡不能再等 negedge
    // 所以這個 testbench 使用第二筆資料來做完整 frame check

    wait (tx_done_o == 1'b1);
    @(posedge clk);

    check_signal(tx_done_o, 1'b1, "tx_done_o pulse");

    @(posedge clk);
    check_signal(tx_busy_o, 1'b0, "tx_busy_o after TX");

    // --------------------------------------------------------
    // Test 2: Send 8'h41 again and check full UART frame
    // --------------------------------------------------------
    $display("----------------------------------------");
    $display(" Test 2: Full frame check 8'h41");
    $display("----------------------------------------");

    send_byte(8'h41);
    check_uart_frame(8'h41);

    wait (tx_done_o == 1'b1);
    @(posedge clk);

    check_signal(tx_done_o, 1'b1, "tx_done_o after full frame");

    @(posedge clk);
    check_signal(tx_busy_o, 1'b0, "tx_busy_o final");

    $display("========================================");
    $display(" UART TX Test PASS");
    $display("========================================");

    #1000;
    $finish;
end

endmodule