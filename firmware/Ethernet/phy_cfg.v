//
//  HPSDR - High Performance Software Defined Radio
//
//  Metis code. 
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


//  Metis code copyright 2010, 2011, 2012, 2013 Alex Shovkoplyas, VE3NEA.

//  25 Sept 2014 - Modified initial register values to correct for 0.12nS rather than 0.2nS steps.
//                 Also added write to register 106h to turn off Tx Data Pad Skews.  Both these
//						 changes are due to errors in the original data sheet which was corrected Feb 2014.


//-----------------------------------------------------------------------------
// initialize the PHY device on startup and when allow_1Gbit changes
// by writing config data to its MDIO registers; 
// continuously read PHY status from the MDIO registers
//-----------------------------------------------------------------------------

module phy_cfg(
  //input
  input clock,        //2.5 MHZ
  input init_request,
  input allow_1Gbit,  //speed selection jumper: open 
  
  //output
  output reg [1:0] speed,
  output reg duplex,
  
  //hardware pins
  inout mdio_pin,
  output mdc_pin  
);


//-----------------------------------------------------------------------------
//                           initialization data
//-----------------------------------------------------------------------------

//mdio register values
wire [15:0] values [8:0];
assign values[8] = {6'b0, allow_1Gbit, 9'b0};
assign values[7] = 16'h8104;
assign values[6] = {8'hc0, 8'h77};  //rx and tx clock delay, in 0.12 ns units to reg 104h, changed 25 Sept
assign values[5] = 16'h8105;
assign values[4] = 16'h0000;			// no Rx pad skews, reg 105h		
assign values[3] = 16'h8106;
assign values[2] = 16'h7777;			// no Tx pad skews, reg 106h, added 25th Sept
assign values[1] = 16'h1300;
assign values[0] = 16'hxxxx;


//mdio register addresses 
wire [4:0] addresses [8:0];
assign addresses[8] = 9;
assign addresses[7] = 11;
assign addresses[6] = 12;
assign addresses[5] = 11;
assign addresses[4] = 12;
assign addresses[3] = 11;
assign addresses[2] = 12;
assign addresses[1] = 0;
assign addresses[0] = 31; 

reg [3:0] word_no; 






//-----------------------------------------------------------------------------
//                            state machine
//-----------------------------------------------------------------------------

//phy initialization required 
//if allow_1Gbit input has changed or init_request input was raised
reg last_allow_1Gbit, init_required;

wire ready;
wire [15:0] rd_data;
reg rd_request, wr_request;


//state machine  
localparam READING = 1'b0, WRITING = 1'b1;  
reg state = READING;  


always @(posedge clock)  
  begin
  if (init_request || (allow_1Gbit != last_allow_1Gbit)) 
    init_required <= 1;
  
  if (ready)
    case (state)
      READING:
        begin
        speed <= rd_data[6:5];
        duplex <= rd_data[3];
        
        if (init_required)
          begin
          wr_request <= 1;
          word_no <= 8;
          last_allow_1Gbit <= allow_1Gbit;
          state  <= WRITING;
          init_required <= 0;
          end
        else
          rd_request <= 1'b1;
        end

      WRITING:
        begin
        if (word_no == 4'b1) state <= READING;   // *** should this be == 0?
        else wr_request <= 1;
        word_no <= word_no - 4'b1;		  
        end
      endcase
		
  else //!ready
    begin
    rd_request <= 0;
    wr_request <= 0;
    end
  end

        
        
        
        
//-----------------------------------------------------------------------------
//                        MDIO interface to PHY
//-----------------------------------------------------------------------------


mdio mdio_inst (
  .clock(clock), 
  .addr(addresses[word_no]), 
  .rd_request(rd_request),
  .wr_request(wr_request),
  .ready(ready),
  .rd_data(rd_data),
  .wr_data(values[word_no]),
  .mdio_pin(mdio_pin),
  .mdc_pin(mdc_pin)
  );  
  



  
  
endmodule
