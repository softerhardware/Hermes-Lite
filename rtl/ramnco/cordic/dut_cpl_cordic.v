module dut_cpl_cordic;

	reg clk;
	reg signed [31:0] phase;
	wire signed [15:0] cos;

   	initial begin
    	$from_myhdl(clk, phase);
    	$to_myhdl(cos);
  	end

	cpl_cordic dut (.clock(clk), .frequency(phase), .in_data_I(16'h4c9a),			
		.in_data_Q(16'h0000), .out_data_I(cos), .out_data_Q());
endmodule