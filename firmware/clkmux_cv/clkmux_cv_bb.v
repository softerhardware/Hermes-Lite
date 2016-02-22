
module clkmux_cv (
	inclk2x,
	inclk1x,
	inclk0x,
	clkselect,
	outclk);	

	input		inclk2x;
	input		inclk1x;
	input		inclk0x;
	input	[1:0]	clkselect;
	output		outclk;
endmodule
