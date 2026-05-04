`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/04 14:53:51
// Design Name: 
// Module Name: tb_fifo_sync
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


module tb_fifo_sync;

    // ============================================================
    // Parameter
    // ============================================================
    localparam integer DATA_WIDTH = 8;
    localparam integer DEPTH      = 16;
    localparam integer ADDR_WIDTH = 4;

    localparam integer CLK_PERIOD = 10;

    // ============================================================
    // DUT signals
    // ============================================================
    reg                     clk;
    reg                     rst_n;

    reg                     wr_en_i;
    reg  [DATA_WIDTH-1:0]   wr_data_i;

    reg                     rd_en_i;
    wire [DATA_WIDTH-1:0]   rd_data_o;
    wire                    rd_valid_o;

    wire                    full_o;
    wire                    empty_o;
    wire                    almost_full_o;
    wire                    almost_empty_o;
    wire [ADDR_WIDTH:0]     level_o;

    integer                 error_count;
    integer                 i;

    // ============================================================
    // DUT
    // ============================================================
    fifo_sync #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_sync (
        .clk            (clk),
        .rst_n          (rst_n),

        .wr_en_i        (wr_en_i),
        .wr_data_i      (wr_data_i),

        .rd_en_i        (rd_en_i),
        .rd_data_o      (rd_data_o),
        .rd_valid_o     (rd_valid_o),

        .full_o         (full_o),
        .empty_o        (empty_o),
        //.almost_full_o  (almost_full_o),
        //.almost_empty_o (almost_empty_o),
        .level_o        (level_o)
    );

    // ============================================================
    // Clock generation
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // ============================================================
    // Waveform dump
    // ============================================================
    initial begin
        $dumpfile("tb_fifo_sync.vcd");
        $dumpvars(0, tb_fifo_sync);
    end

    // ============================================================
    // Task: apply reset
    // ============================================================
    task apply_reset;
        begin
            rst_n     = 1'b0;
            wr_en_i   = 1'b0;
            wr_data_i = {DATA_WIDTH{1'b0}};
            rd_en_i   = 1'b0;

            repeat (5) @(posedge clk);

            rst_n = 1'b1;

            repeat (2) @(posedge clk);
        end
    endtask

    // ============================================================
    // Task: check status
    // ============================================================
    task check_status;
        input expected_empty;
        input expected_full;
        input [ADDR_WIDTH:0] expected_level;
        begin
            #1;

            if (empty_o !== expected_empty) begin
                $display("[ERROR] empty_o mismatch. expected=%0d, got=%0d, time=%0t",
                         expected_empty, empty_o, $time);
                error_count = error_count + 1;
            end

            if (full_o !== expected_full) begin
                $display("[ERROR] full_o mismatch. expected=%0d, got=%0d, time=%0t",
                         expected_full, full_o, $time);
                error_count = error_count + 1;
            end

            if (level_o !== expected_level) begin
                $display("[ERROR] level_o mismatch. expected=%0d, got=%0d, time=%0t",
                         expected_level, level_o, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    // ============================================================
    // Task: FIFO write
    // ============================================================
    task fifo_write;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge clk);
            wr_en_i   = 1'b1;
            wr_data_i = data;

            @(negedge clk);
            wr_en_i   = 1'b0;
            wr_data_i = {DATA_WIDTH{1'b0}};
        end
    endtask

    // ============================================================
    // Task: FIFO read and check
    // ============================================================
    task fifo_read_check;
        input [DATA_WIDTH-1:0] expected_data;
        begin
            @(negedge clk);
            rd_en_i = 1'b1;

            @(posedge clk);
            #1;

            if (rd_valid_o !== 1'b1) begin
                $display("[ERROR] rd_valid_o should be 1. time=%0t", $time);
                error_count = error_count + 1;
            end

            if (rd_data_o !== expected_data) begin
                $display("[ERROR] rd_data_o mismatch. expected=0x%02h, got=0x%02h, time=%0t",
                         expected_data, rd_data_o, $time);
                error_count = error_count + 1;
            end

            @(negedge clk);
            rd_en_i = 1'b0;
        end
    endtask

    // ============================================================
    // Task: empty read check
    // ============================================================
    task empty_read_check;
        begin
            @(negedge clk);
            rd_en_i = 1'b1;

            @(posedge clk);
            #1;

            if (rd_valid_o !== 1'b0) begin
                $display("[ERROR] rd_valid_o should be 0 when FIFO is empty. time=%0t", $time);
                error_count = error_count + 1;
            end

            if (level_o !== 0) begin
                $display("[ERROR] level_o should remain 0 when reading empty FIFO. got=%0d, time=%0t",
                         level_o, $time);
                error_count = error_count + 1;
            end

            @(negedge clk);
            rd_en_i = 1'b0;
        end
    endtask

    // ============================================================
    // Task: write while full check
    // ============================================================
    task full_write_check;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge clk);
            wr_en_i   = 1'b1;
            wr_data_i = data;

            @(posedge clk);
            #1;

            if (level_o !== DEPTH) begin
                $display("[ERROR] level_o should remain DEPTH when writing full FIFO. got=%0d, time=%0t",
                         level_o, $time);
                error_count = error_count + 1;
            end

            if (full_o !== 1'b1) begin
                $display("[ERROR] full_o should remain 1 when writing full FIFO. time=%0t", $time);
                error_count = error_count + 1;
            end

            @(negedge clk);
            wr_en_i   = 1'b0;
            wr_data_i = {DATA_WIDTH{1'b0}};
        end
    endtask

    // ============================================================
    // Task: simultaneous read and write
    // ============================================================
    task simultaneous_read_write_check;
        input [DATA_WIDTH-1:0] wr_data;
        input [DATA_WIDTH-1:0] expected_rd_data;
        input [ADDR_WIDTH:0]   expected_level;
        begin
            @(negedge clk);
            wr_en_i   = 1'b1;
            wr_data_i = wr_data;
            rd_en_i   = 1'b1;

            @(posedge clk);
            #1;

            if (rd_valid_o !== 1'b1) begin
                $display("[ERROR] rd_valid_o should be 1 during simultaneous read/write. time=%0t", $time);
                error_count = error_count + 1;
            end

            if (rd_data_o !== expected_rd_data) begin
                $display("[ERROR] simultaneous read data mismatch. expected=0x%02h, got=0x%02h, time=%0t",
                         expected_rd_data, rd_data_o, $time);
                error_count = error_count + 1;
            end

            if (level_o !== expected_level) begin
                $display("[ERROR] level_o should remain unchanged during simultaneous read/write. expected=%0d, got=%0d, time=%0t",
                         expected_level, level_o, $time);
                error_count = error_count + 1;
            end

            @(negedge clk);
            wr_en_i   = 1'b0;
            wr_data_i = {DATA_WIDTH{1'b0}};
            rd_en_i   = 1'b0;
        end
    endtask

    // ============================================================
    // Main test
    // ============================================================
    initial begin
        error_count = 0;

        // ------------------------------------------------------------
        // Test 1: Reset
        // ------------------------------------------------------------
        $display("==================================================");
        $display("TEST 1: Reset");
        $display("==================================================");

        apply_reset();
        check_status(1'b1, 1'b0, 0);

        // ------------------------------------------------------------
        // Test 2: Write 3 bytes
        // ------------------------------------------------------------
        $display("==================================================");
        $display("TEST 2: Write 3 bytes");
        $display("==================================================");

        fifo_write(8'hAA);
        check_status(1'b0, 1'b0, 1);

        fifo_write(8'h55);
        check_status(1'b0, 1'b0, 2);

        fifo_write(8'h02);
        check_status(1'b0, 1'b0, 3);

        // ------------------------------------------------------------
        // Test 3: Read 3 bytes
        // ------------------------------------------------------------
        $display("==================================================");
        $display("TEST 3: Read 3 bytes");
        $display("==================================================");

        fifo_read_check(8'hAA);
        check_status(1'b0, 1'b0, 2);

        fifo_read_check(8'h55);
        check_status(1'b0, 1'b0, 1);

        fifo_read_check(8'h02);
        check_status(1'b1, 1'b0, 0);

        // ------------------------------------------------------------
        // Test 4: Empty read protection
        // ------------------------------------------------------------
        $display("==================================================");
        $display("TEST 4: Empty read protection");
        $display("==================================================");

        empty_read_check();
        check_status(1'b1, 1'b0, 0);

        // ------------------------------------------------------------
        // Test 5: Write until full
        // ------------------------------------------------------------
        $display("==================================================");
        $display("TEST 5: Write until full");
        $display("==================================================");

        apply_reset();

        for (i = 0; i < DEPTH; i = i + 1) begin
            fifo_write(8'hA0 + i[7:0]);
        end

        check_status(1'b0, 1'b1, DEPTH);

        // ------------------------------------------------------------
        // Test 6: Full write protection
        // ------------------------------------------------------------
        $display("==================================================");
        $display("TEST 6: Full write protection");
        $display("==================================================");

        full_write_check(8'hFF);
        check_status(1'b0, 1'b1, DEPTH);

        // Data should not be overwritten
        for (i = 0; i < DEPTH; i = i + 1) begin
            fifo_read_check(8'hA0 + i[7:0]);
        end

        check_status(1'b1, 1'b0, 0);

        // ------------------------------------------------------------
        // Test 7: Simultaneous read and write
        // ------------------------------------------------------------
        $display("==================================================");
        $display("TEST 7: Simultaneous read and write");
        $display("==================================================");

        apply_reset();

        fifo_write(8'h11);
        fifo_write(8'h22);
        fifo_write(8'h33);

        check_status(1'b0, 1'b0, 3);

        // Read 0x11 and write 0x44 at the same cycle.
        // FIFO level should remain 3.
        simultaneous_read_write_check(8'h44, 8'h11, 3);

        fifo_read_check(8'h22);
        fifo_read_check(8'h33);
        fifo_read_check(8'h44);

        check_status(1'b1, 1'b0, 0);

        // ------------------------------------------------------------
        // Final result
        // ------------------------------------------------------------
        $display("==================================================");
        if (error_count == 0) begin
            $display("FIFO TEST PASS");
        end else begin
            $display("FIFO TEST FAIL, error_count = %0d", error_count);
        end
        $display("==================================================");

        #100;
        $finish;
    end

endmodule