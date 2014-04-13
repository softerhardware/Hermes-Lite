//
//  HPSDR - High Performance Software Defined Radio
//
//  Hermes code. 
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

// Polyphase decimating filter

// Based on firX8R8 by James Ahlstrom, N2ADR,  (C) 2011
// Modified for use with HPSDR by Phil Harman, VK6PH, (C) 2013


// This is a decimate by 2 dual bank Polyphase FIR filter. Since it decimates by 2 the output signal
// level will be 1/2 the input level.  The filter coeficients are distributed between the 4 
// FIR filters such that the first FIR receives coeficients 0, 2, 4... the second 1, 3, 5.. 
// There is no need to compensate for the sinx/x shape of the preceeding CIC filters. This is because
// the cascade of the two filters decimates by 8 and the droop of the CIC at 1/8th its fs/2 is neglibible. 

// The filter coefficients are calculated as per normal.  The basic FIR design is for a 512 TAP, 0.01dB ripple, 110dB ultimate 
// rejection FIR. Note that when designing the basic FIR that it decimates by 2 hence the output bandwith will be 1/4 the design
// sampling rate. 

// Where fractional coefficients are generated these are converted to signed 18 bit integer values and modified such that 
// the largest coefficient = 2^17 - 1.

// The coefficients are split intially into 2 files; one containing the odd coefficients and the other the even. Each 
// file is then split into two where the 'a' suffix file contains coefficients 0 to 127 and the 'b' file the 128 to 255th.

// The filter coefficients are in the files "coefEa.mif", "coefEb.mif", "coefFa.mif" and "coefFb.mif". 
// Note that the RAM length needs to be 2 * TAPS because the initial RAM write address of the 'b' coefficient FIR is 
// equal to TAPS rather than zero.


//
// ROM init file:		REQUIRED, with 256 or 512 coefficients.  
// Number of taps:	NTAPS.
// Input bits:			24 fixed.
// Output bits:		OBITS, default 24.
// Adder bits:			ABITS, default 24.

// This requires eight MifFile's.
// Maximum NTAPS is 8 * (previous and current decimation) less overhead.
// Maximum NTAPS is 2048 (or less).

/*
   Max mumber of TAPS is approx 128 in order to meet max sampling rate requirements. We need 512 taps
   for the 0.01dB ripple, 110dB stop band decimate by 2 Polyphase FIR.  In order to do this use two banks
   of coefficients, one holds coefficients 0 - 127 and the other 128 - 255.
   In which case the second bank of RAM needs to have the input data written at starting address 128 rather
   than 0 in order that the MAC data is received at the correct time.
   
   Each FIR works as follows:
   
    RAM address     0     1     2     3     4     5     6     7   etc
						-----------------------------------------------
						|     |     |     |     |     |     |     |     
						|	   |     |     |     |     |     |     |     
						------------------------------------------------
				
    Coeff address    0     1     2     3     4     5     6     7   etc
						-----------------------------------------------
						|     |     |     |     |     |     |     |     
						| h0  |  h1 | h2  | h3  | h4  | h5  | h6  | h7    
						------------------------------------------------	
				  
				  
    At reset the ROM and RAM addresses are set to 0 (128 in the case of the second RAM bank)
    The first sample is written to RAM address 0 (128). This cause the sample to be multiplied
    by h0 and accumulated. The RAM address is then decremented and the ROM address incremented.
    The sample in the new RAM address is multiplied by the coefficient from the new ROM address.  
    This process is repeated TAPS times. The code then waits for the next sample to arrive which 
    is written to RAM address +1. This sample is then multiplied by h0 etc and the process is
    continued TAPS times.		
*/


module firX2R2 (	
	input clock,
	input x_avail,									// new sample is available
	input signed [INBITS-1:0] x_real,			// x is the sample input
	input signed [INBITS-1:0] x_imag,
	output y_avail,								// new output is available
	output wire signed [OBITS-1:0] y_real,	// y is the filtered output
	output wire signed [OBITS-1:0] y_imag);
	
	localparam ADDRBITS	= 8;					// Address bits for 18/48 x 256 rom/ram blocks
   localparam INBITS    = 24;					// width of I and Q input samples	
	
	parameter
		TAPS 			= 128,						// Number of coefficients per FIR - total is 128 * 4 = 512
   	ABITS			= 24,							// adder bits
		OBITS			= 24;							// output bits
	
	reg [4:0] wstate;								// state machine for write samples
	
	reg  [ADDRBITS-1:0] waddr, raddr;		// write sample memory address
	wire weA, weB, weC, weD;
	reg  signed [ABITS-1:0] Racc, Iacc;
	wire signed [ABITS-1:0] RaccAa, RaccBa, RaccAb, RaccBb;
	wire signed [ABITS-1:0] IaccAa, IaccBa, IaccAb, IaccBb;	
	
