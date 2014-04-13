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


//  Tx_MAC - Copyright 2009, 2010, 2011  Phil Harman VK6APH






//----------------------------------------
//   Tx_MAC - Interface to PHY
//----------------------------------------

/* 
	The format of the data to the PHY at 100T is as follows
	
	                  +----+    +----+    +----+    +----+    +----+    +----+    +----+    +----+    
	PHY_Tx_clock    --+    +----+    +----+    +----+    +----+    +----+    +----+    +----+  		25MHz
	
					      	  +-----------------------------------------------------------------
	Tx_CTL     ------------+
	
	                       +---------+---------+---------+---------+---------+---------+---------+
	TD					        +---------+---------+---------+---------+---------+---------+---------+
	
	nibble (100T)          3:0       7:4       3:0       7:4       3:0       7:4       3:0       7:4
	


	
 
    At 1000T the 3:0 nibble is sent on the positive edge of Rx_clock and 7:4 on the negative edge vis:
    
    
    	             +----+    +----+    +----+    +----+    +----+    +----+    +----+    +----+    
	PHY_Tx_clock    +    +----+    +----+    +----+    +----+    +----+    +----+    +----+  		125MHz
		
						        +-----------------------------------------------------------------
	Tx_CTL     ------------+
	
	                       +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
	TD					        +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
	
	nibble (100T)          3:0  7:4  3:0  7:4  3:0  7:4  3:0  7:4  3:0  7:4  3:0  7:4  3:0  7:4  3:0 
	
	
	Operation is as follows:
	
	The transmit state machine loops looking for either an APR request, ping request or the PHY_Tx fifo having > 1023
	bytes in it. The latter conditions indicates a UDP/IP send request.
	
	ARP:
	This causes a read of a predetermed sequence of bytes that are addressed in sequence by a state machine.
	During the procees the CRC32 calculation is started and appended at the end of the sequence of bytes.
	
	
	PING:
	This first calculates the ping checksum, reads a predetermend sequence of bytes that are addressed in sequence
	then appends the original ping data obtained by the Rx_MAC. During the procees the CRC32 calculation is started
	and appended at the end of the ping data.
	
	
	UDP/IP:
	This causes a read of a predetermed sequence of bytes that are addressed in sequence by a state machine.
	1024 bytes from the PHY_Tx fifo are then appended. During the procees the CRC32 calculation is started
	and appended at the end of the fifo bytes.
	
	NOTE: This code makes use of a large number of states. Each packet that we send uses it own dedicated state
	machine. It is possible to combine common elements of the code e.g. preamble. However, doing so does not 
	reduced the size of the code since Quartus is able to optimise away the duplicated states. The use of individual 
	state machines had been used to make the code more readable.
	
	Change log:
	

	2011 Mar   11    	- Send DHCP server IP address as an option in DHCP_request.
	     Apr    2    	- Reset sequence number when not running rather than when Discovery received. 
							- Add run state and Metis software version to Discovery reply.
					3    	- Add wide band spectrum and on/off enable
	     May   13     - Added independant serial number for wide bandscope data.

*/

module Tx_MAC (Tx_clock, Tx_clock_2, IF_rst, Send_ARP,ping_reply,
			   PHY_Tx_data, PHY_Tx_rdused, ping_data, LED, Tx_fifo_rdreq,
			   Tx_CTL, ARP_sent, ping_sent, TD, DHCP_discover, DHCP_discover_sent,
			   This_MAC,SIADDR, DHCP_request,
			   DHCP_request_sent, METIS_discovery, PC_IP, PC_MAC,
			   Port, This_IP, METIS_discover_sent, ARP_PC_MAC, ARP_PC_IP,
			   Ping_PC_MAC, Ping_PC_IP, Length, speed_100T, Tx_reset, run, wide_spectrum,
			   IP_valid, printf, IP_lease, DHCP_IP, DHCP_MAC, DHCP_request_renew, DHCP_request_renew_sent,
			   erase_done, erase_done_ACK, send_more, send_more_ACK, Hermes_serialno,
			   sp_fifo_rddata, sp_fifo_rdreq, sp_fifo_rdempty, sp_fifo_rdused, have_sp_data,
				 AssignIP);
			   
			   
			   
input  Tx_clock;					// 25MHz for 100T
input  Tx_clock_2;				// clock/2
input  IF_rst;						// reset signal
input  Send_ARP;					// high to send ARP response
input  ping_reply;				// high to send ping response
input  [7:0]PHY_Tx_data;		// data to send to PHY
input  [10:0]PHY_Tx_rdused;	// data available in Tx fifo  
input  [7:0]ping_data[0:59];   // data to send back 	
input  DHCP_discover; 			// high when requested
input  [47:0]This_MAC;			// MAC address of this Metis board
input  [31:0]SIADDR;				// IP address of server that provided IP address
input  DHCP_request;				// high when request required
input  METIS_discovery;			// high when reply required
input  [31:0]PC_IP;				// IP address of the PC we are connecting to
input  [47:0]PC_MAC;				// MAC address of the PC we are connecting to
input  [15:0]Port;			   // Port on the PC we are sending to
input  [31:0]This_IP;			// IP address provided by PC or DHCP at start up
input  [47:0]ARP_PC_MAC;		// MAC address of PC requesting ARP
input  [31:0]ARP_PC_IP;			// IP address of PC requesting ARP
input  [47:0]Ping_PC_MAC;		// MAC address of PC requesting ping
input  [31:0]Ping_PC_IP;		// IP address of PC requesting ping
input  [15:0]Length;				// Lenght of packet - used by ping
input  speed_100T;				// high for 100T,low for 1000T       ************  check
input  Tx_reset;					// high to prevent I&Q data being sent
input  run;							// high to enable data to be sent
input  wide_spectrum;			// high to enable wide spectrum data to be sent
input  IP_valid;					// high when we have a valid IP address 
input  printf;						// high when we want to send debug data
input  [31:0]IP_lease;			// *** test data - IP lease time in seconds
input  [31:0]DHCP_IP;			// IP address of DHCP server
input  [47:0]DHCP_MAC;			// MAC address of DHCP server 
input  DHCP_request_renew;		// set when renew required
input  erase_done;				// set when we what to tell the PC we have completed the EPCS16 erase
input  send_more;					// set when we want the next block of 256 bytes for the EPCS16
input  [7:0]Hermes_serialno;	// Hermes code version
input  [7:0]sp_fifo_rddata;		// raw ACD data from Mercury for wide bandscope
input  sp_fifo_rdempty;			// SP_fifo read empty
input  [12:0]sp_fifo_rdused;	// SP_fifo contents
input  have_sp_data;				// high when sp_fifo is full.
input  [31:0]AssignIP;			// IP address read from EEPROM

output LED;							// show MAC is doing something!
output Tx_fifo_rdreq;			// high to indicate read from Tx fifo required
output Tx_CTL;						// high to enable write to PHY
output ARP_sent;					// high indicates ARP has been sent
output ping_sent;					// high indicates ping reply has been sent
output [3:0]TD;					// nibble to send to PHY
output DHCP_discover_sent;		// high when has been sent
output DHCP_request_sent;       // high when has been sent
output METIS_discover_sent;		// high when has been sent ** pulse
output DHCP_request_renew_sent;	// high when has been sent
output erase_done_ACK;			// set when we have sent erase of EPCS16 complete to PC
output send_more_ACK;			// set when we confirm we have requested more EPCS data from PC
output sp_fifo_rdreq;			// SP_fifo read require signal



// HPSDR specific			
parameter HPSDR_frame = 8'h01;  	// HPSDR Frame type
parameter HPSDR_IP_frame = 8'h03; // Read IP Frame type 
// parameter end_point = 8'h06;	// HPSDR end point - 6 to indicate fifo write 
parameter Type_1 = 8'hEF;	    	// Ethernet Frame type
parameter Type_2 = 8'hFE;
localparam TxPort = 16'd1024;		// Metis 'from' port
localparam IP_MAC = 48'h11_22_33_44_55_66;  // MAC address used for setting and reading IP address

localparam
			RESET = 0,
			UDP  = 1,
			METIS_DISCOVERY = 2,
			ARP = 3,
			PING1 = 4,
			PING2 = 5,
			DHCP_DISCOVER = 6,
			DHCP_REQUEST = 7,
			DHCP_REQUEST_RENEW = 8,
			PRINTF = 9,
			SPECTRUM = 10,
			SENDIP = 11,
			CRC = 12;

			
