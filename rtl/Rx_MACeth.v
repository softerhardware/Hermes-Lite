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


//  Rx_MAC - Copyright 2009, 2010, 2011, 2012, 2013  Phil Harman VK6APH






//--------------------------------------------------------------
//   Rx_MAC - PHY Receive Interface  
//--------------------------------------------------------------

/* 
	The format of the data from the PHY at 100T is as follows
	
	             +----+    +----+    +----+    +----+    +----+    +----+    +----+    +----+    
	Rx_clock   --+    +----+    +----+    +----+    +----+    +----+    +----+    +----+  		25MHz
	
						        +-----------------------------------------------------------------
	 RX_DV     ------------+
	
	                       +---------+---------+---------+---------+---------+---------+---------+
	PHY_RX				     +---------+---------+---------+---------+---------+---------+---------+
	
	nibble (100T)          3:0       7:4       3:0       7:4       3:0       7:4       3:0       7:4
	
		                        +---------+---------+---------+---------+---------+---------+---------+
	PHY_data					      +---------+---------+---------+---------+---------+---------+---------+
	
 
    At 1000T the 3:0 nibble is available on the positive edge of Rx_clock and 7:4 on the negative edge vis:
    
    
    	          +----+    +----+    +----+    +----+    +----+    +----+    +----+    +----+    
	Rx_clock   --+    +----+    +----+    +----+    +----+    +----+    +----+    +----+  		125MHz
		
						        +-----------------------------------------------------------------
	 RX_DV     ------------+
	
	                       +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
	PHY_RX				     +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
	
	nibble (1000T)        3:0  7:4  3:0  7:4  3:0  7:4  3:0  7:4  3:0  7:4  3:0  7:4  3:0  7:4  3:0 
    
    
    Operation:
    
    The state machine operates on the negative edge of Rx_clock.
    When RX_DV goes high nibbles are read into a 112 bit shift register. At each read clock the contents
    of the shift register are compared with valid patterns.
    
    NOTE: DATA IS RECEIVED LOW NIBBLE FIRST.
    
    For a valid preable and MAC address the data (in bytes) in the shift register will look as follows:    
    
    [111:104][103:96][ 95:88][ 87:80][ 79:72][ 71:64][ 63:56][ 55:48][ 47:40][ 39:32][ 31:24][ 23:16][ 15:8] [  7:0]
       55       55      55      55      55      55      55      5D      XX      XX      XX      XX      XX      XX
    
	where XX is a MAC address or broadcast (FF FF FF FF FF FF) - see BROADCAST below.

	
	If the MAC address matches that of this METIS board then a further 56 nibbles are read.
	In which case the data in the shift register looks as follows:
	
    [111:104][103:96][ 95:88][ 87:80][ 79:72][ 71:64][ 63:56][ 55:48][ 47:40][ 39:32][ 31:24][ 23:16][ 15:8] [  7:0]
	 FromMAC  FromMAC FromMAC FromMAC FromMAC FromMAC   80      00      54      00      00      00      00      00   after 28 shifts
	   00       00      08      ??      XX      XX      XX      XX      XX      XX      XX      XX      XX      XX   after 56 shifts
	   
	Then if [87:80] = 11 a UDP/IP frame is identified
	else if [87:80] = 10 an ICMP(ping) request is identified
		 
    UDP:
    If a UDP/IP frame is indentified a further 32 shifts are done in which case the shift register data looks as follows:
    
    [111:104][103:96][ 95:88][ 87:80][ 79:72][ 71:64][ 63:56][ 55:48][ 47:40][ 39:32][ 31:24][ 23:16][ 15:8] [  7:0]     
                                                        FE      EF      10      20      SEQ     SEQ     SEQ     SEQ
                                                        
    Where SEQ = 32 bit sequence number from PC.
    
    If [63:48] = FEEF, indicating an HPSDR frame type AND [47:40] =  10, indicating a type 1 data frame follows,
    AND [39:32] = 20, indicating  the following data is for EP2, then the next 1024 bytes are written to the Rx_fifo.
    The code then loops until RX_DV goes low and the process repeats.                                                    
                                                        
   
    PING:
    If a ping request is identified a futher 8 shifts are applied in which case the shift register data looks as follows:
    
    [111:104][103:96][ 95:88][ 87:80][ 79:72][ 71:64][ 63:56][ 55:48][ 47:40][ 39:32][ 31:24][ 23:16][ 15:8] [  7:0]
																					    80      00      chk     chk
                                                        
    The next 36 bytes are then stored in RAM (since this data needs to be returned to the PC as part of the ping response).
    A ping request flag is then set. The code then loops until RX_DV goes low and the process repeats. 
                                                       
                                                       
    BROADCAST:
    If a broadcast address is detected 28 shift lefts are applied, in which case the shift register data looks as follows:
    
    [111:104][103:96][ 95:88][ 87:80][ 79:72][ 71:64][ 63:56][ 55:48][ 47:40][ 39:32][ 31:24][ 23:16][ 15:8] [  7:0]
      MAC      MAC     MAC     MAC     MAC     MAC      80      60      80      00      10      80      60      40      
      
    If [63:48] = 8060, which indicates an ARP request, then a further 28 shift lefts are applied,
    in which case the shift register data looks as follows:
    
     [111:104][103:96][ 95:88][ 87:80][ 79:72][ 71:64][ 63:56][ 55:48][ 47:40][ 39:32][ 31:24][ 23:16][ 15:8] [  7:0]   
       00        01     MAC     MAC     MAC     MAC     MAC     MAC      IP      IP      IP      IP      00      00    
       
    If [111:96] = 0010, which indicates an ARP request, then a further 16 shift lefts are applied,
    in which case the shift register data looks as follows:
       
     [111:104][103:96][ 95:88][ 87:80][ 79:72][ 71:64][ 63:56][ 55:48][ 47:40][ 39:32][ 31:24][ 23:16][ 15:8] [  7:0]       
        IP      IP      IP      IP       00      00      00      00      00      00      IP      IP      IP      IP
                                                                                         
    if [31:0] = IP address of this METIS card then an ARP_request flag is set. The code then loops until RX_DV
    goes low and the process repeats.
    
    
    
    If a match condition in any of the above is not met then the code loops until RX_DV goes low and the process repeats.
    
*/

