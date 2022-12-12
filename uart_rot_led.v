module uart_rot_led #(parameter N=25_000_000)
(
	input clk,reset_n,
	input rx,
	input send_go,send_reverse,send_pause,
	output [4:0] in_0,in_1,in_2,in_3
);
localparam WORDS_NUM = 10;

reg [5*WORDS_NUM-1:0] words_reg={
	{1'b0,4'd0},
	{1'b0,4'd1},
	{1'b0,4'd2},
	{1'b0,4'd3},
	{1'b0,4'd4},
	{1'b0,4'd5},
	{1'b0,4'd6},
	{1'b0,4'd7},
	{1'b0,4'd8},
	{1'b0,4'd9}
};
reg wr_uart_reg,wr_uart_next;
reg [7:0] wr_data_reg, wr_data_next;

reg [5*WORDS_NUM-1:0] words_next;
reg [24:0] counter_reg=0;
wire [24:0] counter_next;
reg en_reg=0,en_next;
reg dir_reg=0, dir_next;
reg rd_uart,wr_uart;
wire counter_max;
wire rx_empty;
wire [7:0] rd_data;

always @(posedge clk or negedge reset_n)
begin
	if(~reset_n)
	begin
		counter_reg <=0;
		words_reg<={
				{1'b0,4'd0},
				{1'b0,4'd1},
				{1'b0,4'd2},
				{1'b0,4'd3},
				{1'b0,4'd4},
				{1'b0,4'd5},
				{1'b0,4'd6},
				{1'b0,4'd7},
				{1'b0,4'd8},
				{1'b0,4'd9}};
		en_reg <= 0;
		dir_reg<=0;
	end
	else
	begin
		en_reg <= en_next;
		dir_reg<=dir_next;
		if(en_reg)
		begin
			counter_reg<= counter_next;
			words_reg <= words_next;
		end
	end
end

assign counter_next = (counter_reg == N)?0:counter_reg + 1;
assign counter_max = (counter_reg == N)?1 : 0;

always @(*)
begin
	rd_uart=0;
	en_next =en_reg;
	dir_next = dir_reg;
	words_next = words_reg;
	if(counter_max) words_next = (~dir_reg)? {words_reg[5*WORDS_NUM-6:0],words_reg[5*WORDS_NUM-1:5*WORDS_NUM-5]}:
													{words_reg[4:0],words_reg[5*WORDS_NUM-1:5]};
	if(~rx_empty)
	begin
		rd_uart=1;
		if(rd_data == 8'h47)
		begin
			en_next = 1;
		end
		else if(rd_data == 8'h50)
		begin
			en_next = 0;
		end
		else if(rd_data == 8'h44)
		begin
			dir_next = ~dir_reg;
		end
	end
end

assign in_3 = words_reg[5*WORDS_NUM-1:5*WORDS_NUM-5];
assign in_2 = words_reg[5*WORDS_NUM-6:5*WORDS_NUM-10];
assign in_1 = words_reg[5*WORDS_NUM-11:5*WORDS_NUM-15];
assign in_0 = words_reg[5*WORDS_NUM-16:5*WORDS_NUM-20];

always @(posedge clk or negedge reset_n)
	 begin
		if(~reset_n)
		begin
			wr_uart_reg <= 0;
			wr_data_reg <= 0; 
		end
		else
		begin
			wr_data_reg <= wr_data_next;
			wr_uart_reg <= wr_uart_next;
		end
	 end
	 always @(*)
	 begin
		wr_data_next = wr_data_reg;
		wr_uart_next = 0;
		if(send_go_tick)
		begin
			wr_uart_next=1;
			wr_data_next = 8'h47 ;
		end
		else if(send_pause_tick)
		begin
			wr_uart_next=1;
			wr_data_next = 8'h50 ;
		end
		else if(send_reverse_tick)
		begin
			wr_uart_next=1;
			wr_data_next= 8'h44;
		end
	 end

	db_fsm m2
	(
		.clk(clk),
		.reset_n(reset_n),
		.sw(!send_go),
		.db_level(),
		.db_tick(send_go_tick)
   );
	db_fsm m3
	(
		.clk(clk),
		.reset_n(reset_n),
		.sw(!send_reverse),
		.db_level(),
		.db_tick(send_reverse_tick)
   );
	db_fsm m4
	(
		.clk(clk),
		.reset_n(reset_n),
		.sw(!send_pause),
		.db_level(),
		.db_tick(send_pause_tick)
   );

uart #(.DBIT(8),.SB_TICK(16),.DVSR(326),.DVSR_WIDTH(9),.FIFO_ADDR_WIDTH(4),
	.FIFO_DATA_WIDTH(8)) uart_inst
(
		.clk(clk),
		.reset_n(reset_n),
		.rd_uart(rd_uart),
		.wr_uart(wr_uart_reg),
		.wr_data(wr_data_reg),
		.rx(rx),
		.tx(tx),
		.rd_data(rd_data),
		.rx_empty(rx_empty),
		.tx_full()
);
endmodule