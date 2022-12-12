
module uart_rot_led_test(
	input clk,reset_n,
	input send_go,send_reverse,send_pause,
	input rx,
	output[7:0] sseg,
	output[5:0] sel
    );
	 wire [4:0] in0,in1,in2,in3;
	 uart_rot_led #(.N(25_000_000)) //Frequency will be 50MHz/turns = 50MHz/15M = 3.33Hz(0.3 sec per move)
		 rot_led
			(
			.clk(clk),
			.reset_n(reset_n),
			.rx(rx),
			.send_go(send_go),
			.send_pause(send_pause),
			.send_reverse(send_reverse),
			.in_0(in0),
			.in_1(in1),
			.in_2(in2),
			.in_3(in3)
			 );
	 
	disp_hex_mux led_mux
		(
		.clk(clk),
		.reset_n(reset_n),
		.in_0({1'b0,in0}),
		.in_1({1'b0,in1}),
		.in_2({1'b0,in2}),
		.in_3({1'b0,in3}),
		.sseg(sseg),
		.sel(sel)
		 );

endmodule