/*
	Change log:

	2011 Mar  28 - Enable Discovery request at all times but use IP and Port of PC that sends Start command.
	     Apr   3 - Add wide band spectrum and on/off enable
	2012 Dec  21 - Modified ARP to enable directed as well as broadcast request
		       22 - Added FIFO to PHY so PHY_data_clock can run at all times. FIFO is 8 bit and is fed 
				      such that high and low nibbles are always in the correct sequence.
	2013 Jan  26 - Enable IP address to be set without being in Bootloader mode. Once IP is set board will reset.

					  
*/


module Rx_MAC (PHY_RX_CLOCK, PHY_data_clock, RX_DV, PHY_RX, broadcast, ARP_request,
			   ping_request, ping_data, Rx_enable, this_MAC, DHCP_offer, DHCP_ACK, DHCP_NAK,
			   ARP_PC_MAC, ARP_PC_IP, This_IP, Ping_PC_IP, Ping_PC_MAC,
			   YIADDR, This_MAC, METIS_discovery, METIS_discover_sent, PC_IP, PC_MAC, Port, Length, data_match,
			   PHY_100T_state, Rx_fifo_data, seq_error, run, wide_spectrum, IP_lease, DHCP_IP, DHCP_MAC);
			   
input PHY_RX_CLOCK;
input PHY_data_clock;
input RX_DV;
input [3:0]PHY_RX;
input [47:0]This_MAC;  				// MAC address of this Oyz board
input [31:0]This_IP;				// IP address allocated to this METIS Board
input METIS_discover_sent;			// set when Discovery request has been responded to

