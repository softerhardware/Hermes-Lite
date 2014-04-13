// V1.0 25th October 2007
//
// Copyright 2006,2007 Phil Harman VK6APH
//
//  HPSDR - High Performance Software Defined Radio
//
//  Alex LPF selection.
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
//		Alex Band Decoder & LPF selection
//
//////////////////////////////////////////////////////////////
/*
	
	Each band is  decoded and the appropriate LPF selected as follows
	
	160m 	  		LPF = 7'b0001000
	 80m	  		LPF = 7'b0000100
	60/40m  		LPF = 7'b0000010
	30/20m  		LPF = 7'b0000001
    17/15m  	LPF = 7'b1000000
	12/10m  		LPF = 7'b0100000
	 6m	  		LPF = 7'b0010000
*/

module LPF_select(clock, frequency, LPF);
input  wire        clock;
input  wire [31:0] frequency;	
output reg   [6:0] LPF;

// Select highest LPF dependant on frequency in use, frequency is in Hz
		
always @(posedge clock)  
begin 
	if  	(frequency > 32000000) 	 LPF <= 7'b0010000;		// > 10m so use 6m LPF
	else if (frequency > 22000000) LPF <= 7'b0100000;  	// > 15m so use 12/10m LPF
	else if (frequency > 15000000) LPF <= 7'b1000000;  	// > 20m so use 17/15m LPF
	else if (frequency > 8000000)  LPF <= 7'b0000001;  	// > 40m so use 30/20m LPF  
	else if (frequency > 4500000)  LPF <= 7'b0000010;  	// > 80m so use 60/40m LPF
	else if (frequency > 2400000)  LPF <= 7'b0000100;  	// > 160m so use 80m LPF  
	else 						   		 LPF <= 7'b0001000; 		// < 2.4MHz so use 160m LPF
end 
endmodule
