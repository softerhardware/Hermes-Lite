//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// Major portions ripped-off from USRP FPGA verilog code Copyright (C) 2003 Matt Ettus
//
// HPSDR Phase Accumulator
// P. Covington N8VB
// Phase Accumulator
//
// Inputs:
// clk - clock 
// reset - reset bit, resets the phase accumulator to 0;
// frequency - tuning word/dword, size based on RESOLUTION parameter, default = 32
//
// Outputs:
// phase_out - phase accumulator current value, size based on RESOLUTION parameter, default = 32
//
module phase_accumulator(clk,reset,frequency,phase_out);
	parameter RESOLUTION = 32;
	
	input	clk;
	input	reset;
	input	[RESOLUTION-1:0] frequency;
	
	output reg [RESOLUTION-1:0] phase_out;
	
	always @(posedge clk)
		if(reset)
			phase_out <= #1 32'b0; // reset the phase accumulator to 0
		else
			phase_out <= #1 phase_out + frequency; // add frequency increment to phase accumulator			
endmodule