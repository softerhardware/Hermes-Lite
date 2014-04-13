// V1.0 31 August  2009  
//
// Copyright 2009, 2010, 2011 Phil Harman VK6APH
//
//  HPSDR - High Performance Software Defined Radio
//
//  Ethernet 802.3 CRC32 Generator
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
//

module CRC32 (rst, clk, crc, data); 

  input					rst;
  input                 clk; 
  input     	  [7:0] data;
  reg             [3:0] addr; 
  wire           [31:0] crc1, crc2; 
  output         [31:0] crc = 0; 

  reg [31:0]crc = 0;

  function [31:0] crc_table; 
    input [3:0] addr; 
    case (addr) 
       0: crc_table = 32'h4DBDF21C; 
       1: crc_table = 32'h500AE278; 
       2: crc_table = 32'h76D3D2D4; 
       3: crc_table = 32'h6B64C2B0; 
       4: crc_table = 32'h3B61B38C; 
       5: crc_table = 32'h26D6A3E8; 
       6: crc_table = 32'h000F9344; 
       7: crc_table = 32'h1DB88320; 
       8: crc_table = 32'hA005713C; 
       9: crc_table = 32'hBDB26158; 
      10: crc_table = 32'h9B6B51F4; 
      11: crc_table = 32'h86DC4190; 
      12: crc_table = 32'hD6D930AC; 
      13: crc_table = 32'hCB6E20C8; 
      14: crc_table = 32'hEDB71064; 
      15: crc_table = 32'hF0000000; 
    endcase 
  endfunction 

  assign crc1 = crc[31:4]  ^ crc_table(crc[3:0]  ^ data[3:0]); // low nibble 
  assign crc2 = crc1[31:4] ^ crc_table(crc1[3:0] ^ data[7:4]); // high nibble

  always @ (posedge clk, posedge rst) begin 
    if (rst)
    begin
		crc <= 0;
		addr <= 0; 
	end 
    else 
	begin
		crc  <= crc2; 
		addr <= addr + 1'b1; 
	end 
  end 
 

endmodule
