`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/29 19:06:11
// Design Name: 
// Module Name: uart_tx
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


module uart_tx #(
    parameter integer CLK_FREQ_HZ = 125_000_000,
    parameter integer BAUD_RATE   = 115_200
)(
    input  wire       clk,          //DONE
    input  wire       rst_n,        //DONE

    input  wire       tx_start_i,   //DONE
    input  wire [7:0] tx_data_i,    //DONE

    output reg        tx_o,         //DONE
    output wire       tx_busy_o,    //DONE
    output wire       tx_done_o     //DONE 
);

localparam integer DATA_BIT = 8;
localparam integer BAUD_DIV = CLK_FREQ_HZ / BAUD_RATE ;

localparam  IDLE    = 5'b00001,
            START   = 5'b00010,
            DATA    = 5'b00100,
            STOP    = 5'b01000,
            DONE    = 5'b10000;

reg [4:0] cr_state;
reg [4:0] nt_state; 
reg [7:0] data_buffer;

function integer clog2;
input integer value;
integer i;
begin
    clog2 = 0;
    for (i = value -1 ; i > 0 ; i = i >> 1) begin
        clog2 = clog2 + 1;
    end
end
endfunction

localparam BAUD_CNT_W = clog2(BAUD_DIV);

reg     [BAUD_CNT_W - 1:0]  baud_cnt;
wire    [BAUD_CNT_W    :0]  baud_cnt_inc    = baud_cnt + 1'b1;
wire                        baud_cnt_end    = (baud_cnt_inc == BAUD_DIV) ? 1'b1 : 1'b0;
wire    [BAUD_CNT_W - 1:0]  baud_cnt_next   = (baud_cnt_end) ? {BAUD_CNT_W {1'b0}} : baud_cnt_inc [BAUD_CNT_W-1:0]; 
wire                        baud_tick       = baud_cnt_end;


reg     [2:0]               bit_cnt;
wire    [3:0]               bit_cnt_inc    = bit_cnt + 1'b1;
wire                        bit_cnt_end    = (bit_cnt_inc == DATA_BIT) ? 1'b1 : 1'b0;
wire    [2:0]               bit_cnt_next   = (bit_cnt_end) ? 3'b0 : bit_cnt_inc [2:0]; 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////          
assign tx_busy_o = (cr_state == START || cr_state == DATA || cr_state == STOP) ? 1'b1 : 1'b0;
assign tx_done_o = (cr_state == DONE) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_cnt <= {BAUD_CNT_W{1'b0}};
    end else begin
        if (cr_state == IDLE || cr_state == DONE) baud_cnt <= {BAUD_CNT_W{1'b0}};            
        else baud_cnt <= baud_cnt_next;            
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt <= 3'b0;
    end else begin
        if (baud_tick) begin
            if (cr_state == DATA) begin
                bit_cnt <= bit_cnt_next;
            end else bit_cnt <= 3'b0;
        end
    end
end

always @(*) begin
    if (!rst_n) begin
        tx_o = 1'b1;
    end else begin
        case (cr_state)
            IDLE    :   tx_o = 1'b1; 
            START   :   tx_o = 1'b0; 
            DATA    :   tx_o = data_buffer [0]; 
            STOP    :   tx_o = 1'b1; 
            DONE    :   tx_o = 1'b1; 
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_buffer <= 8'b0;
    end else begin
        if (cr_state == IDLE && tx_start_i) begin
            data_buffer <= tx_data_i;     
        end else if(cr_state == DATA && baud_tick) data_buffer <= data_buffer >> 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cr_state <= IDLE;
    end else begin
        case (cr_state)
        IDLE:begin
            if (tx_start_i) begin
                cr_state    <= START;
            end
        end 
        START:begin
            if (baud_tick) begin
                cr_state <= DATA;
            end
        end 
        DATA:begin  
            if (baud_tick && bit_cnt_end) begin
                cr_state <= STOP;
            end
        end 
        STOP:begin
            if (baud_tick) begin
                cr_state <= DONE;
            end
        end 
        DONE:cr_state <= IDLE;
        endcase
    end
end

endmodule