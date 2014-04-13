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



// DHCP - copyright 2010, 2011, 2012 Phil Harman VK6APH

/*
	change log:


*/

//  sequencer for DHCP -  state machine to sequence DHCP discover, offer, request and ACK/NAK


/*
					 
				    +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+
	clock      --+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+  +--+

						  +-----+
	DHCP_start-------+     +--------------------------------------------------------------- 

					          +-----+
	DHCP_discover  -------+     +--------------------------------------------------------------- sent to Tx_MAC

										             +---------------------
	DHCP_offer     -----------------//-----+													 from Rx_MAC

										             +-----+
	DHCP_request  --------------------------+     +-----------------------------------------	 sent to Tx_MAC
	
														                 +---------------
	DHCP_ACK       ----------------------------------//-----+									 from Rx_MAC 
	
	OR		       ---------+																	                  +--------------------
	time_out              +-----------------------------------------//------------------------+ 
	

	The code loops waiting for  DHCP_start from Metis. It then sets DHCP_discover high which causes 
	the TX_MAC send a discovery request. Then loops waiting for DHCP_offer, from Rx_MAC,  or a time out. 
	It then  sets DHCP_request high which causes TX_MAC to send a request. Then loops waiting for an
	DHCP_ACK from Rx_MAC or a time out. 
	
	Code then loops back to the start.

*/



module DHCP (clock, DHCP_start, DHCP_renew, DHCP_discover, DHCP_offer, time_out, DHCP_request, DHCP_ACK);

input clock;
input DHCP_start;
input DHCP_renew;
input DHCP_offer;
input DHCP_ACK;


output DHCP_discover;
output DHCP_request;
output time_out;


reg [3:0]DHCP_state;
reg DHCP_discover;
reg DHCP_request;
reg [24:0]time_count;
reg time_out; 									// set when DHCP times out

// NOTE: If set, then leave time_out flag set until we get the next discover or renew request

always @ (posedge clock)					// Tx is on negedge Tx_clock_2 
begin
	case(DHCP_state)
	0: begin
	   time_count <= 0;						// loop until we see a DHCP start signal
		if (DHCP_start) begin
			DHCP_discover <= 1'b1;
			time_out <= 0; 					// reset time out flag
			DHCP_state <= 1;
		end
		else if (DHCP_renew) begin			// send a DHCP request
			time_out <= 0; 
			DHCP_state <= 2;
		end 
		else DHCP_state <= 0;	
	   end
	1: begin										// loop until we see a DHCP offer, time out of not found
	   DHCP_discover <= 0;
			if (DHCP_offer)
				DHCP_state <= 2;
			else begin
				if (time_count == 25000000) begin
						time_out <= 1'b1;
						time_count <= 0;
						DHCP_state <= 0;
				 end
				 else begin
					time_count <= time_count + 1'b1;
					DHCP_state <= 1;
				 end 
			end 
		end
    2: begin
	   DHCP_request <= 1'b1;				// accept offered IP address
	   DHCP_state <= 3;
	   end
	3: begin
	   DHCP_request <= 0;					// loop until we see a DHCP ACK or NAK, time out if not found
		if (DHCP_ACK) 
		   DHCP_state <= 0;			 
		else begin 
			if (time_count == 25000000) begin
					time_count <= 0;
					time_out <= 1'b1;
					DHCP_state <= 0;
			 end
			 else begin
				time_count <= time_count + 1'b1;
				DHCP_state <= 3;
			 end 
		end   
	   end
	default: DHCP_state <= 0;
	endcase
end

endmodule
