`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/30 22:20:53
// Design Name: 
// Module Name: uart_rx
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


module uart_rx #(
    parameter integer CLK_FREQ_HZ = 125_000_000,
    parameter integer BAUD_RATE   = 115_200
)(
    input   wire        clk,            //DONE
    input   wire        rst_n,          //DONE
    input   wire        rx_i,           //DONE
    output  [7:0]       rx_data_o,      //DONE      
    output              rx_valid_o,     //DONE
    output              rx_busy_o       //DONE
);

localparam integer DATA_BIT = 8;
localparam integer BAUD_DIV = CLK_FREQ_HZ / BAUD_RATE ;
localparam integer HALF_BIT = BAUD_DIV / 2;

localparam      IDLE    = 5'b00001,
                START   = 5'b00010,
                DATA    = 5'b00100,
                STOP    = 5'b01000,
                DONE    = 5'b10000;

reg [4:0] cr_state;                     //DONE
reg [4:0] nt_state; 
reg [7:0] data_buffer;                  //DONE
reg rx_meta;                            //DONE
reg rx_sync;                            //DONE

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

reg     [BAUD_CNT_W - 1:0]  baud_cnt;       //DONE
wire    [BAUD_CNT_W    :0]  baud_cnt_inc    = baud_cnt + 1'b1;
wire                        baud_cnt_end    = (baud_cnt_inc == BAUD_DIV) ? 1'b1 : 1'b0;
wire    [BAUD_CNT_W - 1:0]  baud_cnt_next   = (baud_cnt_end) ? {BAUD_CNT_W {1'b0}} : baud_cnt_inc [BAUD_CNT_W-1:0]; 
wire                        baud_tick       = baud_cnt_end;
wire                        half_tick       = (baud_cnt_inc == HALF_BIT) ? 1'b1 : 1'b0;

reg     [2:0]               bit_cnt;        //DONE
wire    [3:0]               bit_cnt_inc    = bit_cnt + 1'b1;
wire                        bit_cnt_end    = (bit_cnt_inc == DATA_BIT) ? 1'b1 : 1'b0;
wire    [2:0]               bit_cnt_next   = (bit_cnt_end) ? 3'b0 : bit_cnt_inc [2:0]; 

//////////////////////////////////////////////////////////////////////////////////////////////
assign rx_data_o    = data_buffer;
assign rx_valid_o   = (cr_state == DONE) ? 1'b1 : 1'b0;
assign rx_busy_o    = (cr_state == START || cr_state == DATA || cr_state == STOP) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_meta <= 1'b1;
        rx_sync <= 1'b1;
    end else begin
        rx_meta <= rx_i;
        rx_sync <= rx_meta;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_cnt <= {BAUD_CNT_W {1'b0}};
    end else begin
        case (cr_state)
            IDLE    : baud_cnt <= {BAUD_CNT_W {1'b0}};
            START   : baud_cnt <= (half_tick) ? {BAUD_CNT_W {1'b0}} : baud_cnt_next;
            DATA    : baud_cnt <= baud_cnt_next;
            STOP    : baud_cnt <= baud_cnt_next;
            DONE    : baud_cnt <= {BAUD_CNT_W {1'b0}}; 
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt <= 3'b0;
    end else begin
        case (cr_state)
            IDLE    : bit_cnt <= 3'b0;
            START   : bit_cnt <= 3'b0;
            DATA    : bit_cnt <= (baud_tick) ? bit_cnt_next : bit_cnt;
            STOP    : bit_cnt <= 3'b0;
            DONE    : bit_cnt <= 3'b0;
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cr_state <= IDLE;
    end else begin
        case (cr_state)
            IDLE:begin
                if (!rx_sync) begin
                    cr_state <= START;
                end
            end
            START:begin
                if (half_tick) begin
                    cr_state <= (rx_sync) ? IDLE : DATA;
                end
            end
            DATA:begin
                if (baud_tick && bit_cnt_end) begin
                    cr_state <= STOP;
                end
            end
            STOP:begin
                if (baud_tick) begin
                    cr_state <= (rx_sync) ? DONE : IDLE;
                end
            end
            DONE: cr_state <= IDLE; 
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_buffer <= 8'b0;
    end else begin
        case (cr_state)
            DATA:begin
                if (baud_tick) begin
                    data_buffer <= {rx_sync , data_buffer [7:1]};
                end
            end  
        endcase
    end
end

endmodule