// Output is the result of adding 2 by 24 bit results so Racc and Iacc need to be 
// 24 + log2(2) = 24 + 1 = 25 bits wide to prevent DC spur.
// However, since we decimate by 2 the output will be 1/2 the input. Hence we 
// use 24 bits for the Accumulators. 

	assign y_real = Racc[ABITS-1:0];  
	assign y_imag = Iacc[ABITS-1:0];
	
	initial
	begin
		wstate = 0;
		waddr = 0;
		raddr = 0;
	end
	
	always @(posedge clock)
	begin
		if (wstate == 2) wstate <= wstate + 1'd1;	// used to set y_avail
		if (wstate == 3) begin
			wstate <= 0;									// reset state machine and increment RAM write address
			waddr <= waddr + 1'd1;
			raddr <= waddr;
		end
		if (x_avail)
		begin
			wstate <= wstate + 1'd1;
			case (wstate)
				0:	begin											// wait for the first x input
						Racc <= RaccAa + RaccAb;			// add accumulators from 'a' and 'b' FIRs
						Iacc <= IaccAa + IaccAb;
					end
				1:	begin											// wait for the next x input
						Racc <= Racc + RaccBa + RaccBb;		
						Iacc <= Iacc + IaccBa + IaccBb;
					end
			endcase
		end
	end
	
	
	// Enable each FIR in sequence
   assign weA 		= (x_avail && wstate == 0);
	assign weB 		= (x_avail && wstate == 1);

	
	// at end of sequence indicate new data is available
	assign y_avail = (wstate == 2);
	
	// Dual bank polyphase decimate by 2 FIR. Note that second bank needs a RAM write offset of TAPS.

	fir256d #("coefEa.mif", ABITS, TAPS) A (clock, waddr, raddr, weA, x_real, x_imag, RaccAa, IaccAa);					// first bank odd coeff
	fir256d #("coefEb.mif", ABITS, TAPS) B (clock, (waddr + 8'd128), raddr, weA, x_real, x_imag, RaccAb, IaccAb);	// second bank
	fir256d #("coefFa.mif", ABITS, TAPS) C (clock, waddr, raddr, weB, x_real, x_imag, RaccBa, IaccBa);  				// first bank even coeff
	fir256d #("coefFb.mif", ABITS, TAPS) D (clock, (waddr + 8'd128), raddr, weB, x_real, x_imag, RaccBb, IaccBb); 	// second bank


endmodule


// This filter waits until a new sample is written to memory at waddr.  Then
// it starts by multiplying that sample by coef[0], the next prior sample
// by coef[1], (etc.) and accumulating.  For R=2 decimation, coef[1] is the
// coeficient prior to coef[0].
// When reading from the RAM we need to allow 3 clock pulses from presenting the 
// read address until the data is available. 

module fir256d(

	input clock,
	input [ADDRBITS-1:0] waddr,							// memory write address
	input [ADDRBITS-1:0] raddr,							// memory read address
	input we,													// memory write enable
	input signed [INBITS-1:0] x_real,						// sample to write
	input signed [INBITS-1:0] x_imag,
	output reg signed [ABITS-1:0] Raccum,
	output reg signed [ABITS-1:0] Iaccum
	);

	localparam ADDRBITS	= 8;								// Address bits for 18/36 X 256 rom/ram blocks
	localparam COEFBITS	= 18;								// coefficient bits
	localparam INBITS		= 24;								// I and Q sample width 
	
	parameter MifFile	= "xx.mif";							// ROM coefficients
	parameter ABITS	= 0;									// adder bits
	parameter TAPS		= 0;									// number of filter taps, max 2**ADDRBITS

	reg [ADDRBITS-1:0] caddr;								// read address for  coef
	wire [INBITS*2-1:0] q;									// I/Q sample read from memory
	reg  [INBITS*2-1:0] reg_q;
	wire signed [INBITS-1:0] q_real, q_imag;			// I/Q sample read from memory
	wire signed [COEFBITS-1:0] coef; 	      		// coefficient read from memory
	reg signed  [COEFBITS-1:0] reg_coef; 				// coefficient read from memory
	reg signed  [41:0] Rmult, Imult;						// multiplier result   24 * 18 bits = 42 bits 
	reg signed  [41:0] RmultSum, ImultSum;				// multiplier result
	reg [ADDRBITS:0] counter;								// count TAPS samples
   reg [ADDRBITS-1:0] read_address;	
	
	
	assign q_real = reg_q[INBITS*2-1:INBITS];
	assign q_imag = reg_q[INBITS-1:0];

	firromH #(MifFile) roma (caddr, clock, coef);		// coefficient ROM 18 X 256
	firram48 rama (clock, {x_real, x_imag}, read_address, waddr, we, q);  	// sample RAM 48 X 256;  48 bit = 24 bits I and 24 bits Q

	
	always @(posedge clock)
	begin
		if (we)		// Wait until a new sample is written to memory
			begin
				counter <= TAPS[ADDRBITS:0] + 4;			// count samples and pipeline latency (delay of 3 clocks from address being presented)
				read_address <= raddr;						// RAM read address -> newest sample
				caddr <= 1'd0;									// start at coefficient zero
				Raccum <= 0;
				Iaccum <= 0;
			end
		else
			begin		// main pipeline here
				if (counter < (TAPS[ADDRBITS:0] + 2))
				begin
					Rmult <= q_real * reg_coef;
					Imult <= q_imag * reg_coef;
					Raccum <= Raccum + Rmult[41:18] + Rmult[17];  // truncate 42 bits down to 24 bits to prevent DC spur
					Iaccum <= Iaccum + Imult[41:18] + Imult[17];
				end
				if (counter > 0)
				begin
					counter <= counter - 1'd1;
					read_address <= read_address - 1'd1;	// move to prior sample
					caddr <= caddr + 1'd1;						// move to next coefficient
					reg_q <= q;
					reg_coef <= coef;
				end
			end
	end
endmodule
