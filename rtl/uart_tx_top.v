`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/29 19:59:39
// Design Name: 
// Module Name: uart_tx_top
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


module uart_tx_top (
    clk,rst_n,uart_tx_o
);

input clk;
input rst_n;
output uart_tx_o;

localparam CLK_FREQ_HZ  = 125_000_000;
localparam BAUD_RATE    = 115200;
localparam integer SEND_INTERVAL = 125_000_000;
reg             tx_start;
wire    [7:0]   tx_data = 8'h41;
wire            tx_busy;
wire            tx_done;
reg     [26:0]  send_cnt;
wire    [27:0]  send_cnt_inc = send_cnt + 1'b1;  
wire            send_cnt_end = (send_cnt_inc == SEND_INTERVAL) ? 1'b1 : 1'b0;  
wire    [26:0]  send_cnt_next = (send_cnt_end) ? 27'b0 : send_cnt_inc [26:0];  


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        send_cnt <= 27'b0; 
    end else begin
        send_cnt <= send_cnt_next;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_start <= 1'b0; 
    end else begin
        if (send_cnt_end && !tx_busy) tx_start <= 1'b1;
        else tx_start <= 1'b0;
    end
end

uart_tx # (
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .BAUD_RATE(BAUD_RATE)
  )
  uart_tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tx_start_i(tx_start),
    .tx_data_i(tx_data),
    .tx_o(uart_tx_o),
    .tx_busy_o(tx_busy),
    .tx_done_o(tx_done)
  );

endmodule