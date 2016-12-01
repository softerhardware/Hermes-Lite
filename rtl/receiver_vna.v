/*
--------------------------------------------------------------------------------
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.
This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.
You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the
Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
Boston, MA  02110-1301, USA.
--------------------------------------------------------------------------------
*/


//------------------------------------------------------------------------------
//           Copyright (c) 2008 Alex Shovkoplyas, VE3NEA
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//           Copyright (c) 2013 Phil Harman, VK6APH 
//------------------------------------------------------------------------------

// 2013 Jan 26 - varcic now accepts 2...40 as decimation and CFIR
//               replaced with Polyphase FIR - VK6APH

// 2015 Jan 31 - updated for Hermes-Lite 12bit Steve Haynal KF7O

// 2016 Nov 26 - added VNA logic James Ahlstrom N2ADR

module receiver_vna(
  input clock,
  input [5:0] rate,             //48k....384k
  input [31:0] Rx_frequency,
  output output_strobe,
  input signed [11:0] in_data,
  output [23:0] out_data_I,
  output [23:0] out_data_Q,
  // VNA modes are PC-scan and FPGA-scan
  input vna,
  input [31:0] Tx_frequency_in,
  output reg [31:0] Tx_frequency_out,
  input [15:0] vna_count
  );

  parameter CICRATE;
  parameter RATE48;		// The decimation for 48000 sps

wire signed [17:0] cordic_outdata_I;
wire signed [17:0] cordic_outdata_Q;

reg [2:0] vna_state;		// state machine for both VNA modes
reg [13:0] vna_decimation;	// count up DECIMATION clocks, and then output a sample
reg [15:0] vna_counter;		// count the number of scan points until we get to vna_count desired points
reg [9:0] data_counter;		// Add up 1024 cordic samples per output sample ; 2**10 = 1024
reg signed [27:0] vna_I, vna_Q;				// accumulator for I/Q cordic samples: 18 bit cordic * 10-bits = 28 bits
reg signed [23:0] vna_out_I, vna_out_Q;		// output sample == vna_I, Q
reg vna_strobe;				// output data ready strobe for VNA

localparam DECIMATION = (RATE48 * CICRATE * 8) * 6;	// The decimation; the number of clocks per output sample

localparam VNA_STARTUP			= 0;	// States in the state machine
localparam VNA_PC_SCAN			= 1;
localparam VNA_TAKE_DATA		= 2;
localparam VNA_ZERO_DATA		= 3;
localparam VNA_RETURN_DATUM1	= 4;
localparam VNA_RETURN_DATUM2	= 5;
localparam VNA_CHANGE_FREQ		= 6;
localparam VNA_WAIT_STABILIZE	= 7;

