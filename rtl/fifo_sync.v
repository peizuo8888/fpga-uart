`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/04 14:53:27
// Design Name: 
// Module Name: fifo_sync
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


module fifo_sync #(
    parameter integer DATA_WIDTH = 8,
    parameter integer DEPTH      = 512,
    parameter integer ADDR_WIDTH = 9
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // Write interface
    input  wire                  wr_en_i,       //DONE
    input  wire [DATA_WIDTH-1:0] wr_data_i,     //DONE

    // Read interface
    input  wire                  rd_en_i,
    output reg  [DATA_WIDTH-1:0] rd_data_o,     //DONE
    output reg                   rd_valid_o,    //DONE

    // Status
    output wire                  full_o,        //DONE
    output wire                  empty_o,       //DONE
    // output wire                  almost_full_o,
    // output wire                  almost_empty_o,
    output reg [ADDR_WIDTH:0]   level_o         //DONE
);

reg     [DATA_WIDTH-1:0] mem [0:DEPTH-1];       //DONE
reg     [ADDR_WIDTH-1:0] wr_ptr;                //DONE
reg     [ADDR_WIDTH-1:0] rd_ptr;                //DONE

always @(posedge clk or negedge rst_n) begin
    if (wr_en_i && !full_o) begin
        mem [wr_ptr] <= wr_data_i;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) wr_ptr <= {ADDR_WIDTH{1'b0}};
    else if (wr_en_i && !full_o) wr_ptr <= wr_ptr + 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) rd_ptr <= {ADDR_WIDTH{1'b0}};
    else if (rd_en_i && !empty_o) rd_ptr <= rd_ptr + 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_valid_o <= 1'b0;
    end else begin
        if (rd_en_i && !empty_o)    rd_valid_o <= 1'b1;
        else                        rd_valid_o <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) rd_data_o <= {DATA_WIDTH{1'b0}};
    else        rd_data_o <= mem [rd_ptr];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        level_o <= {ADDR_WIDTH{1'b0}};
    end else begin
        case ({wr_en_i , rd_en_i})
            2'b00: level_o <= level_o;
            2'b01: level_o <= (level_o != {ADDR_WIDTH{1'b0}}) ? level_o - 1'b1 : level_o;
            2'b10: level_o <= (level_o != DEPTH) ? level_o + 1'b1 : level_o;
            2'b11: level_o <= level_o;
            default: level_o <= level_o;
        endcase
    end
end

assign empty_o = (level_o == {ADDR_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
assign full_o  = (level_o == DEPTH) ? 1'b1 : 1'b0;


endmodule
