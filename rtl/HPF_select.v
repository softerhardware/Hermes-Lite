// V1.0 19th November 2007
//
// Copyright 2006,2007 Phil Harman VK6APH
//
//  HPSDR - High Performance Software Defined Radio
//
//  Alex SPI interface.
//
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

//////////////////////////////////////////////////////////////
//
//		Alex Band Decoder & HPF selection
//
//////////////////////////////////////////////////////////////
/*
	V2.0 for V3 Alex	

	Each band is  decoded and the appropriate HPF selected as follows
	
	Bypass 	HPF = 6'b100000
	1.5MHz	HPF = 6'b010000
	6.5MHz	HPF = 6'b001000
	9.5MHz 	HPF = 6'b000100
    20MHz  	HPF = 6'b000010
	13MHz  	HPF = 6'b000001
	
*/

module HPF_select(clock,frequency,HPF);
input  wire        clock;
input  wire [31:0] frequency;
output reg   [5:0] HPF;

always @(posedge clock)
begin
if 		(frequency <  1416000) HPF <= 6'b100000;  // bypass
else if	(frequency <  6500000) HPF <= 6'b010000;	// 1.5MHz HPF	
else if (frequency <  9500000)  HPF <= 6'b001000;	// 6.5MHz HPF
else if (frequency < 13000000)  HPF <= 6'b000100;	// 9.5MHz HPF
else if (frequency < 20000000)  HPF <= 6'b000001;	// 13MHz HPF
else								     HPF <= 6'b000010;	// 20MHz HPF

end
endmodule