wire [31:0] CRC32;				   	// holds 802.3 CRC result 
reg  [31:0] temp_CRC32 = 0; 

reg  [31:0] sequence_number = 0;
reg  [31:0] spec_seq_number = 0;


reg [6:0] state_Tx;             	// state for FX2
reg [10:0] data_count;
reg [10:0] sp_data_count;
reg reset_CRC;
reg [7:0] Tx_data;
reg [4:0] gap_count;
reg ARP_sent;					    	// true when we have replied to an ARP request
reg LED; 						    	// Test LED
reg erase_done_ACK;					// set when we have sent erase of EPCS16 complete to PC
reg send_more_ACK;					// set when we confirm we have requested more EPCS data from PC
reg [31:0]Discovery_IP;				// IP address of PC doing Discovery
reg [47:0]Discovery_MAC;			// MAC address of PC doing Discovery
reg [15:0]Discovery_Port;			// Port Address of PC doing Discovery

reg [7:0]end_point; 					// USB end point equivalent 8'h06 for IQ data and 8'h04 for Spectrum
reg [4:0]IP_count;					// holds shift count when sending IP to PHY TX fifo

// calculate the IP checksum, big-endian style
// The 0xC935 is fixed and made up of the 16 bit add of the header data. *** this will need changing if we change payload size  ****
// i.e. 0x4500 + 0x0424 + 0x8011 = 0xC935 
// then add the IPsource and IPDesitination in 16 bits using 1's complement and then complement

// calculate the UDP/IP checksum
wire [31:0]IPchecksum1;
wire [31:0]IPchecksum2;
wire [15:0]IPchecksum3;

assign IPchecksum1 = 32'h0000C935 + This_IP[31:16] + This_IP[15:0] + PC_IP[31:16] + PC_IP[15:0];
                        
