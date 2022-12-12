module uart
#(parameter DBIT=8, SB_TICK = 16,
DVSR = 162, DVSR_WIDTH=12 , FIFO_ADDR_WIDTH = 4, FIFO_DATA_WIDTH=8)
(
	input clk,reset_n,
	input rd_uart, wr_uart, rx,
	input [7:0] wr_data,
	output tx_full, rx_empty, tx,
	output [7:0] rd_data
);
wire tick, rx_done_tick, tx_done_tick;
wire tx_empty,tx_fifo_not_empty;
wire [7:0] tx_fifo_out,rx_data_out;

baud_generator #(.DVSR_WIDTH(DVSR_WIDTH)) baud_generator_inst
(
	.clk(clk),.reset_n(reset_n),
	.baud_dvsr(DVSR),
	.s_tick(tick)
);
uart_rx uart_rx_unit
      (.clk(clk), .reset_n(reset_n), .data_bits(DBIT),.stop_bits(SB_TICK),
		.parity_bits(0), .rx(rx), .s_tick(tick),
       .rx_done_tick(rx_done_tick), .dout(rx_data_out));

fifo #(.W(FIFO_ADDR_WIDTH),.B(FIFO_DATA_WIDTH)) fifo_rx_unit
      (.clk(clk), .reset_n(reset_n), .rd(rd_uart),
       .wr(rx_done_tick), .wr_data(rx_data_out),
       .empty(rx_empty), .full(), .rd_data(rd_data));

fifo #(.W(FIFO_ADDR_WIDTH),.B(FIFO_DATA_WIDTH)) fifo_tx_unit
      (.clk(clk), .reset_n(reset_n), .rd(tx_done_tick),
       .wr(wr_uart), .wr_data(wr_data), .empty(tx_empty),
       .full(tx_full), .rd_data(tx_fifo_out));

uart_tx uart_tx_unit
      (.clk(clk), .reset_n(reset_n), .data_bits(DBIT), .stop_bits(SB_TICK),
		.parity_bits(0), .tx_start(tx_fifo_not_empty),
       .s_tick(tick), .din(tx_fifo_out),
       .tx_done_tick(tx_done_tick), .tx(tx));
		 
assign tx_fifo_not_empty = ~tx_empty;

endmodule