output [15:0]Port;					// UPD/IP Port that Metis and the PC is using
output reg  broadcast;   			// set when we receive a broadcast address
output reg  ARP_request;			// set when we receive a vaild ARP request
output reg  ping_request;			// set when we receive a valid ping request
output reg  [7:0]ping_data[0:59];	// RAM to hold ping data from PC that we need to echo, max of 56 + 4 bytes 
output reg  Rx_enable;
output wire this_MAC;				// set when packet for this MAC address received
output reg  DHCP_offer; 			// DHCP offer - set when we get a valid DHCP offer
output reg  [31:0]YIADDR;			// IP address from DHCP offer
output reg  DHCP_ACK;
output reg  DHCP_NAK;
output reg  METIS_discovery;		// set when we receive a discovery request
output reg  [31:0]PC_IP;			// holds IP address of the PC we are connecting to
output reg  [47:0]PC_MAC;			// holds the MAC address of the PC we are connecting to
output reg  [47:0]ARP_PC_MAC;		// has the MAC address of the PC requesting an ARP	
output reg  [31:0]ARP_PC_IP;		// has the IP address of the PC requesting an ARP
output reg  [31:0]Ping_PC_IP;		// has the IP address of the PC requesting a ping
output reg  [47:0]Ping_PC_MAC;	// has the MAC address of the PC requesting a ping
output reg  [15:0]Length;			// holds length of packet, used by ping calculate payload length
output reg  data_match;				// **** test flag *****
output reg  PHY_100T_state;		// used at a system clock at 100T
output wire [7:0]Rx_fifo_data;  	// PHY output sent to Rx fifo.
output 	    seq_error; 			// set when we receive a sequence error
output reg  run;						// when set enables HPSDR (i.e. USB format) data to be sent to the PC
output reg  wide_spectrum;			// when set enables wide spectrum data to be sent
output reg [31:0]IP_lease;			// holds IP lease time in seconds from DHCP ACK frame
output reg [31:0]DHCP_IP;			// IP address of DHCP Server making offer
output reg [47:0]DHCP_MAC;			// MAC address of DHCP Server making offer

reg [111:0] PHY_output;				// shift register to hold nibble output from Micrel PHY chip 
reg [4:0] PHY_Rx_state;
reg [9:0] left_shift;
reg [31:0] PC_sequence_number;	// sequence number from PC
reg [11:0] PHY_data_count;      	// counts how many nibbles we send to the PHY_Rx_fifo
reg [47:0] FromMAC;					// MAC of sending PC
reg [31:0] FromIP;					// IP address of sending PC
reg [7:0] ping_count; 				// counts off 36 bytes of ping data
reg [31:0]temp_YIADDR;				// Tempory storage for YIADDR until MAC address validated
reg UDP_check;					// used to check for 0800
reg [31:0]To_IP;						// holds IP address that UDP/IP data is being set to
reg [7:0]skip;							// holds number of bytes to skip when looking for IP lease
reg [15:0] FromPort;					// Port that PC sends from
reg [15:0] ToPort;					// Port that PC send to 
reg [31:0]temp_PC_IP;				// save PC IP address incase Discovery is from a different PC
reg [47:0]temp_PC_MAC;				// save PC MAC address incase Discovery is from a different PC
reg [15:0]temp_Port;					// save PC Port incase Discovery is from a different PC

localparam  Rx_port = 1024;		// Port that Metis listens on 

// Receive states
localparam	START = 5'd0,
			GET_TYPE = 5'd1,
			ARP = 5'd2,
			UDP = 5'd3,
			METIS_DISCOVERY = 5'd4,
			SEND_TO_FIFO = 5'd5,
			DHCP = 5'd6,
			PING = 5'd7,
			RETURN = 5'd13;

localparam Broadcast = 48'hFF_FF_FF_FF_FF_FF;


wire [3:0] PHY_RX;					// has nibble from PHY chip
wire [3:0] PHY_data_h;
wire [3:0] PHY_data_l;
reg  [7:0] PHY_byte;
wire [7:0] PHY_byte_out;
reg  PHY_Rx_fifo_reset;
reg  [31:0]prev_seq_number;
reg  seq_error;							// set when we have a sequence error