assign IPchecksum2 =  ((IPchecksum1 & 32'h0000FFFF) + (IPchecksum1 >> 16));  	// 1's complement add, shift the higher order bits and add
assign IPchecksum3 = ~((IPchecksum2 & 32'h0000FFFF) + (IPchecksum2 >> 16));	// again, then complement

// calculate the UDP/IP checksum for Metis discovery 
wire [31:0]DISchecksum1;
wire [31:0]DISchecksum2;
wire [15:0]DISchecksum3;

assign DISchecksum1 = 32'h00004500 + 32'h00000058 + 32'h00008011 + This_IP[31:16] + This_IP[15:0] +
                        Discovery_IP[31:16] + Discovery_IP[15:0];
                        
assign DISchecksum2 =  ((DISchecksum1 & 32'h0000FFFF) + (DISchecksum1 >> 16));  	// 1's complement add, shift the higher order bits and add
assign DISchecksum3 = ~((DISchecksum2 & 32'h0000FFFF) + (DISchecksum2 >> 16));	// again, then complement


// calculate the IP checksum for ICMP (ping)
wire [31:0]ICMPchecksum1;
wire [31:0]ICMPchecksum2;
wire [15:0]ICMPchecksum3;

assign ICMPchecksum1 = 32'h00004500 + Length + 32'h00008001 + This_IP[31:16] + This_IP[15:0] +
						  Ping_PC_IP[31:16] + Ping_PC_IP[15:0];
                        
assign ICMPchecksum2 =  ((ICMPchecksum1 & 32'h0000FFFF) + (ICMPchecksum1 >> 16));  // 1's complement add, shift the higher order bits and add
assign ICMPchecksum3 = ~((ICMPchecksum2 & 32'h0000FFFF) + (ICMPchecksum2 >> 16));  // again, then complement

// calculate the IP checksum for DHCP discovery  
wire [31:0]DHCPchecksum1;
wire [31:0]DHCPchecksum2;
wire [15:0]DHCPchecksum3;

assign DHCPchecksum1 = 32'h00004500 + UDP_DHCP_length + 32'h00008011 + 32'h0000FFFF + 32'h0000FFFF;
                        
assign DHCPchecksum2 =  ((DHCPchecksum1 & 32'h0000FFFF) + (DHCPchecksum1 >> 16));  // 1's complement add, shift the higher order bits and add
assign DHCPchecksum3 = ~((DHCPchecksum2 & 32'h0000FFFF) + (DHCPchecksum2 >> 16));  // again, then complement

// calculate IP checksum for DHCP request
wire [31:0]DHCP_req_checksum1;
wire [31:0]DHCP_req_checksum2;
wire [15:0]DHCP_req_checksum3;

assign DHCP_req_checksum1 = 32'h00004500 + UDP_DHCP_req_length + 32'h00008011 + 32'h0000FFFF + 32'h0000FFFF;
                        
assign DHCP_req_checksum2 =  ((DHCP_req_checksum1 & 32'h0000FFFF) + (DHCP_req_checksum1 >> 16));  // 1's complement add, shift the higher order bits and add
assign DHCP_req_checksum3 = ~((DHCP_req_checksum2 & 32'h0000FFFF) + (DHCP_req_checksum2 >> 16));  // again, then complement

// calculate IP checksum for DHCP request renew
wire [31:0]DHCP_req_renew_checksum1;
wire [31:0]DHCP_req_renew_checksum2;
wire [15:0]DHCP_req_renew_checksum3;

assign DHCP_req_renew_checksum1 = 32'h00004500 + UDP_DHCP_req_renew_length + 32'h00008011 + This_IP[31:16] + This_IP[15:0] +
							      DHCP_IP[31:16] + DHCP_IP[15:0];
							                              
assign DHCP_req_renew_checksum2 =  ((DHCP_req_renew_checksum1 & 32'h0000FFFF) + (DHCP_req_renew_checksum1 >> 16));  // 1's complement add, shift the higher order bits and add
assign DHCP_req_renew_checksum3 = ~((DHCP_req_renew_checksum2 & 32'h0000FFFF) + (DHCP_req_renew_checksum2 >> 16));  // again, then complement



wire [15:0]DHCP_length;
wire [15:0]UDP_DHCP_length;

wire [15:0]DHCP_req_length;
wire [15:0]UDP_DHCP_req_length;

wire [15:0]DHCP_req_renew_length;
wire [15:0]UDP_DHCP_req_renew_length;


reg [9:0] rdaddress;
reg [7:0] pkt_data;
reg [7:0] ck_count;
reg [31:0]ping_check_temp;
reg [15:0]ping_check_sum;
reg ping_sent;
reg [8:0] zero_count;
reg [3:0]interframe;
reg printf;
reg DHCP_request_renew_sent;
reg Metis_discover_sent;
reg [7:0] frame;				// HPSDR frame type; 0x02 for Discovery reply, 
									//                   0x03 for EPCS16 erase complete and 
									//					      0x04 for send next 256 bytes for EPCS16 program
reg [31:0]temp_IP;			// holds IP address from EEPROM whilst we are shifting


always @ * 
case(rdaddress)
//---------- UDP/IP packet --------
// Ethernet preamble
  0 : pkt_data <= 8'h55;
  1 : pkt_data <= 8'h55;
  2 : pkt_data <= 8'h55;
  3 : pkt_data <= 8'h55;
  4 : pkt_data <= 8'h55;
  5 : pkt_data <= 8'h55;
  6 : pkt_data <= 8'h55;
  7 : pkt_data <= 8'hD5;
// Ethernet header
  8 : pkt_data <= PC_MAC[47:40];
  9 : pkt_data <= PC_MAC[39:32];
  10: pkt_data <= PC_MAC[31:24];
  11: pkt_data <= PC_MAC[23:16];
  12: pkt_data <= PC_MAC[15:8];
  13: pkt_data <= PC_MAC[7:0];
  14: pkt_data <= This_MAC[47:40];
  15: pkt_data <= This_MAC[39:32];
  16: pkt_data <= This_MAC[31:24];
  17: pkt_data <= This_MAC[23:16];
  18: pkt_data <= This_MAC[15:8];
  19: pkt_data <= This_MAC[7:0];
  20: pkt_data <= 8'h08;
  21: pkt_data <= 8'h00;
 // IP header 
  22: pkt_data <= 8'h45;				// Version
  23: pkt_data <= 8'h00;				// Type of service
  24: pkt_data <= 8'h04;				// length ***** CHANGE CHECKSUM IF LENGTH CHANGES *****
  25: pkt_data <= 8'h24;				// total of 1060 bytes, 1032 UDP data + 8 UDP header + 20 IP header
  26: pkt_data <= 8'h00;				// Identification
  27: pkt_data <= 8'h00;
  28: pkt_data <= 8'h00;				// Flags, Fragment
  29: pkt_data <= 8'h00;
  30: pkt_data <= 8'h80;				// Time to live
  31: pkt_data <= 8'h11;				// Protocol (0x11 = UDP)
  32: pkt_data <= IPchecksum3[15:8];	// Checksum
  33: pkt_data <= IPchecksum3[ 7:0];
  34: pkt_data <= This_IP[31:24];		// Source IP Address is IP address allocated to this board
  35: pkt_data <= This_IP[23:16];
  36: pkt_data <= This_IP[15:8];
  37: pkt_data <= This_IP[7:0];
  38: pkt_data <= PC_IP[31:24];			// Destination PC IP Address
  39: pkt_data <= PC_IP[23:16];
  40: pkt_data <= PC_IP[15:8];
  41: pkt_data <= PC_IP[7:0];
// UDP header
  42: pkt_data <= TxPort[15:8];			// 'from' port = 1024
  43: pkt_data <= TxPort[7:0];
  44: pkt_data <= Port[15:8];				// destination port assigned by PC during Metis Discovery (i.e. PC 'from' Port)
  45: pkt_data <= Port[7:0];
  46: pkt_data <= 8'h04;					// length
  47: pkt_data <= 8'h10;	    			// total of 1040 bytes (1032 UDP data + 8 UDP header)
  48: pkt_data <= 8'h00;					// UDP Checksum (set to all zero which is valid for IP4 but not IP6)
  49: pkt_data <= 8'h00;
// Start of Payload
  50: pkt_data <= Type_1;	    			// Ethernet Frame type 0xEFFE (HPSDR)
  51: pkt_data <= Type_2;
  52: pkt_data <= HPSDR_frame;			// HPSDR Frame type 
  53: pkt_data <= end_point;				// HPSDR end point
  54: pkt_data <= (state_Tx == SPECTRUM) ? spec_seq_number[31:24] : sequence_number[31:24]; // 32bit sequence numbers 
  55: pkt_data <= (state_Tx == SPECTRUM) ? spec_seq_number[23:16] : sequence_number[23:16];
  56: pkt_data <= (state_Tx == SPECTRUM) ? spec_seq_number[15:8]  : sequence_number[15:8];
  57: pkt_data <= (state_Tx == SPECTRUM) ? spec_seq_number[7:0]   : sequence_number[7:0];   
  // followed by 1024 bytes of data
  // then CRC32 - CRC[7:0] is stored in each state &
  // all states use this code to add the balance of the CRC
  58: pkt_data <= temp_CRC32[15:8];
  59: pkt_data <= temp_CRC32[23:16];
  60: pkt_data <= temp_CRC32[31:24];
  
//----------  ARP reply data -----------
// Ethernet preamble
 100: pkt_data <= 8'h55;
 101: pkt_data <= 8'h55;
 102: pkt_data <= 8'h55;
 103: pkt_data <= 8'h55;
 104: pkt_data <= 8'h55;
 105: pkt_data <= 8'h55;
 106: pkt_data <= 8'h55;
 107: pkt_data <= 8'hD5;
// Ethernet header
 108: pkt_data <= ARP_PC_MAC[47:40];	// MAC address of PC requesting ARP
 109: pkt_data <= ARP_PC_MAC[39:32];
 110: pkt_data <= ARP_PC_MAC[31:24];
 111: pkt_data <= ARP_PC_MAC[23:16];
 112: pkt_data <= ARP_PC_MAC[15:8];
 113: pkt_data <= ARP_PC_MAC[7:0];
 114: pkt_data <= This_MAC[47:40];		// MAC address of this Metis board
 115: pkt_data <= This_MAC[39:32];
 116: pkt_data <= This_MAC[31:24];
 117: pkt_data <= This_MAC[23:16];
 118: pkt_data <= This_MAC[15:8];
 119: pkt_data <= This_MAC[7:0];
 // ARP reply 
 120: pkt_data <= 8'h08;
 121: pkt_data <= 8'h06;
 122: pkt_data <= 8'h00;					// Hardware type
 123: pkt_data <= 8'h01;
 124: pkt_data <= 8'h08;					// Protocol Type
 125: pkt_data <= 8'h00;
 126: pkt_data <= 8'h06;					// Hardware Length
 127: pkt_data <= 8'h04;					// Protocol Length
 128: pkt_data <= 8'h00;					// Operation, ARP reply, 0x0002
 129: pkt_data <= 8'h02;
 130: pkt_data <= This_MAC[47:40];		// MAC address of this Metis board
 131: pkt_data <= This_MAC[39:32];
 132: pkt_data <= This_MAC[31:24];
 133: pkt_data <= This_MAC[23:16];
 134: pkt_data <= This_MAC[15:8];
 135: pkt_data <= This_MAC[7:0];
 136: pkt_data <= This_IP[31:24];		// IP address assigned to this Metis board
 137: pkt_data <= This_IP[23:16];
 138: pkt_data <= This_IP[15:8];
 139: pkt_data <= This_IP[7:0];
 140: pkt_data <= ARP_PC_MAC[47:40];	// MAC address of PC requesting ARP
 141: pkt_data <= ARP_PC_MAC[39:32];
 142: pkt_data <= ARP_PC_MAC[31:24];
 143: pkt_data <= ARP_PC_MAC[23:16];
 144: pkt_data <= ARP_PC_MAC[15:8];
 145: pkt_data <= ARP_PC_MAC[7:0];
 146: pkt_data <= ARP_PC_IP[31:24]; 	// IP address of PC requesting ARP
 147: pkt_data <= ARP_PC_IP[23:16]; 	
 148: pkt_data <= ARP_PC_IP[15:8];  	
 149: pkt_data <= ARP_PC_IP[7:0];   	
 // send 18 zeros to pad payload out to 60 bytes
 // followed by CRC at raddress = 58


 //----------  ping reply -----------
 // Ethernet preamble
 200: pkt_data <= 8'h55;
 201: pkt_data <= 8'h55;
 202: pkt_data <= 8'h55;
 203: pkt_data <= 8'h55;
 204: pkt_data <= 8'h55;
 205: pkt_data <= 8'h55;
 206: pkt_data <= 8'h55;
 207: pkt_data <= 8'hD5;
// Ethernet header
 208: pkt_data <= Ping_PC_MAC[47:40]; 	// MAC address of PC requesting the ping
 209: pkt_data <= Ping_PC_MAC[39:32];
 210: pkt_data <= Ping_PC_MAC[31:24];
 211: pkt_data <= Ping_PC_MAC[23:16];
 212: pkt_data <= Ping_PC_MAC[15:8];
 213: pkt_data <= Ping_PC_MAC[7:0];
 214: pkt_data <= This_MAC[47:40];
 215: pkt_data <= This_MAC[39:32];
 216: pkt_data <= This_MAC[31:24];
 217: pkt_data <= This_MAC[23:16];
 218: pkt_data <= This_MAC[15:8];
 219: pkt_data <= This_MAC[7:0];
 220: pkt_data <= 8'h08;
 221: pkt_data <= 8'h00;
 // IP header 
 222: pkt_data <= 8'h45;					// Version
 223: pkt_data <= 8'h00;					// Type of service
 224: pkt_data <= Length[15:8];//8'h00;				// length
 225: pkt_data <= Length[7:0];//8'h3C;				// total of 60 bytes
 226: pkt_data <= 8'h00;					// Identification
 227: pkt_data <= 8'h00;
 228: pkt_data <= 8'h00;					// Flags, Fragment
 229: pkt_data <= 8'h00;
 230: pkt_data <= 8'h80;					// Time to live
 231: pkt_data <= 8'h01;					// Protocol (0x01 = ICMP - ping)   
 232: pkt_data <= ICMPchecksum3[15:8];	// Checksum
 233: pkt_data <= ICMPchecksum3[ 7:0];
 234: pkt_data <= This_IP[31:24];		// IP Address of this Metis board
 235: pkt_data <= This_IP[23:16];
 236: pkt_data <= This_IP[15:8];
 237: pkt_data <= This_IP[7:0];
 238: pkt_data <= Ping_PC_IP[31:24];	// IP address of PC requesting the ping
 239: pkt_data <= Ping_PC_IP[23:16];
 240: pkt_data <= Ping_PC_IP[15:8];
 241: pkt_data <= Ping_PC_IP[7:0];
// ICMP packet 
 242: pkt_data <= 8'h00;						// 0x00 echo reply, 0x08 for request
 243: pkt_data <= 8'h00;						// code
 244: pkt_data <= ping_check_sum[15:8];	// Checksum 
 245: pkt_data <= ping_check_sum[7:0];
// Start data - 36 bytes 
// followed by CRC at raddress = 58

//----------  DHCP discover -----------
// UDP/IP packet
// Ethernet preamble
 300: pkt_data <= 8'h55;
 301: pkt_data <= 8'h55;
 302: pkt_data <= 8'h55;
 303: pkt_data <= 8'h55;
 304: pkt_data <= 8'h55;
 305: pkt_data <= 8'h55;
 306: pkt_data <= 8'h55;
 307: pkt_data <= 8'hD5;
// Ethernet header
 308: pkt_data <= 8'hFF;				// Destination MAC is FF FF FF FF FF FF
 309: pkt_data <= 8'hFF;
 310: pkt_data <= 8'hFF;
 311: pkt_data <= 8'hFF;
 312: pkt_data <= 8'hFF;
 313: pkt_data <= 8'hFF;
 314: pkt_data <= This_MAC[47:40];
 315: pkt_data <= This_MAC[39:32];
 316: pkt_data <= This_MAC[31:24];
 317: pkt_data <= This_MAC[23:16];
 318: pkt_data <= This_MAC[15:8];
 319: pkt_data <= This_MAC[7:0];
 320: pkt_data <= 8'h08;
 321: pkt_data <= 8'h00;
 // IP header 
 322: pkt_data <= 8'h45;				// Version
 323: pkt_data <= 8'h00;				// Type of service
 324: pkt_data <= UDP_DHCP_length[15:8];	// length
 325: pkt_data <= UDP_DHCP_length[7:0];		// UDP data + 8 UDP header + 20 IP header
 326: pkt_data <= 8'h00;				// Identification
 327: pkt_data <= 8'h00;
 328: pkt_data <= 8'h00;				// Flags, Fragment
 329: pkt_data <= 8'h00;
 330: pkt_data <= 8'h80;				// Time to live
 331: pkt_data <= 8'h11;				// Protocol (0x11 = UDP)
 332: pkt_data <= DHCPchecksum3[15:8];	// Checksum
 333: pkt_data <= DHCPchecksum3[ 7:0];
 334: pkt_data <= 8'h00;				// Source IP Address
 335: pkt_data <= 8'h00;
 336: pkt_data <= 8'h00;
 337: pkt_data <= 8'h00;
 338: pkt_data <= 8'hFF;				// Destination IP Address
 339: pkt_data <= 8'hFF;
 340: pkt_data <= 8'hFF;
 341: pkt_data <= 8'hFF;
// UDP header
 342: pkt_data <= 8'h00;				// source port = 68
 343: pkt_data <= 8'h44;
 344: pkt_data <= 8'h00;				// destination port = 67
 345: pkt_data <= 8'h43;
 346: pkt_data <= DHCP_length[15:8];	// length
 347: pkt_data <= DHCP_length[7:0];	    // total of 252 bytes (244 UDP data + 8 UDP header)
 348: pkt_data <= 8'h00;				// UDP Checksum (set to all zero which is valid for IP4 but not IP6)
 349: pkt_data <= 8'h00; 
 // DHCP Discover
 350: pkt_data <= 8'h01;
 351: pkt_data <= 8'h01;
 352: pkt_data <= 8'h06;
 353: pkt_data <= 8'h00;
 // 24 x 0x00
 354: pkt_data <= This_MAC[47:40];
 355: pkt_data <= This_MAC[39:32];
 356: pkt_data <= This_MAC[31:24];
 357: pkt_data <= This_MAC[23:16];
 358: pkt_data <= This_MAC[15:8];
 359: pkt_data <= This_MAC[7:0]; 
 // 202 x 0x00
 360: pkt_data <= 8'h63;			// Magic Cookie
 361: pkt_data <= 8'h82;
 362: pkt_data <= 8'h53;
 363: pkt_data <= 8'h63;
 // Options
 364: pkt_data <= 8'h35;			// Options
 365: pkt_data <= 8'h01;
 366: pkt_data <= 8'h01;
 // End
 367: pkt_data <= 8'hFF;
	

//----------  DHCP request ---------- 
// UDP/IP packet
// Ethernet preamble
 400: pkt_data <= 8'h55;
 401: pkt_data <= 8'h55;
 402: pkt_data <= 8'h55;
 403: pkt_data <= 8'h55;
 404: pkt_data <= 8'h55;
 405: pkt_data <= 8'h55;
 406: pkt_data <= 8'h55;
 407: pkt_data <= 8'hD5;
// Ethernet header
 408: pkt_data <= 8'hFF;				// Destination MAC is FF FF FF FF FF FF
 409: pkt_data <= 8'hFF;
 410: pkt_data <= 8'hFF;
 411: pkt_data <= 8'hFF;
 412: pkt_data <= 8'hFF;
 413: pkt_data <= 8'hFF;
 414: pkt_data <= This_MAC[47:40];
 415: pkt_data <= This_MAC[39:32];
 416: pkt_data <= This_MAC[31:24];
 417: pkt_data <= This_MAC[23:16];
 418: pkt_data <= This_MAC[15:8];
 419: pkt_data <= This_MAC[7:0];
 420: pkt_data <= 8'h08;
 421: pkt_data <= 8'h00;
 // IP header 
 422: pkt_data <= 8'h45;				// Version
 423: pkt_data <= 8'h00;				// Type of service
 424: pkt_data <= UDP_DHCP_req_length[15:8];	// length
 425: pkt_data <= UDP_DHCP_req_length[7:0];		// UDP data + 8 UDP header + 20 IP header
 426: pkt_data <= 8'h00;				// Identification
 427: pkt_data <= 8'h00;
 428: pkt_data <= 8'h00;				// Flags, Fragment
 429: pkt_data <= 8'h00;
 430: pkt_data <= 8'h80;				// Time to live
 431: pkt_data <= 8'h11;				// Protocol (0x11 = UDP)
 432: pkt_data <= DHCP_req_checksum3[15:8];	// Checksum
 433: pkt_data <= DHCP_req_checksum3[ 7:0];
 434: pkt_data <= 8'h00;				// Source IP Address
 435: pkt_data <= 8'h00;
 436: pkt_data <= 8'h00;
 437: pkt_data <= 8'h00;
 438: pkt_data <= 8'hFF;				// Destination IP Address
 439: pkt_data <= 8'hFF;
 440: pkt_data <= 8'hFF;
 441: pkt_data <= 8'hFF;
// UDP header
 442: pkt_data <= 8'h00;				// source port = 68
 443: pkt_data <= 8'h44;
 444: pkt_data <= 8'h00;				// destination port = 67
 445: pkt_data <= 8'h43;
 446: pkt_data <= DHCP_req_length[15:8];	// length
 447: pkt_data <= DHCP_req_length[7:0];	    // total of 252 bytes (246 UDP data + 8 UDP header)
 448: pkt_data <= 8'h00;				// UDP Checksum (set to all zero which is valid for IP4 but not IP6)
 449: pkt_data <= 8'h00; 
 // DHCP Request
 450: pkt_data <= 8'h01;
 451: pkt_data <= 8'h01;
 452: pkt_data <= 8'h06;
 453: pkt_data <= 8'h00;
 // 24 x 0x00
 454: pkt_data <= This_MAC[47:40];
 455: pkt_data <= This_MAC[39:32];
 456: pkt_data <= This_MAC[31:24];
 457: pkt_data <= This_MAC[23:16];
 458: pkt_data <= This_MAC[15:8];
 459: pkt_data <= This_MAC[7:0]; 
 // 202 x 0x00
 460: pkt_data <= 8'h63;				// Magic Cookie
 461: pkt_data <= 8'h82;
 462: pkt_data <= 8'h53;
 463: pkt_data <= 8'h63;
 // Options
 464: pkt_data <= 8'h35;				// Options
 465: pkt_data <= 8'h01;
 466: pkt_data <= 8'h03;
 467: pkt_data <= 8'h32;				 		
 468: pkt_data <= 8'h04;
 469: pkt_data <= This_IP[31:24];	// IP address being accepted
 470: pkt_data <= This_IP[23:16];
 471: pkt_data <= This_IP[15:8];
 472: pkt_data <= This_IP[7:0];
 473: pkt_data <= 8'h36;
 474: pkt_data <= 8'h04;
 475: pkt_data <= DHCP_IP[31:24];	// IP address of DHCP server
 476: pkt_data <= DHCP_IP[23:16];
 477: pkt_data <= DHCP_IP[15:8];
 478: pkt_data <= DHCP_IP[7:0];
 // End
 479: pkt_data <= 8'hFF;
 
 
//----------  UDP/IP packet in reply to Metis discovery request ----
// Ethernet preamble
 500: pkt_data <= 8'h55;
 501: pkt_data <= 8'h55;
 502: pkt_data <= 8'h55;
 503: pkt_data <= 8'h55;
 504: pkt_data <= 8'h55;
 505: pkt_data <= 8'h55;
 506: pkt_data <= 8'h55;
 507: pkt_data <= 8'hD5;
// Ethernet header
 508: pkt_data <= Discovery_MAC[47:40];
 509: pkt_data <= Discovery_MAC[39:32];
 510: pkt_data <= Discovery_MAC[31:24];
 511: pkt_data <= Discovery_MAC[23:16];
 512: pkt_data <= Discovery_MAC[15:8];
 513: pkt_data <= Discovery_MAC[7:0];
 514: pkt_data <= This_MAC[47:40];
 515: pkt_data <= This_MAC[39:32];
 516: pkt_data <= This_MAC[31:24];
 517: pkt_data <= This_MAC[23:16];
 518: pkt_data <= This_MAC[15:8];
 519: pkt_data <= This_MAC[7:0];
 520: pkt_data <= 8'h08;
 521: pkt_data <= 8'h00;
 // IP header 
 522: pkt_data <= 8'h45;				// Version
 523: pkt_data <= 8'h00;				// Type of service
 524: pkt_data <= 8'h00;				// length  ***** CHANGE CHECKSUM IF LENGTH CHANGES *****
 525: pkt_data <= 8'h58;				// total of 88 bytes, 60 UDP data + 8 UDP header + 20 IP header
 526: pkt_data <= 8'h00;				// Identification
 527: pkt_data <= 8'h00;
 528: pkt_data <= 8'h00;				// Flags, Fragment
 529: pkt_data <= 8'h00;
 530: pkt_data <= 8'h80;				// Time to live
 531: pkt_data <= 8'h11;				// Protocol (0x11 = UDP)
 532: pkt_data <= DISchecksum3[15:8];	// Checksum  			
 533: pkt_data <= DISchecksum3[ 7:0];
 534: pkt_data <= This_IP[31:24];		// Source IP Address
 535: pkt_data <= This_IP[23:16];
 536: pkt_data <= This_IP[15:8];
 537: pkt_data <= This_IP[7:0];
 538: pkt_data <= Discovery_IP[31:24];			// Destination PC IP Address
 539: pkt_data <= Discovery_IP[23:16];
 540: pkt_data <= Discovery_IP[15:8];
 541: pkt_data <= Discovery_IP[7:0];
// UDP header
 542: pkt_data <= TxPort[15:8];			// 'from' port
 543: pkt_data <= TxPort[7:0];
 544: pkt_data <= Discovery_Port[15:8];	// destination port assigned by PC
 545: pkt_data <= Discovery_Port[7:0];
 546: pkt_data <= 8'h00;				// length
 547: pkt_data <= 8'h44;	    		// total of 68 bytes (60 UDP data + 8 UDP header)
 548: pkt_data <= 8'h00;				// UDP Checksum (set to all zero which is valid for IP4 but not IP6)
 549: pkt_data <= 8'h00;
// Start of Payload
 550: pkt_data <= Type_1;	    		// Ethernet Frame type 0xEFFE (HPSDR)
 551: pkt_data <= Type_2;
 552: pkt_data <= frame + run;			// HPSDR Frame type = discovery reply = 0x02 or 0x03 if running
 553: pkt_data <= This_MAC[47:40];		// This Metis MAC Address
 554: pkt_data <= This_MAC[39:32];
 555: pkt_data <= This_MAC[31:24];
 556: pkt_data <= This_MAC[23:16];
 557: pkt_data <= This_MAC[15:8];
 558: pkt_data <= This_MAC[7:0];
 559: pkt_data <= Hermes_serialno;
 // send 50 zeros to give a minimum payload of 60 bytes  *** sending 0x01 now 
 // then CRC 
 
 
 // ---------- printf test code -----------------
 // Ethernet preamble
 600 : pkt_data <= 8'h55;
 601 : pkt_data <= 8'h55;
 602 : pkt_data <= 8'h55;
 603 : pkt_data <= 8'h55;
 604 : pkt_data <= 8'h55;
 605 : pkt_data <= 8'h55;
 606 : pkt_data <= 8'h55;
 607 : pkt_data <= 8'hD5;
// Ethernet header
 608 : pkt_data <= 8'hFF;
 609 : pkt_data <= 8'hFF;
 610 : pkt_data <= 8'hFF;
 611 : pkt_data <= 8'hFF;
 612 : pkt_data <= 8'hFF;
 613 : pkt_data <= 8'hFF;
 614 : pkt_data <= This_MAC[47:40]; 		// MAC address of this Metis Board
 615 : pkt_data <= This_MAC[39:32]; 
 616 : pkt_data <= This_MAC[31:24];
 617 : pkt_data <= This_MAC[23:16]; 
 618 : pkt_data <= This_MAC[15:8];  
 619 : pkt_data <= This_MAC[7:0];   
// Start of Payload
 620: pkt_data <= 8'hEF;	    			// Ethernet Frame type 0xEFFF (printf)
 621: pkt_data <= 8'hFF;
 622: pkt_data <= HPSDR_frame;			// HPSDR Frame type 
 623: pkt_data <= 8'hFF;
 624: pkt_data <= This_IP[31:24];		// Source IP Address
 625: pkt_data <= This_IP[23:16];
 626: pkt_data <= This_IP[15:8];
 627: pkt_data <= This_IP[7:0];
 628: pkt_data <= PC_IP[31:24];			// Destination PC IP Address
 629: pkt_data <= PC_IP[23:16];
 630: pkt_data <= PC_IP[15:8];
 631: pkt_data <= PC_IP[7:0];
 632: pkt_data <= PC_MAC[47:40];
 633: pkt_data <= PC_MAC[39:32];
 634: pkt_data <= PC_MAC[31:24];
 635: pkt_data <= PC_MAC[23:16];
 636: pkt_data <= PC_MAC[15:8];
 637: pkt_data <= PC_MAC[7:0];	
 638: pkt_data <= IP_lease[31:24];
 639: pkt_data <= IP_lease[23:16];
 640: pkt_data <= IP_lease[15:8];
 641: pkt_data <= IP_lease[7:0];
 642: pkt_data <= DHCP_IP[31:24];		// DHCP IP Address
 643: pkt_data <= DHCP_IP[23:16];
 644: pkt_data <= DHCP_IP[15:8];
 645: pkt_data <= DHCP_IP[7:0];	
 646: pkt_data <= DHCP_MAC[47:40];
 647: pkt_data <= DHCP_MAC[39:32];
 648: pkt_data <= DHCP_MAC[31:24];
 649: pkt_data <= DHCP_MAC[23:16];
 650: pkt_data <= DHCP_MAC[15:8];
 651: pkt_data <= DHCP_MAC[7:0];			// when changing add one and edit code 		
  // followed by data 
  // then CRC32 at 58

//----------  DHCP request renew ---------- 
// UDP/IP packet
// Ethernet preamble
 700: pkt_data <= 8'h55;
 701: pkt_data <= 8'h55;
 702: pkt_data <= 8'h55;
 703: pkt_data <= 8'h55;
 704: pkt_data <= 8'h55;
 705: pkt_data <= 8'h55;
 706: pkt_data <= 8'h55;
 707: pkt_data <= 8'hD5;
// Ethernet header
 708: pkt_data <= DHCP_MAC[47:40];				// DHCP Server MAC 
 709: pkt_data <= DHCP_MAC[39:32];
 710: pkt_data <= DHCP_MAC[31:24];
 711: pkt_data <= DHCP_MAC[23:16];
 712: pkt_data <= DHCP_MAC[15:8];
 713: pkt_data <= DHCP_MAC[7:0];
 714: pkt_data <= This_MAC[47:40];
 715: pkt_data <= This_MAC[39:32];
 716: pkt_data <= This_MAC[31:24];
 717: pkt_data <= This_MAC[23:16];
 718: pkt_data <= This_MAC[15:8];
 719: pkt_data <= This_MAC[7:0];
 720: pkt_data <= 8'h08;
 721: pkt_data <= 8'h00;
 // IP header 
 722: pkt_data <= 8'h45;						// Version
 723: pkt_data <= 8'h00;						// Type of service
 724: pkt_data <= UDP_DHCP_req_renew_length[15:8];	// length
 725: pkt_data <= UDP_DHCP_req_renew_length[7:0];		// 244 UDP data + 8 UDP header + 20 IP header
 726: pkt_data <= 8'h00;						// Identification
 727: pkt_data <= 8'h00;
 728: pkt_data <= 8'h00;						// Flags, Fragment
 729: pkt_data <= 8'h00;
 730: pkt_data <= 8'h80;						// Time to live
 731: pkt_data <= 8'h11;						// Protocol (0x11 = UDP)
 732: pkt_data <= DHCP_req_renew_checksum3[15:8];	// Checksum
 733: pkt_data <= DHCP_req_renew_checksum3[ 7:0];
 734: pkt_data <= This_IP[31:24];			// Source IP Address is IP address allocated to this board
 735: pkt_data <= This_IP[23:16];
 736: pkt_data <= This_IP[15:8];
 737: pkt_data <= This_IP[7:0];
 738: pkt_data <= DHCP_IP[31:24];			// DHCP Server IP Address
 739: pkt_data <= DHCP_IP[23:16];
 740: pkt_data <= DHCP_IP[15:8];
 741: pkt_data <= DHCP_IP[7:0];
// UDP header
 742: pkt_data <= 8'h00;						// source port = 68
 743: pkt_data <= 8'h44;
 744: pkt_data <= 8'h00;						// destination port = 67
 745: pkt_data <= 8'h43;
 746: pkt_data <= DHCP_req_renew_length[15:8];		// length
 747: pkt_data <= DHCP_req_renew_length[7:0];	    // total of 252 bytes ( 244 UDP data + 8 UDP header)
 748: pkt_data <= 8'h00;						// UDP Checksum (set to all zero which is valid for IP4 but not IP6)
 749: pkt_data <= 8'h00; 
 // DHCP Request
 750: pkt_data <= 8'h01;
 751: pkt_data <= 8'h01;
 752: pkt_data <= 8'h06;
 753: pkt_data <= 8'h00;
 // XID, SECS, FLAGS
 754: pkt_data <= 8'h00;
 755: pkt_data <= 8'h00;
 756: pkt_data <= 8'h00;
 757: pkt_data <= 8'h00;
 758: pkt_data <= 8'h00;
 759: pkt_data <= 8'h00;
 760: pkt_data <= 8'h00;
 761: pkt_data <= 8'h00; 
 // CIADDR
 762: pkt_data <= This_IP[31:24];			// CIADDR is IP address allocated to this board
 763: pkt_data <= This_IP[23:16];
 764: pkt_data <= This_IP[15:8];
 765: pkt_data <= This_IP[7:0];
 // 12 x 0x00 
 766: pkt_data <= This_MAC[47:40];
 767: pkt_data <= This_MAC[39:32];
 768: pkt_data <= This_MAC[31:24];
 769: pkt_data <= This_MAC[23:16];
 770: pkt_data <= This_MAC[15:8];
 771: pkt_data <= This_MAC[7:0]; 
 // 202 x 0x00
 772: pkt_data <= 8'h63;			// Magic Cookie
 773: pkt_data <= 8'h82;
 774: pkt_data <= 8'h53;
 775: pkt_data <= 8'h63;
 // Options
 776: pkt_data <= 8'h35;			// Options  NOTE: No IP requested nor Server IP as per rfc2131
 777: pkt_data <= 8'h01;
 778: pkt_data <= 8'h03;
 // End
 779: pkt_data <= 8'hFF;
 // followed by CRC32 at 58


  default: pkt_data <= 0;
endcase

// to calculate length ; 8 + (end - DHCP_start + 1) + nulls + 202 

assign DHCP_length = 16'd8 + (16'd367 - 16'd350 + 16'd1) + 16'd24 + 16'd202;  // 8 + 244
assign UDP_DHCP_length = DHCP_length + 16'd20;

assign DHCP_req_length = 16'd8 + (16'd479 - 16'd450 + 16'd1) + 16'd24 + 16'd202; // 8 + 256
assign UDP_DHCP_req_length = DHCP_req_length + 16'd20;

assign DHCP_req_renew_length = 16'd8 + (16'd779 - 16'd750 + 16'd1) + 16'd12 + 16'd202;  // 8 + 244
assign UDP_DHCP_req_renew_length = DHCP_req_renew_length + 16'd20;


always @ (negedge Tx_clock_2)	// clock at half speed since we read bytes but write nibbles
begin
case(state_Tx)

RESET:
   begin
	LED <= 1'b0;
	sync_Tx_CTL <= 1'b0;
	data_count <= 0;
	reset_CRC <= 0;
	rdaddress <= 0;
	ARP_sent <= 0;
	ping_sent <= 0;
	ping_check_temp <= 0;					// reset ping check sum calculation
	ck_count <= 0;
	zero_count <= 0;
	DHCP_discover_sent <= 0;
	DHCP_request_sent <= 0;
	METIS_discover_sent <= 0;
	DHCP_request_renew_sent <= 0;
	interframe <= 0;
	erase_done_ACK <= 0;
	send_more_ACK <= 0;
	IP_count <= 0;		
	
        if (IF_rst)
			state_Tx <= RESET;
		else begin
			if (run == 1'b0) begin
				sequence_number <= 0;  		// reset sequence numbers when not running.
				spec_seq_number <= 0;
			end 
			if (printf) begin
				rdaddress <= 600;
				state_Tx <= PRINTF;
			end 
			
			
			else if (DHCP_discover) begin
				rdaddress <= 300;				// point to start of DHCP table	
				state_Tx <= DHCP_DISCOVER;		
			end 
			else if (DHCP_request) begin
				rdaddress <= 400;
				state_Tx <= DHCP_REQUEST;
			end	
			else if (DHCP_request_renew) begin
				rdaddress <= 700;
				state_Tx <= DHCP_REQUEST_RENEW;
			end		 
			else if (Send_ARP) begin			// Pending ARP request
				rdaddress <= 100;					// point to start of ARP table	
				state_Tx <= ARP;
			end
			else if (ping_reply)begin
				rdaddress <= 200;					// point to ping checksum code
				state_Tx <= PING1;
			end
			else if (METIS_discovery && IP_valid) begin		// only respond if we have a valid IP address
				Discovery_IP <= PC_IP;								// reply to the requesting PC without changing IP etc for other commands
				Discovery_MAC <= PC_MAC;
				Discovery_Port <= Port;
				rdaddress <= 500;									// point to start of discovery reply table
				frame <= 8'h02;									// Discovery reply type
				METIS_discover_sent <= 1'b1;					// let Rx_MAC know Discovery has been responded to
				state_Tx <= METIS_DISCOVERY;
			end 
			else if (erase_done && IP_valid) begin			// only respond if we have a valid IP address
				erase_done_ACK <= 1'b1; 						// ACK the ASMI request
				rdaddress <= 500;									// point to start of discovery reply table
				frame <= 8'h03;									// erase_done reply type
				state_Tx <= METIS_DISCOVERY;
			end	
			else if (send_more && IP_valid) begin			// only respond if we have a valid IP address
				send_more_ACK <= 1'b1; 							// ACK the ASMI request
				rdaddress <= 500;									// point to start of discovery reply table
				frame <= 8'h04;									// send_more reply type
				state_Tx <= METIS_DISCOVERY;
			end				
			else if (PHY_Tx_rdused > 1023  && !Tx_reset && run) begin	// wait until we have at least 1024 bytes in Tx fifo
				rdaddress <= 0;														// and we have completed a Metis Discovery
				state_Tx <= UDP;
				//state_Tx <= RESET;													// ***** inhibit TX for testing
			end	
			else if (have_sp_data && wide_spectrum) begin					// Spectrum fifo has data available
				rdaddress <= 0;
				state_Tx <= SPECTRUM;
			end

			else	state_Tx <= RESET;
		end
   end

// start sending UDP/IP data   
UDP:
	begin
		end_point <= 8'h06;							// USB I&Q equivalent end point - EP6
		if (rdaddress != 58)							// keep sending until we reach the end of the fixed data 
		begin
			Tx_data <= pkt_data;
			sync_Tx_CTL <= 1'b1;						// enable write to PHY
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= UDP;
		end 
		else 
		// read the Tx fifo data 
		begin
			if (data_count != 1024) begin
				Tx_data <= PHY_Tx_data;  				
				data_count <= data_count + 1'b1;		// increment loop counter
				state_Tx <= UDP;
			end
			else begin
    			temp_CRC32 <= CRC32;						// grab the CRC data since it will change next clock pulse
				Tx_data <= CRC32[7:0];					// send CRC32 to PHY
				rdaddress <= 58; 							// point to end of CRC table 
              sequence_number <= sequence_number + 1'b1; 	// increment sequence number 
				state_Tx <= CRC;
			end 
		end  													// done, so now add the remainder of the CRC32 
		
	if (rdaddress == 57) Tx_fifo_rdreq <= 1'b1;			// enable read from Tx_fifo on next clock
	if (data_count == 1023) Tx_fifo_rdreq <= 1'b0;		// stop reading from Tx_fifo		
		
	if (rdaddress == 7)
		reset_CRC <= 1'b1; 								// start CRC32 generation
	else 
		reset_CRC <= 1'b0;
  end 	
  

METIS_DISCOVERY:
	begin
		if (rdaddress != 560) begin					// keep sending until we reach the end of the data 
			Tx_data <= pkt_data;
			sync_Tx_CTL <= 1'b1;							// enable write to PHY
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= METIS_DISCOVERY;
		end
		else if (zero_count < 50)begin				// send 50 x 0x01s *** tidy code, Hermes ID for PC code.
			Tx_data <= 8'h01;
			zero_count <= zero_count + 1'b1;
			state_Tx <= METIS_DISCOVERY;	
		end 
		else begin
    			temp_CRC32 <= CRC32;						// grab the CRC data since it will change next clock pulse
				Tx_data <= CRC32[7:0];					// send CRC32 to PHY
				rdaddress <= 58; 							// point to end of CRC table 
				state_Tx <= CRC;
		end  
	  if (rdaddress == 507)
		  reset_CRC <= 1'b1; 							// start CRC32 generation
	  else 
		  reset_CRC <= 1'b0;
	end

 
// respond to pending ARP request, just read straight through the table 	
ARP:
	begin
	LED <= 1'b1;
		if (rdaddress != 150) begin					
			sync_Tx_CTL <= 1'b1;							// enable write to PHY 
			Tx_data <= pkt_data;
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= ARP; 
		end
		else if (zero_count < 18)begin				// send 18 x 0x00s
			Tx_data <= 8'h00;
			zero_count <= zero_count + 1'b1;
			state_Tx <= ARP;	
		end 
		else begin
			ARP_sent <= 1'b1;								// set APR sent flag
			temp_CRC32 <= CRC32;							// grab the CRC data since it will change next clock pulse
			Tx_data <= CRC32[7:0];						// send CRC32 to PHY
			rdaddress <= 58; 								// point to end of CRC table
			state_Tx <= CRC;
		end
		
	if (rdaddress == 107)
		reset_CRC <= 1'b1; 								// start CRC32 generation
	else 
		reset_CRC <= 1'b0;
	
	end

// Calculate ping checksum. Ping data is in bytes, convert to 16 bits then 
// sum, apply one's complement then complement 	
PING1:
	begin
		if (ck_count != (Length - 24)) begin  		// add all the ping data as 16 bits, 
			ping_check_temp <= ping_check_temp + {16'b0,ping_data[ck_count], ping_data[ck_count + 1]};
			ck_count <= ck_count + 8'd2;				// get next two bytes
			state_Tx <= PING1;	
		end
		else if (ping_check_temp >> 16 != 0) begin   // do one's complement 
			ping_check_temp <=  ((ping_check_temp & 32'h0000FFFF) + (ping_check_temp >> 16)); 
			state_Tx <= PING1;
		end		
		else begin					// complement and move to next state
			ping_check_sum <= ~ping_check_temp[15:0]; 
			state_Tx <= PING2;					   
		end
	end	
	
// respond to ping
PING2:	
	begin
		if (rdaddress != 246)						// keep sending until we reach the end of the fixed data 
		begin
			Tx_data <= pkt_data;
			sync_Tx_CTL <= 1'b1;						// enable write to PHY
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= PING2;
		end 
		else if (data_count != (Length - 24)) begin	// send contents of ping_data in bytes
			Tx_data <=  ping_data[data_count];	
			data_count <= data_count + 1'd1;		// increment loop counter
			state_Tx <= PING2;
		end
		else begin
			ping_sent <= 1'b1;						// set ping sent flag
			temp_CRC32 <= CRC32;						// grab the CRC data since it will change next clock pulse
			Tx_data <= CRC32[7:0];					// send CRC32 to PHY
			rdaddress <= 58; 							// point to end of CRC table
			state_Tx <= CRC;
		end		
		
	if (rdaddress == 207)
		reset_CRC <= 1'b1; 							// start CRC32 generation
	else 
		reset_CRC <= 1'b0;			
	end 

// send DHCP discover request
DHCP_DISCOVER:
	begin
		if (rdaddress < 354) begin					
			sync_Tx_CTL <= 1'b1;						// enable write to PHY 
			Tx_data <= pkt_data;
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= DHCP_DISCOVER; 
		end
		else if (zero_count < 24)begin				// send 24 x 0x00s
				Tx_data <= 8'h00;
				zero_count <= zero_count + 1'b1;
				state_Tx <= DHCP_DISCOVER;	
		end
		else if (rdaddress < 360) begin					
				Tx_data <= pkt_data;
				rdaddress <= rdaddress + 1'b1;
				state_Tx <= DHCP_DISCOVER;
		end
		else if (zero_count < 226)begin				// send 202 x 0x00s
				Tx_data <= 8'h00;
				zero_count <= zero_count + 1'b1;
				state_Tx <= DHCP_DISCOVER;	
		end 
		else if (rdaddress < 368) begin				// send the balance of the data				
				Tx_data <= pkt_data;
				rdaddress <= rdaddress + 1'b1;
				state_Tx <= DHCP_DISCOVER;
		end
		else begin
			temp_CRC32 <= CRC32;							// grab the CRC data since it will change next clock pulse
			Tx_data <= CRC32[7:0];						// send CRC32 to PHY
			rdaddress <= 58; 								// point to end of CRC table
			DHCP_discover_sent <= 1'b1;				// indicate we have sent the request
			state_Tx <= CRC;
		end
		
	if (rdaddress == 307)
		reset_CRC <= 1'b1; 								// start CRC32 generation
	else 
		reset_CRC <= 1'b0;
		
	end
// send DHCP request	
DHCP_REQUEST:
	begin
		if (rdaddress < 454) begin					
			sync_Tx_CTL <= 1'b1;							// enable write to PHY 
			Tx_data <= pkt_data;
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= DHCP_REQUEST; 
		end
		else if (zero_count < 24)begin				// send 34 x 0x00s
				Tx_data <= 8'h00;
				zero_count <= zero_count + 1'b1;
				state_Tx <= DHCP_REQUEST;	
		end									
		else if (rdaddress < 460) begin					
				Tx_data <= pkt_data;
				rdaddress <= rdaddress + 1'b1;
				state_Tx <= DHCP_REQUEST;
		end
		else if (zero_count < 226)begin				// send 202 x 0x00s
				Tx_data <= 8'h00;
				zero_count <= zero_count + 1'b1;
				state_Tx <= DHCP_REQUEST;	
		end 
		else if (rdaddress < 480) begin				// send the balance of the data				
				Tx_data <= pkt_data;
				rdaddress <= rdaddress + 1'b1;
				state_Tx <= DHCP_REQUEST;
		end
		else begin
			temp_CRC32 <= CRC32;							// grab the CRC data since it will change next clock pulse
			Tx_data <= CRC32[7:0];						// send CRC32 to PHY
			rdaddress <= 58; 								// point to end of CRC table
			DHCP_request_sent <= 1'b1;					// indicate we have sent the request
			state_Tx <= CRC;
		end
		
		if (rdaddress == 407)
			reset_CRC <= 1'b1; 							// start CRC32 generation
		else 
			reset_CRC <= 1'b0;
		
	end
	
//
DHCP_REQUEST_RENEW:
	begin
		if (rdaddress < 766) begin					
			sync_Tx_CTL <= 1'b1;							// enable write to PHY 
			Tx_data <= pkt_data;
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= DHCP_REQUEST_RENEW; 
		end
		else if (zero_count < 12)begin				// send 12 x 0x00s
				Tx_data <= 8'h00;
				zero_count <= zero_count + 1'b1;
				state_Tx <= DHCP_REQUEST_RENEW;	
		end									
		else if (rdaddress < 772) begin					
				Tx_data <= pkt_data;
				rdaddress <= rdaddress + 1'b1;
				state_Tx <= DHCP_REQUEST_RENEW;
		end
		else if (zero_count < 214)begin				// send 202 x 0x00s
				Tx_data <= 8'h00;
				zero_count <= zero_count + 1'b1;
				state_Tx <= DHCP_REQUEST_RENEW;	
		end 
		else if (rdaddress < 780) begin				// send the balance of the data				
				Tx_data <= pkt_data;
				rdaddress <= rdaddress + 1'b1;
				state_Tx <= DHCP_REQUEST_RENEW;
		end
		else begin
			temp_CRC32 <= CRC32;							// grab the CRC data since it will change next clock pulse
			Tx_data <= CRC32[7:0];						// send CRC32 to PHY
			rdaddress <= 58; 								// point to end of CRC table
			DHCP_request_renew_sent <= 1'b1;			// indicate we have sent the request
			state_Tx <= CRC;
		end
		
		if (rdaddress == 707)
			reset_CRC <= 1'b1; 							// start CRC32 generation
		else 
			reset_CRC <= 1'b0;
		
	end
	
	
	
// for debug - send data as raw Ethernet broadcast	
PRINTF:
	begin
		if (rdaddress != 652)							// end of table + 1  i.e. keep sending until we reach the end of the data 
		begin
			Tx_data <= pkt_data;
			sync_Tx_CTL <= 1'b1;							// enable write to PHY
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= PRINTF;
		end
		// now send 60 bytes of 0x00 
		else if (data_count != 60) begin
			Tx_data <= 0;  				
			data_count <= data_count + 1'b1;			// increment loop counter
			state_Tx <= PRINTF;
		end
		else begin
    			temp_CRC32 <= CRC32;						// grab the CRC data since it will change next clock pulse
				Tx_data <= CRC32[7:0];					// send CRC32 to PHY
				rdaddress <= 58; 							// point to end of CRC table 
				state_Tx <= CRC;
		end  
	  if (rdaddress == 607)
		  reset_CRC <= 1'b1; 								// start CRC32 generation
	  else 
		  reset_CRC <= 1'b0;
	end	

// send raw ADC data from Mercury. Spectrum data has its own independant sequence number.
SPECTRUM:
	begin
		end_point <= 8'h04;							// USB Spectrum equivalent end point - EP4
		if (rdaddress != 58)							// keep sending until we reach the end of the fixed data 
		begin 											// but skip sequence number
			Tx_data <= pkt_data;
			sync_Tx_CTL <= 1'b1;						// enable write to PHY
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= SPECTRUM;
		end 
		else 
		// read the Tx fifo data 
		begin
			if (sp_data_count != 1024) begin
				Tx_data <= sp_fifo_rddata;  					// read data from SP_fifo	
				sp_data_count <= sp_data_count + 1'b1;		// increment loop counter
				state_Tx <= SPECTRUM;
			end
			else begin
				sp_data_count <= 0;						// reset data counter for next time 
    			temp_CRC32 <= CRC32;						// grab the CRC data since it will change next clock pulse
				Tx_data <= CRC32[7:0];					// send CRC32 to PHY
				rdaddress <= 58; 							// point to end of CRC table
				spec_seq_number <= spec_seq_number + 1'b1; // increment spectrum sequence number 
				state_Tx <= CRC;
			end 
		end  													// done, so now add the remainder of the CRC32 
		
	if (rdaddress == 57) sp_fifo_rdreq <= 1'b1;				// enable read from SP_fifo on next clock
	if (sp_data_count == 1023) sp_fifo_rdreq <= 1'b0;		// stop reading from SP_fifo		
		
	if (rdaddress == 7)
		reset_CRC <= 1'b1; 								// start CRC32 generation
	else 
		reset_CRC <= 1'b0;
  end 	
  
		
  
  
	
// add remainder of CRC32
CRC:
	begin
		if (rdaddress != 61) begin
			Tx_data <= pkt_data;
			rdaddress <= rdaddress + 1'b1;
			state_Tx <= CRC;     
		end
		else begin
			sync_Tx_CTL <= 1'b0;									// disable PHY write
			if (interframe == 10) begin						// delay between frames should be 960/96nS min
				state_Tx <= RESET; 								// send complete, loop back to start
			end 	
			else interframe <= interframe + 1'b1;
		end
	end	

endcase
end     



//------------------------------
//   802.3 CRC32 Calculation
//-------------------------------

CRC32 CRC32_inst(.rst(reset_CRC),.clk(Tx_clock_2), .data(Tx_data), .crc(CRC32)); 



//-----------------------------------------------------------
//   Send data to PHY
//-----------------------------------------------------------


// Data to send is in Tx_data in bytes. 
// For 100T, when sync_Tx_CTL is true we alternate sending low and high nibbles 

reg [4:0]PHY_state;
reg sync_Tx_CTL;
reg [3:0] sync_TD;


always @ (negedge Tx_clock)  
begin
case (PHY_state)
// send low nibble
0:	begin 
		if (sync_Tx_CTL) begin
			sync_TD <= Tx_data[3:0];
			PHY_state <= 1'b1;
		end	
	else PHY_state <= 0;
	end
// now send high nibble
1:	begin
	sync_TD <= Tx_data[7:4];
	PHY_state <= 0;
	end

endcase
end

// sync data to PHY on Tx clock, clock PHY on ~Tx_clock so we clock in middle of data

always @ (posedge Tx_clock)
begin
	 TD <= sync_TD;
	 Tx_CTL <= sync_Tx_CTL; 
end 




reg [3:0]TD;
//wire [3:0]high_data;		// data to send on positive edge of Tx_clock
//wire [3:0]low_data;		// data to send on negative edge of Tx_clock
reg Tx_CTL;
//
//always @ (posedge Tx_clock)
//	 Tx_CTL <= sync_Tx_CTL; 
//
//// instantiate ALTDDIO_OUT for PHY_Tx  
//// PHY_Tx sends datain_h on the positive edge of outclock and datain_l on the negeative edge.
//// Hence for 100T only send data on the positive edge
//
//assign high_data = speed_100T ? sync_TD : Tx_data[3:0];
//assign low_data  = speed_100T ? 4'b0    : Tx_data[7:4];
//
//PHY_Tx PHY_Tx_inst(.datain_h(high_data), .datain_l(low_data), .outclock(Tx_clock), .dataout(TD));

endmodule


/*
// perhaps calculate check sum this way - example is for UPD/IP

reg [31:0]check_sum;
reg [15:0]IP_check_sum;

// assume this is part of an existing state machine

case (state)
0:	begin	
	check_sum <= 0;
	rdaddress <= 22;		// starting address from where we want to calculate the check sum
	state<= 1;
	end
1:	begin
	if (rdaddress < 42)begin
		temp <= pkt_data;
		rdaddress <= rdaddress + 1'b1;
		state <= 2;
	end
	else state <= 3; 
2:	begin 
	check_sum = check_sum + {temp,pkt_data};
	rdaddress <= rdaddress + 1'b1;
	state <= 1;
	end
3:  begin
	if (check_sum >> 16 != 0) begin   // do one's complement 
			check_sum <=  ((check_sum & 32'h0000FFFF) + (check_sum >> 16)); 
			state <= 3;
	end
	else begin					// complement and move to next state
			IP_check_sum <= ~check_sum[15:0];
			state <= next;					   
	end

*/