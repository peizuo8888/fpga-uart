module uart_echo_top #(
    parameter integer CLK_FREQ_HZ = 125_000_000,
    parameter integer BAUD_RATE   = 115_200
)(
    input  wire clk,
    input  wire rst_n,

    input  wire uart_rx_i,
    output wire uart_tx_o
);
wire [7:0]  rx_data;
wire        rx_valid;
wire        rx_busy;

reg         tx_start;       //DONE
reg  [7:0]  tx_data;        //DONE
wire        tx_busy;        
wire        tx_done;        
reg  [7:0]  pending_data;   //DONE
reg         pending_valid;  //DONE

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_start <= 1'b0;
        tx_data  <= 8'b0;
        pending_data    <= 8'b0;
        pending_valid   <= 1'b0;
    end else begin
        tx_start <= 1'b0;
        if (!tx_busy) begin
            if (pending_valid) begin
                tx_start    <= 1'b1;
                tx_data     <= pending_data;
                if (rx_valid) begin
                    pending_data    <= rx_data;
                    pending_valid   <= 1'b1;
                end else begin
                    pending_valid   <= 1'b0; 
                end
            end else begin
               if (rx_valid) begin
                    tx_data     <= rx_data;
                    tx_start    <= 1'b1;
               end
            end
        end else begin
            if (rx_valid && !pending_valid) begin
               pending_data     <= rx_data;
               pending_valid    <= 1'b1; 
            end
        end
    end
end
// assign tx_start =  (!tx_busy && (pending_valid || rx_valid));
// assign tx_data  =  (pending_valid) ? pending_data : rx_data;

uart_rx #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .BAUD_RATE(BAUD_RATE)
)uart_rx_inst(
    .clk(clk),       
    .rst_n(rst_n),     
    .rx_i(uart_rx_i),      
    .rx_data_o(rx_data),       
    .rx_valid_o(rx_valid),
    .rx_busy_o(rx_busy)  
);
uart_tx #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .BAUD_RATE(BAUD_RATE)
)uart_tx_inst(
    .clk(clk),   
    .rst_n(rst_n),     
    .tx_start_i(tx_start), 
    .tx_data_i(tx_data), 
    .tx_o(uart_tx_o),       
    .tx_busy_o(tx_busy),  
    .tx_done_o(tx_done)    
);

endmodule