// ------------------------- 100T Interface ---------------------
// FIFO based PHY interface. The state machine ensures that the low and high nibbles
// are always presented to the input FIFO in the correct order.
// The output from the FIFO is clocked with the PHY_RX_CLOCK/2 so we always have a clock
// feeding the decoder.  This is required since writing the IP address to EEPROM takes time. 

//-------------------------------------------
//   			PHY fifo
//-------------------------------------------

/*
							 PHY_fifo (32 bytes) 
						
						---------------------
			PHY_byte |data[7:0]	         | 
						|				         |
!PHY_100T_state	|wrreq		         | 
						|					      |									    
	~PHY_RX_CLOCK	|>wrclk	 			   |
						---------------------								
		 !rdempty   |rdreq		  q[7:0] | PHY_byte_out
						|					      |					  			
						|   		     rdempty| rdempty 
						|                    | 							
	PHY_data_clock	|>rdclk  			   | 	    
						---------------------								

 
*/

always @ (posedge PHY_RX_CLOCK)
begin
case (PHY_100T_state)
// capture the low nibble
0:	begin
		if (RX_DV) begin 
			PHY_byte <= {PHY_byte[7:4],PHY_RX};
			PHY_100T_state <= 1'd1;
		end 
	end 
// capture the high nibble
1:	begin
	PHY_byte <= {PHY_RX, PHY_byte[3:0]};
	PHY_100T_state <= 1'd0;
	end
endcase
end 


wire rdempty;

PHY_fifo PHY_fifo_inst (.data(PHY_byte), .q(PHY_byte_out), .wrreq(!PHY_100T_state), .wrclk(~PHY_RX_CLOCK), .rdreq(!rdempty),
						.rdclk(PHY_data_clock), .rdempty(rdempty));

// apply output of fifo to 112 bit shift register
always @ (negedge PHY_data_clock)
 if(!rdempty)
	 PHY_output <= {PHY_output[103:0], PHY_byte_out}; 	  

// ---------------------------- 1000T interface -------------------------


// ---------------------------- PHY data to send to Rx fifo -------------

assign Rx_fifo_data = PHY_output[7:0];

// ---------------------------- Process PHY data ------------------------

// process bytes from PHY
always @ (negedge PHY_data_clock)						
begin

case (PHY_Rx_state)