wire vna_scanner = vna ? (vna_count != 1'd0) : 1'b0;
wire [31:0] frequency = vna ? Tx_frequency_out : Rx_frequency;
wire out_strobe;
assign output_strobe = (vna_scanner) ? vna_strobe : out_strobe;

wire signed [23:0] out_data_I2;
wire signed [23:0] out_data_Q2;
assign out_data_I = vna_scanner ? vna_out_I : out_data_I2;
assign out_data_Q = vna_scanner ? vna_out_Q : out_data_Q2;

always @(posedge clock)		// state machine for VNA
begin
    if ( ! vna)
    begin	// Not in VNA mode; operate as a regular receiver
        Tx_frequency_out <= Tx_frequency_in;
        vna_state <= VNA_STARTUP;
    end
    else case (vna_state)
    VNA_STARTUP:		// Start VNA mode; zero the Rx and Tx frequencies to synchronize the cordics to zero phase
    begin
        Tx_frequency_out <= 1'b0;
		vna_counter <= vna_count;
		vna_decimation <= DECIMATION / 2;	// arbitrary startup wait
		if (vna_scanner)
			vna_state <= VNA_CHANGE_FREQ;
		else
			vna_state <= VNA_PC_SCAN;
    end
    VNA_PC_SCAN:		// stay in this VNA state when the PC scans the VNA points
    begin
        Tx_frequency_out <= Tx_frequency_in;
    end
	VNA_TAKE_DATA:		// add up points to produce a sample
	begin
		vna_decimation <= vna_decimation - 1'd1;
		vna_I <= vna_I + cordic_outdata_I;
		vna_Q <= vna_Q + cordic_outdata_Q;
		if (data_counter == 1'b0)
			vna_state <= VNA_RETURN_DATUM1;
		else
			data_counter <= data_counter - 1'd1;
	end
	VNA_ZERO_DATA:		// make a zero sample
	begin
		vna_decimation <= vna_decimation - 1'd1;
		if (data_counter == 1'b0)
			vna_state <= VNA_RETURN_DATUM1;
		else
			data_counter <= data_counter - 1'd1;
	end
	VNA_RETURN_DATUM1:		// Return the sample
	begin
		vna_decimation <= vna_decimation - 1'd1;
		vna_out_I <= vna_I[27:4];
		vna_out_Q <= vna_Q[27:4];
		vna_state <= VNA_RETURN_DATUM2;
	end
	VNA_RETURN_DATUM2:		// Return the sample
	begin
		vna_decimation <= vna_decimation - 1'd1;
		vna_strobe <= 1'b1;
		vna_state <= VNA_CHANGE_FREQ;
	end
	VNA_CHANGE_FREQ:		// done with samples; change frequency
	begin
		vna_decimation <= vna_decimation - 1'd1;
		vna_strobe <= 1'b0;
		if (vna_counter == vna_count)
		begin
			Tx_frequency_out <= Tx_frequency_in;	// starting frequency for scan
			vna_counter <= 1'd0;
		end
		else if (vna_counter == 1'd0)
			vna_counter <= 1'd1;
		else
		begin
			vna_counter <= vna_counter + 1'd1;
			Tx_frequency_out <= Tx_frequency_out + Rx_frequency;	// Rx_frequency is the frequency to add for each point
		end
		vna_state <= VNA_WAIT_STABILIZE;
	end
	VNA_WAIT_STABILIZE:		// Output samples at 8000 sps.  Allow time for output to stabilize after a frequency change.
	begin
		if (vna_decimation == 1'b0)
		begin
			vna_I <= 1'd0;
			vna_Q <= 1'd0;
			vna_decimation <= DECIMATION - 1;
			data_counter <= 10'd1023;
			if (vna_counter == 0)
				vna_state <= VNA_ZERO_DATA;
			else
				vna_state <= VNA_TAKE_DATA;
		end
		else
			vna_decimation <= vna_decimation - 1'd1;
	end
    endcase
end

///// The remainder is the same as the receiver module except where marked "CHANGE"

//------------------------------------------------------------------------------
//                               cordic
//------------------------------------------------------------------------------

cordic cordic_inst(
  .clock(clock),
  .in_data(in_data),             //12 bit 
  .frequency(frequency),         //32 bit
  .out_data_I(cordic_outdata_I), //18 bit
  .out_data_Q(cordic_outdata_Q)
  );

  
// Receive CIC filters followed by FIR filter
wire decimA_avail, decimB_avail;
wire signed [13:0] decimA_real, decimA_imag;
wire signed [15:0] decimB_real, decimB_imag;

localparam VARCICWIDTH = (CICRATE == 10) ? 34 : (CICRATE == 13) ? 34 : (CICRATE == 5) ? 41 : 37; // Last is default rate of 8
localparam ACCWIDTH = (CICRATE == 10) ? 28 : (CICRATE == 13) ? 30 : (CICRATE == 5) ? 25 : 27; // Last is default rate of 8


// CIC filter 
//I channel
cic #(.STAGES(3), .DECIMATION(CICRATE), .IN_WIDTH(18), .ACC_WIDTH(ACCWIDTH), .OUT_WIDTH(14))      
  cic_inst_I2(
    .clock(clock),
    .in_strobe( ! vna_scanner),	// CHANGE - do not run the filters when not in use
    .out_strobe(decimA_avail),
    .in_data(cordic_outdata_I),
    .out_data(decimA_real)
    );

//Q channel
cic #(.STAGES(3), .DECIMATION(CICRATE), .IN_WIDTH(18), .ACC_WIDTH(ACCWIDTH), .OUT_WIDTH(14))  
  cic_inst_Q2(
    .clock(clock),
    .in_strobe( ! vna_scanner),	// CHANGE
    .out_strobe(),
    .in_data(cordic_outdata_Q),
    .out_data(decimA_imag)
    );


//  Variable CIC filter - in width = out width = 14 bits, decimation rate = 2 to 16 
//I channel
varcic #(.STAGES(5), .IN_WIDTH(14), .ACC_WIDTH(VARCICWIDTH), .OUT_WIDTH(16), .CICRATE(CICRATE))
  varcic_inst_I1(
    .clock(clock),
    .in_strobe(decimA_avail),
    .decimation(rate),
    .out_strobe(decimB_avail),
    .in_data(decimA_real),
    .out_data(decimB_real)
    );

//Q channel
varcic #(.STAGES(5), .IN_WIDTH(14), .ACC_WIDTH(VARCICWIDTH), .OUT_WIDTH(16), .CICRATE(CICRATE))
  varcic_inst_Q1(
    .clock(clock),
    .in_strobe(decimA_avail),
    .decimation(rate),
    .out_strobe(),
    .in_data(decimA_imag),
    .out_data(decimB_imag)
    );
				
firX8R8 fir2 (clock, decimB_avail, {{2{decimB_real[15]}},decimB_real}, {{2{decimB_imag[15]}},decimB_imag}, out_strobe, out_data_I2, out_data_Q2);

endmodule
