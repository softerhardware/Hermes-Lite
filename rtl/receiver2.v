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



module receiver2(
  input clock,                  //122.88 MHz
  input [5:0] rate,             //48k....960k
  input [31:0] frequency,
  output out_strobe,
  input signed [15:0] in_data,
  output signed [23:0] out_data_I,
  output signed [23:0] out_data_Q,
  output test_strobe3
  );

wire signed [21:0] cordic_outdata_I;
wire signed [21:0] cordic_outdata_Q;

// gain adjustment, reduce by 6dB to match previous receiver code.
//wire signed [23:0] out_data_I;
//wire signed [23:0] out_data_Q;

//assign out_data_I = (out_data_I2 >>> 1);
//assign out_data_Q = (out_data_Q2 >>> 1);




//------------------------------------------------------------------------------
//                               cordic
//------------------------------------------------------------------------------

cordic cordic_inst(
  .clock(clock),
  .in_data(in_data),             //16 bit 
  .frequency(frequency),         //32 bit
  .out_data_I(cordic_outdata_I), //22 bit
  .out_data_Q(cordic_outdata_Q)
  );

  
 
  // CIC M = 5, R = 8  + Vari CIC m = 5, R = 2..40  + FIR R = 8.
  
// Receive CIC filters followed by FIR filter
wire decimA_avail, decimB_avail;
wire signed [17:0] decimA_real, decimB_real;
wire signed [17:0] decimA_imag, decimB_imag;

//I channel
wire cic_outstrobe_2;
wire signed [23:0] cic_outdata_I2;
wire signed [23:0] cic_outdata_Q2;

//I channel
cic #(.STAGES(3), .DECIMATION(8), .IN_WIDTH(22), .ACC_WIDTH(31), .OUT_WIDTH(18))      
  cic_inst_I2(
    .clock(clock),
    .in_strobe(1'b1),
    .out_strobe(decimA_avail),
    .in_data(cordic_outdata_I),
    .out_data(decimA_real)
    );


//Q channel
cic #(.STAGES(3), .DECIMATION(8), .IN_WIDTH(22), .ACC_WIDTH(31), .OUT_WIDTH(18))  
  cic_inst_Q2(
    .clock(clock),
    .in_strobe(1'b1),
    .out_strobe(),
    .in_data(cordic_outdata_Q),
    .out_data(decimA_imag)
    );



				
//  Variable CIC filter - in width = out width = 18 bits, decimation rate = 2 to 40 

wire cic_outstrobe_1;
wire signed [22:0] cic_outdata_I1;
wire signed [22:0] cic_outdata_Q1;

varcic #(.STAGES(5), .IN_WIDTH(18), .ACC_WIDTH(45), .OUT_WIDTH(18))
  varcic_inst_I1(
    .clock(clock),
    .in_strobe(decimA_avail),
    .decimation(rate),
    .out_strobe(decimB_avail),
    .in_data(decimA_real),
    .out_data(decimB_real)
    );


//Q channel
varcic #(.STAGES(5), .IN_WIDTH(18), .ACC_WIDTH(45), .OUT_WIDTH(18))
  varcic_inst_Q1(
    .clock(clock),
    .in_strobe(decimA_avail),
    .decimation(rate),
    .out_strobe(),
    .in_data(decimA_imag),
    .out_data(decimB_imag)
    );

		
				
//firX8R8 fir2 (clock, decimB_avail, decimB_real, decimB_imag, out_strobe, out_data_I, out_data_Q);

wire out_strobe1;
wire signed [23:0] out_data_I2;
wire signed [23:0] out_data_Q2;		

// cascaded Polyphase FIR filters, decimate by 4 and decimate by 2. 
firX4R4 fir2 (clock, decimB_avail, decimB_real, decimB_imag, out_strobe1, out_data_I2, out_data_Q2);
firX2R2 fir3 (clock, out_strobe1, out_data_I2, out_data_Q2, out_strobe, out_data_I, out_data_Q);

  
  
assign test_strobe3 = out_strobe;

endmodule