START:
	begin
	broadcast <= 1'b0;			// reset broadcast flag
	left_shift <= 0; 				// reset the shift counter
	ARP_request <= 1'b0;			// reset ARP for now
	ping_request <= 1'b0;
	this_MAC <= 1'b0;
	PHY_data_count <= 0;			// reset the data counters
	ping_count <= 0;
	
	
		if (PHY_output[63:0] == {16'h55_D5, Broadcast} ) begin
			broadcast <= 1'b1;				// set broadcast flag 
			PHY_Rx_state <= GET_TYPE;   	// See what type of packet and who it is for
		end

	  // else check for frame to this METIS MAC address - ignore first 6 x h55 since Rx PLL may not be locked  
		else if (PHY_output[63:0] == {16'h55_D5, This_MAC}) begin	// addressed to me?	
			this_MAC <= 1'b1;					  			// set this MAC flag
			PHY_Rx_state <= GET_TYPE;  			  	// have preamble and address so next state 
		end
	  
		
		else PHY_Rx_state <= START;  			  		// no preamble and MAC address  so loop and look again  
	end
	
	
	
// Determine the type of packet 
// we get one left shift automatically when we go to this state
GET_TYPE:
begin
data_match <= 1'b1;								//  we either got our MAC or Broadcast to get this far :) 
	case(left_shift)
	// Check for ARP request
	13: begin
			
				FromMAC <= PHY_output[111:64]; 					// get the MAC address of the sending PC
				Length <= PHY_output[31:16];						// get lenght of packet for ping 	
					if (PHY_output[63:48] == 16'h0806) begin 	// check for ARP request	
						left_shift <= 0;
						PHY_Rx_state <= ARP;
					end
					else begin
						UDP_check <= PHY_output[63:48] == 16'h0800;				// save these values for next check
						left_shift <= left_shift + 1'b1;
			end
		end
	// Check for UDP/IP
	27: begin		
			if (PHY_output[87:80] == 8'h11 && UDP_check ) begin
				FromIP  <=  PHY_output[63:32];			// IP address of PC sending UDP/IP frame
			    To_IP <=  PHY_output[31:0]; 				// save the IP address being send to for later match
				left_shift <= 0;
				PHY_Rx_state <= UDP;
			end
			else  left_shift <= left_shift + 1'b1;
		end 
	// Check for ping request or desitation unavailiable and that it is for this IP address 
	30: begin
			 if (PHY_output[111:104] == 8'h01  && PHY_output[55:24] == This_IP)begin			 
				 if (PHY_output[23:16] == 8'h08) begin 
					Ping_PC_IP  <= PHY_output[87:56];		// save IP address of requesting PC
					Ping_PC_MAC <= FromMAC;		   			// save MAC address of requesting PC
					left_shift <= left_shift + 1'b1;					   	
				end
				else if (PHY_output[23:16] == 8'h03) begin 
					run <= 1'b0;									// can't reach destination so stop sending
					wide_spectrum <= 1'b0;
					PHY_Rx_state <= RETURN;
				end
			end
			else  PHY_Rx_state <= RETURN;	// non of the above so exit
		end 
	// shift left once more to skip second part of Checksum	
	31:	begin
			left_shift <= 0;
			PHY_Rx_state <= PING;						// now process ping request
		end
					
	default: begin
			 left_shift <= left_shift + 1'b1;		// left shift once again
			 PHY_Rx_state <= GET_TYPE;
			end 
			
	endcase	
end 				
	
// we get one left shift automatically when we go to this state
ARP:
begin
	case (left_shift)
	13: begin
			if ( PHY_output[111:96] == 16'h0001) begin 
				ARP_PC_MAC <= PHY_output[95:48];  // get the MAC address of the requesting PC
				ARP_PC_IP  <= PHY_output[47:16];  // get the IP  address of the requesting PC
				left_shift <= left_shift + 1'b1;
				//data_match <= 1'b1;
			end
			else PHY_Rx_state <= RETURN;			// exit
		end
	// check for IP match  
	21: begin
			if (PHY_output[31:0] == This_IP)  
				ARP_request <= 1'b1;    			// request a reply to the ARP request
			PHY_Rx_state <= RETURN;					// done so exit 
		end
	
	default: begin
			 left_shift <= left_shift + 1'b1;
			 PHY_Rx_state <= ARP;
			 end
	endcase
end

// process UDP, could be HPSDR frame, ERASE, PROGRAM, START, STOP, METIS discovery
UDP:
begin
	case (left_shift)
	// check for DHCP; look at To & From ports and UDP type
	13: begin
		FromPort <= PHY_output[111:96]; 				// save the PC port this came from since we will reply to it for UDP/IP 
		ToPort   <= PHY_output[95:80];				// save the port this is send to 
			if (PHY_output[95:80] == 16'h0044  && PHY_output[47:40] == 8'h02)begin  // it's a DHCP
				left_shift <= 0;
				PHY_Rx_state <= DHCP;
			end
			else left_shift <= left_shift + 1'b1;					 
		end
		// decode command 
	15: begin
		// check for 0xEFFE and To_Port = 1024  - this is common to all commands
			if (PHY_output[63:48] == 16'hEFFE && ToPort == Rx_port) begin
				// check for all commands that are sent to This_IP address and port
				if (To_IP == This_IP) begin										
					case (PHY_output[47:40])
					1:  begin // check for HPSDR data, look for End Point 2 						
							if (PHY_output[39:32] == 8'h02) begin			// check for HPSDR endpoint data
								PC_sequence_number <= PHY_output[31:0];  	// get the PC sequence number
								PHY_Rx_state <= SEND_TO_FIFO;
							end
						end
					4:  begin	// check for Start/Stop command
						run <= PHY_output[32];
						wide_spectrum <= PHY_output[33];
						PC_IP   <= FromIP;			// save the calling PC's IP address
						PC_MAC  <= FromMAC;			// save the calling PC's MAC address
						Port 	<= FromPort;			// save the calling PC's from Port
						PHY_Rx_state <= RETURN;	
						end
					default: PHY_Rx_state <= RETURN;	
					endcase
				end
				// check for Discovery broadcasts to this port. If a Discovery,save the current PC's IP etc in case the 
				// Discovery request comes from a different PC or there are multiple Metis cards on the same network.
				// Once the Discovery has been responded to we can restore the previous PC's IP etc. 		
				// If a set IP command then check it is for this MAC and if so, and not running, get the IP address to 
				// save in EEPROM.
				else if (broadcast) begin 			
					  if (PHY_output[47:40] == 8'h02) begin		// check for Metis Discovery
						left_shift <= 0;
						temp_PC_IP   <= PC_IP;							// save the calling PC's IP address
						temp_PC_MAC  <= PC_MAC;							// save the calling PC's MAC address
						temp_Port 	 <= Port;							// save the calling PC's from Port
						PHY_Rx_state <= METIS_DISCOVERY;
					 end
					 else PHY_Rx_state <= RETURN;
				end  				
				else  PHY_Rx_state <= RETURN;							// non of the above so return						
			end
			else PHY_Rx_state <= RETURN;								
		end 
		
	default: begin
			 left_shift <= left_shift + 1'b1;
			 PHY_Rx_state <= UDP;
			end
	endcase		
end 

METIS_DISCOVERY:
begin
	case (left_shift)
	// get IP, MAC & Port for the PC requesting the Discovery
	1: begin
		PC_IP   <= FromIP;					
		PC_MAC  <= FromMAC;					
		Port 	<= FromPort;				
		METIS_discovery <= 1'b1;					// set the discovery flag
		left_shift <= left_shift + 1'b1;					 
		end
	// now wait until Discovery reply has been sent then restore previous PC's IP address etc.
	3: begin
		//if (METIS_discover_sent) begin 
			METIS_discovery <= 0;			    	// clear the discovery flag 
			PC_IP <= temp_PC_IP;						// restore previous PC IP data in case Discovery came from a different PC.
			PC_MAC <= temp_PC_MAC;
			Port <= temp_Port;
			PHY_Rx_state <= RETURN;					// done so return
		//end 
	   end 
		
	default: begin
			 left_shift <= left_shift + 1'b1;
			 PHY_Rx_state <= METIS_DISCOVERY;
			end
	endcase		
end 
	
//  Loop here until we have sent 1024 bytes to the EPCS Rx FIFO. Then drop Rx_enable 
//  so that the CRC is not sent. Loop back to the start to look for the next preamble

SEND_TO_FIFO:
begin
		if (PC_sequence_number != prev_seq_number + 1'b1)  	// check for sequence errors
			seq_error <= 1'b1;
		if (PHY_data_count == 1024) begin    						// have we sent 1024 bytes ?
			data_match <= 1'b0;
			Rx_enable <= 0;												// yes so disable further writes to PHY_Rx_fifo
			prev_seq_number <= PC_sequence_number;
			seq_error <= 1'b0;									
			PHY_Rx_state <= START;										// loop back to detect sync and C&C again 
		end
		else begin
			Rx_enable <= 1'b1;				
			PHY_data_count <= PHY_data_count + 1'b1;
		end 
	end	
	
	
	
// capture the IP address being offered and if for this MAC then save and set 
// DHCP_Offer flag. If a response to a DHCP_request check for ACK or NAK
DHCP:
begin
	DHCP_offer <= 0;  					// reset status flags
	DHCP_ACK <= 0;
	DHCP_NAK <= 0;
	DHCP_MAC <= FromMAC; 				// save the MAC address of the DHCP server
	case (left_shift)
	// Get the offered IP address
	// Store in a temp register until we confirm it is for this MAC address
	13: begin
		temp_YIADDR <= PHY_output[31:0]; 		// save IP address this is offered
		left_shift <= left_shift + 1'b1;
		end

	// check the offer is being sent to this MAC address
	27: begin
		  if (PHY_output[47:0] == This_MAC) begin  	// if for us save YIADDR and continue
			YIADDR <= temp_YIADDR;							// it is for us so save the offered IP address
			left_shift <= left_shift + 1'b1;
		  end
		  else  PHY_Rx_state <= RETURN;					// not for us so exit
		end 
	
		
	// now need to check if this is an Offer or an ACK/NAC 
	// so shift 202 + 7 = 209 more times and then read bytes [23:0]	
   236: begin
			if (PHY_output[23:0] == 24'h35_01_02) begin			// have an ACK so check how long IP lease is for
				DHCP_offer <= 1'b1;										// and get IP address of DHCP server
				left_shift <= left_shift + 1'b1;
				
			end 
			else if (PHY_output[23:0] == 24'h35_01_05) begin   
				DHCP_ACK <= 1'b1;
				PHY_Rx_state <= RETURN;
			end
			else if (PHY_output[23:0] == 24'h35_01_06) begin
				DHCP_NAK <= 1'b1;
				PHY_Rx_state <= RETURN;	
			end 
		end 
		
// capture next two bytes, check option, process if IP lease or skip if not.
// If option is 0xFF then we have reach the end of the options so return.		
	238: begin
			if (PHY_output[15:8] == 8'hFF)    					// check for end of DHCP options
				PHY_Rx_state <= RETURN;
			else if (PHY_output[15:0] == 16'h3304) begin  	// check for IP lease flag, next 4 bytes hold the # seconds
				left_shift <=  241;
			end 
			else if (PHY_output[15:0] == 16'h3604) begin  	// get the IP address of the DHCP server, next 4 bytes holds it.
				left_shift <=  245;
			end 
			else begin
				skip <= PHY_output[7:0];     						// not lease flag so we want so 'skip' these number of bytes
				left_shift <= left_shift + 1'b1;
			end
		 end 
// we all ready have one 'skip' when we get here 		
	239: begin 
			if (skip - 1 == 0) left_shift <= 240;				// skip over byte so look again 
			else begin
				skip <= skip - 1'b1;
				left_shift <= 239;
			end
		 end 
// need another shift left before we return since we read two bytes at 238	
	240: left_shift <= 238;			 
		 
	241: left_shift <= left_shift + 1'b1;
	
// we have shifted left 4 times so get the IP lease time here 	
	244: begin
		 IP_lease <= PHY_output[31:0];
		 left_shift <= 240;
		 end 
		 
	245: left_shift <= left_shift + 1'b1;
	
// we have shifted left 4 times so get the IP address of the DHCP server
	248: begin
		 DHCP_IP <= PHY_output[31:0];
		 left_shift <= 240;
		 end 
	
	default: begin
			 left_shift <= left_shift + 1'b1;
			 PHY_Rx_state <= DHCP;
			end
	endcase		
end
	
// Process ping request. Save (Length - 24) bytes in RAM, then exit.
// We need to save 4 + Payload Length bytes so for 32 bytes we save 36 etc.
// The 4 bytes are the Identifier and Sequence Number
PING:
	begin
		if (ping_count == (Length - 24))  begin
			ping_request <= 1'b1;				   		// set the ping flag
			PHY_Rx_state <= RETURN;
		end
		else begin		
			ping_data[ping_count] <= PHY_output[7:0];
			ping_count <= ping_count + 1'b1;
			PHY_Rx_state <= PING;
		end
	end 

	
// Clear any test flags and return to the start
RETURN:
	begin
		data_match <= 1'b0;							// ****  clear test flag ******
		PHY_Rx_state <= START; 						// frame is over so loop to start
	end
default: PHY_Rx_state <= START;	
endcase
end 

   
endmodule
