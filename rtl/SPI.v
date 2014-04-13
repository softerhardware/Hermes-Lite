// V1.0 25th October 2007
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
//		Alex SPI interface
//
//////////////////////////////////////////////////////////////

/*
	data to send to Alex Tx filters is in the following format:

	Bit 15 - NC					U2 - D0
	Bit 14 - NC					U2 - D1
	Bit 13 - NC					U2 - D2
	Bit 12 - Yellow Led		U2 - D3
	Bit 11 - 30/20m			U2 - D4
	Bit 10 - 60/40m			U2 - D5
	Bit  9 - 80m				U2 - D6
	Bit  8 - 160m				U2 - D7

	Bit  7 - Ant #1			U4 - D0
	Bit  6 - Ant #2			U4 - D1
	Bit  5 - Ant #3			U4 - D2
	Bit  4 - T/R relay		U4 - D3
	Bit  3 - Red Led			U4 - D4
	Bit  2 - 6m					U4 - D5
	Bit  1 - 12/10m			U4 - D6
	Bit  0 - 17/15m			U4 - D7

	Relay selection data is contained in [6:0]LPF
	
	data to send to Alex Rx filters is in the folowing format:
	

	Bit 15 - RED LED 			U28 - QA
	Bit 14 - 1.5 MHz HPF 	U28 - QB
	Bit 13 - 6.5 MHz HPF 	U28 - QC
	Bit 12 - 9.5 MHz HPF 	U28 - QD
	Bit 11 - 6M Preamp 		U28 - QE
	Bit 10 - 13 MHz HPF 		U28 - QF
	Bit 09 - 20 MHz HPF 		U28 - QG
	Bit 08 - Bypass 			U28 - QH
	Bit 07 - 10 dB Atten. 	U30 - QA
	Bit 06 - 20 dB Atten. 	U30 - QB
	Bit 05 - Transverter	RX U30 - QC
	Bit 04 - RX 2 In 			U30 - QD
	Bit 03 - RX 1 In 			U30 - QE
	Bit 02 - RX 1 OUT 		U30 - QF Low = Default Receive Path
	Bit 01 - N.C.				U30 - QG
	Bit 00 - YELLOW LED 		U30 - QH
	
	Relay selection data is contained in [5:0]HPF
	All outputs are active high

	SPI data is sent to Alex whenever any of the above data changes

*/

module SPI(Alex_data, SPI_data, SPI_clock, Rx_load_strobe, Tx_load_strobe, spi_clock);

input wire[31:0]Alex_data;
output reg SPI_data;
output reg SPI_clock;
output reg Rx_load_strobe;
output reg Tx_load_strobe;
input wire spi_clock;

reg [3:0]spi_state;
reg [4:0]data_count;
reg [31:0]previous_Alex_data;	// used to detect change in data


always @ (posedge spi_clock)
begin
case (spi_state)
0:	begin
		if (Alex_data != previous_Alex_data)begin
			data_count <= 31;				// set starting bit count to 31
			spi_state <= 1;
		end
		else spi_state <= 0; 			// wait for Alex data to change
	end		
1:	begin
	SPI_data <= Alex_data[data_count];	// set up data to send
	spi_state <= 2;
	end
2:	begin
	SPI_clock <= 1'b1;					// set clock high
	spi_state <= 3;
	end
3:	begin
	SPI_clock <= 1'b0;					// set clock low
	spi_state <= 4;
	end
4:	begin
		if (data_count == 16)begin		// transfer complete
			Tx_load_strobe <= 1'b1; 	// strobe Tx data
			spi_state <= 5;
		end
		else if(data_count == 0) begin
			Rx_load_strobe <= 1'b1;
			spi_state <= 6;
		end 
		else spi_state  <= 1;  			// go round again
	data_count <= data_count - 1'b1;
	end
5:	begin
	Tx_load_strobe <= 1'b0;				// reset Tx strobe
	spi_state <= 1;						// now do Rx data
	end
6:	begin
	Rx_load_strobe <= 1'b0;				// reset Rx strobe
	previous_Alex_data <= Alex_data; // save current data
	spi_state <= 0;						// reset for next run
	end
	
endcase
end

endmodule
