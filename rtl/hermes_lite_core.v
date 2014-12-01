//
//  Hermes Lite
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

// (C) Phil Harman VK6APH, Kirk Weedman KD7IRS  2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 
// (C) Steve Haynal KF7O 2014


// This is a port of the Hermes project from www.openhpsdr.org to work with
// the Hermes-Lite hardware described at http://github.com/softerhardware/Hermes-Lite.
// It was forked from Hermes V2.5.

module hermes_lite_core(

	input AD9866clk,

	input IF_clk,
	input ad9866spiclk,
	input rstclk,
	input EEPROM_clock,
	input IF_locked,

 	input extreset,
	output [7:0] leds, 

	// AD9866
	output [5:0] ad9866_pga,
	
	inout [11:0] ad9866_adio,
	//input [5:0] ad9866_rx,
	//output [5:0] ad9866_tx,
	
	output ad9866_rxen,
	//input ad9866_rxsync,
	
	output ad9866_rxclk,
	
	output ad9866_txen,
	//output ad9866_txsync,

	output ad9866_txclk,
	//output ad9866_txquiet,

	output ad9866_sclk,
    output ad9866_sdio,
    input  ad9866_sdo,
    output ad9866_sen_n,

    output ad9866_rst_n,
 
    // MII Ethernet PHY
  	output [3:0]PHY_TX,
  	output PHY_TX_EN,              //PHY Tx enable
  	input  PHY_TX_CLOCK,           //PHY Tx data clock
  	input  [3:0]PHY_RX,     
  	input  RX_DV,                  //PHY has data flag
  	input  PHY_RX_CLOCK,           //PHY Rx data clock
  	output PHY_RESET_N,  
    inout PHY_MDIO,
    output PHY_MDC

);

// PARAMETERS

// Ethernet Interface
parameter MAC;
parameter IP;

// ADC Oscillator
parameter CLK_FREQ;

// B57 = 2^57.   M2 = B57/OSC
localparam M2 = (CLK_FREQ == 61440000) ? 32'd2345624805 : 32'd1954687338;
// M3 = M2 / 2, used to round the result
localparam M3 = (CLK_FREQ == 61440000) ? 32'd1172812402 : 32'd977343669;

// Decimation rate
localparam RATE48 =  (CLK_FREQ == 61440000) ? 6'd20 : 6'd24;
localparam RATE96 =  (CLK_FREQ == 61440000) ? 6'd10 : 6'd12;
localparam RATE192 = (CLK_FREQ == 61440000) ? 6'd05 : 6'd06;
localparam RATE384 = (CLK_FREQ == 61440000) ? 6'd03 : 6'd03; // Doesn't work for 61.44 MHz oscillator

// Number of Receivers
parameter NR; // number of receivers to implement

wire NCONFIG;

wire FPGA_PTT;
wire RAND;
assign RAND = 0;

assign NCONFIG = IP_write_done || reset_FPGA;

parameter M_TPD   = 4;
parameter IF_TPD  = 2;

parameter  Hermes_serialno = 8'd25;		// Serial number of this version
localparam Penny_serialno = 8'd00;		// Use same value as equ1valent Penny code 
localparam Merc_serialno = 8'd00;		// Use same value as equivalent Mercury code

localparam RX_FIFO_SZ  = 4096; 			// 16 by 4096 deep RX FIFO
localparam TX_FIFO_SZ  = 1024; 			// 16 by 1024 deep TX FIFO  
localparam SP_FIFO_SZ = 2048;			// 16 by 8192 deep SP FIFO, was 16384 but wouldn't fit

localparam read_reg_address = 5'h10; 	// PHY register to read from - gives connect speed and fully duplex	


//--------------------------------------------------------------
// Reset Lines - C122_rst, IF_rst
//--------------------------------------------------------------

wire  IF_rst;
	
assign IF_rst 	 = (!IF_locked || reset);		// hold code in reset until PLLs are locked & PHY operational

assign PHY_RESET_N = 1'b1;  						// Allow PYH to run for now

// transfer IF_rst to 122.88MHz clock domain to generate C122_rst
cdc_sync #(1)
	reset_C122 (.siga(IF_rst), .rstb(IF_rst), .clkb(C122_clk), .sigb(C122_rst)); // 122.88MHz clock domain reset
	
//---------------------------------------------------------
//		CLOCKS
//---------------------------------------------------------

//wire C122_clk = LTC2208_122MHz;
wire C122_clk; //  = AD9866clk;
wire _122MHz;  // = AD9866clk;

wire CLRCLK;

wire C122_cbclk, C122_cbrise, C122_cbfall;
Hermes_clk_lrclk_gen #(.CLK_FREQ(CLK_FREQ)) clrgen (.reset(C122_rst), .CLK_IN(C122_clk), .BCLK(C122_cbclk),
                             .Brise(C122_cbrise), .Bfall(C122_cbfall), .LRCLK(CLRCLK));


assign C122_clk = AD9866clk;
assign _122MHz = AD9866clk;


//----------------------------PHY Clocks-------------------

wire Tx_clock;
//wire Tx_clock_2;
wire C125_locked; 										// high when PLL locked
wire PHY_data_clock;
wire PHY_speed;											// 0 = 100T, 1 = 1000T

reg Tx_clock_2;
always @ (posedge PHY_TX_CLOCK) Tx_clock_2 <= ~Tx_clock_2;

//ethclocks_cv PLL_clocks_inst( .inclk0(PHY_TX_CLOCK), .c0(Tx_clock_2), .c1(EEPROM_clock));
assign Tx_clock = PHY_TX_CLOCK;


assign PHY_speed = 1'b0;		// high for 1000T, low for 100T; force 100T for now


// generate PHY_RX_CLOCK/2 for 100T 
reg PHY_RX_CLOCK_2;
always @ (posedge PHY_RX_CLOCK) PHY_RX_CLOCK_2 <= ~PHY_RX_CLOCK_2; 

// force 100T for now 
assign PHY_data_clock = PHY_RX_CLOCK_2;


//------------------------------------------------------------
//  Reset and initialisation
//------------------------------------------------------------

/* 
	Hold the code in reset whilst we do the following:
	
	Get the boards MAC address from the EEPROM.
	
	Then setup the PHY registers and read from the PHY until it indicates it has 
	negotiated a speed.  Read connection speed and that we are running full duplex.
	
	LED0 incates PHY status - fast flash if no Ethernet connection, slow flash if 100T and on if 1000T
	
	Then wait a second (for the network to stabilise) then  attempt to obtain an IP address using DHCP
	- supplied address is in YIADDR.  If the DHCP request either times out, or results in a NAK, retry four 
	additional times with a 2 second delay between each retry.
	
	If after the retries a DHCP assigned IP address is not available use an APIPA IP address or an assigned one
	from Flash.
	
	Inhibit replying to a Metis Discovery request until an IP address has been applied.
	
	LED6 indicates the result of DHCP - on if ACK, slow flash if NAK, fast flash if time out and 
	long then short flash if static IP
	
	Once an IP address has been assigned set IP_valid flag. When set enables a response to a Discovery request.
	
	Wait for a Metis discovery frame - once received enable HPSDR data to PC.
	
	Enable rest of code.
	
*/

reg reset;
reg [4:0]start_up;
reg [47:0]This_MAC; 			// holds the MAC address of this Metis board
reg read_MAC; 
wire MAC_ready;
reg DHCP_start;
reg [24:0]delay;
reg duplex;						// set when we are connected full duplex
reg speed_100T;				// set when we are connected at 100MHz
reg speed_1000T;				// set when we are connected at 1GHz
reg Tx_reset;					// when set prevents HPSDR UDP/IP Tx data being sent
reg [2:0]DHCP_retries;		// DHCP retry counter
reg IP_valid;					// set when Metis has a valid IP address assigned by DHCP or APIPA
reg Assigned_IP_valid;		// set if IP address assigned by PC is not 0.0.0.0. or 255.255.255.255
reg use_IPIPA;					// set when no DHCP or assigned IP available so use APIAP
reg read_IP_address;			// set when we wish to read IP address from EEPROM


always @ (posedge Tx_clock_2)
begin
	case (start_up)
	// get the MAC address for this board
0:	begin 
		IP_valid <= 1'b0;							// clear IP valid flag
		Assigned_IP_valid <= 1'b0;				// clear IP in flash memory valid
		reset <= 1'b1;
		Tx_reset <= 1'b1;							// prevent I&Q data Tx until all initialised 
		read_MAC <= 1'b1;
		use_IPIPA <= 0;							// clear IPIPA flag
		start_up <= start_up + 1'b1;
	end
	// wait until we have read the EEPROM then the IP address
1:  begin
		if (MAC_ready) begin 					// MAC_ready goes high when EEPROM read
			read_MAC <= 0;
			read_IP_address <= 1'b1;						// set read IP flag
			start_up <= start_up + 1'b1;
		end
		else start_up <= 1'b1;
	end
	// read the IP address from EEPROM then set up the PHY
2:	begin
		if (IP_ready) begin
			read_IP_address <= 0;
    		write_PHY <= 1'b1;					// set write to PHY flag
			start_up <= start_up + 1'b1;
		end
		else start_up <= 2;    
    end			
	// check the IP address read from the flash memory is valid. Set up the PHY MDIO registers
3: begin
	   if (AssignIP != 0 && AssignIP != 32'hFF_FF_FF_FF)
			Assigned_IP_valid <= 1'b1;	
	   if (write_done) begin
			write_PHY <= 0;						// clear write PHY flag so it does not run again
			duplex <= 0;							// clear duplex and speed flags
			speed_100T <= 0;
			speed_1000T <= 0; 
			read_PHY <= 1'b1;						// set read from PHY flag
			start_up <= start_up + 1'b1;
		end 
		else start_up <= 3;						// loop here till write is done
	end 
	
	// loop reading PHY Register 31 bits [3],[5] & [6] to determine if final connection is full duplex at 100T or 1000T.
	// Set speed and duplex bits.
	// If an IP address has been assigned (i.e. != 0) then continue else	
	// once connected delay 1 second before trying DHCP to give network time to stabilise.
4: begin
		if (read_done  && register_data[0]) begin
			duplex <= register_data[2];			// get connection status and speed
			speed_100T  <= register_data[1];
			//speed_1000T <= register_data[6];
			speed_1000T <= 0;
			read_PHY <= 0;								// clear read PHY flag so it does not run again	
			reset <= 0;	
			if (duplex) begin							// loop here is not fully duplex network connection
				// if an IP address has been assigned then skip DHCP etc
				if (Assigned_IP_valid) start_up <= 6;
				// allow rest of code to run now so we can get IP address. If 						
				else if (delay == 12500000) begin	// delay 1 second so that PHY is ready for DHCP transaction
					DHCP_start <= 1'b1;					// start DHCP process
					if (time_out)							// loop until the DHCP module has cleared its time_out flag
						start_up <= 4;
					else begin
						delay <= 0;							// reset delay for DHCP retries
						start_up <= start_up + 1'b1;
					end 
				end 
				else delay <= delay + 1'b1;
			end 
		end 
		else start_up <= 4;								// keep reading Register 1 until we have a valid speed and full duplex		
   end 

	// get an IP address from the DHCP server, move to next state if successful, retry 3 times if NAK or time out.		
5:  begin 
		DHCP_start <= 0;
		if (DHCP_ACK) 										// have DHCP assigned IP address so continue
			start_up <= start_up + 1'b1;
		else if (DHCP_NAK || time_out) begin		// try again 3 more times with 1 second delay between attempts
			if (DHCP_retries == 3) begin				// no more DHCP retries so use IPIPA address and  continue
				use_IPIPA <= 1'b1;
				start_up <= start_up + 1'b1;
			end
			else begin
				DHCP_retries <= DHCP_retries + 1'b1;	// try DHCP again
				start_up <= 4;
			end	
		end		
		else start_up <= 5;
	end
	
	// Have a valid IP address and a full duplex PHY connection so enable Tx code 
6:  begin
	IP_valid <= 1'b1;					// we now have a valid IP address so can respond to Discovery requests etc
	Tx_reset <= 0;						// release reset so UDP/IP Tx code can run
	start_up <= start_up + 1'b1;						
	read_PHY <= 1'b1;					// set read from PHY flag
	end
	// loop checking we still have a Network connection by reading speed from PHY registers - restart if network connection lost
7:	begin
		if (read_done) begin 
			read_PHY <= 0;
			if (register_data[0] || ~register_data[1])
				start_up <= 6;								// network connection OK
			else start_up <= 0;							// lost network connection so re-start
		end 
	end
	default: start_up <= 0;
    endcase
end 

//----------------------------------------------------------------------------------
// read and write to the EEPROM	(NOTE: Max clock frequency is 20MHz)
//----------------------------------------------------------------------------------
wire IP_ready;
wire write_IP;
				
//EEPROM EEPROM_inst(.clock(EEPROM_clock), .read_MAC(read_MAC), .read_IP(read_IP_address), .write_IP(write_IP), 
//				   .IP_to_write(IP_to_write), .CS(CS), .SCK(SCK), .SI(SI), .SO(SO), .This_MAC(This_MAC),
//				   .This_IP(AssignIP), .MAC_ready(MAC_ready), .IP_ready(IP_ready), .IP_write_done(IP_write_done));				
	
// Emulate EEPROM

assign This_MAC = MAC;
//assign AssignIP = {8'd192,8'd168,8'd2,8'd31};
assign AssignIP = IP;
assign MAC_ready = 1'b1;
assign IP_ready = 1'b1;
assign IP_write_done = 1'b1;

					
//------------------------------------------------------------------------------------
//  If DHCP provides an IP address for Metis use that else use a random APIPA address
//------------------------------------------------------------------------------------

// Use an APIPA address of 169.254.(last two bytes of the MAC address)

wire [31:0] This_IP;
wire [31:0]AssignIP;			// IP address read from EEPROM

assign This_IP =  Assigned_IP_valid ? AssignIP : 
				              use_IPIPA ? {8'd169, 8'd254, This_MAC[15:0]} : YIADDR;

//----------------------------------------------------------------------------------
// Read/Write the  PHY MDIO registers (NOTE: Max clock frequency is 2.5MHz)
//----------------------------------------------------------------------------------
wire write_done; 
reg write_PHY;
reg read_PHY;
wire PHY_clock;
wire read_done;
wire [15:0]register_data; 
wire PHY_MDIO_clk;
assign PHY_MDIO_clk = EEPROM_clock;

MDIO MDIO_inst(.clk(PHY_MDIO_clk), .write_PHY(write_PHY), .write_done(write_done), .read_PHY(read_PHY),
	  .clock(PHY_MDC), .MDIO_inout(PHY_MDIO), .read_done(read_done),
	  .read_reg_address(read_reg_address), .register_data(register_data),.speed(PHY_speed));

//----------------------------------------------------------------------------------
//  Renew the DHCP supplied IP address at half the lease period
//----------------------------------------------------------------------------------

/*
	Request a DHCP IP address at IP_lease/2 seconds if we have a valid DHCP assigned IP address.
	The IP_lease is obtained from the DHCP server and returned during the DHCP ACK.
	This is the number of seconds that the IP lease is valid. 
	
	Divide this value by 2 then multiply by the clock rate to give the delay time.
	
	If an IP_lease time of zero is received then the lease time is set to 24 days.
*/

wire [51:0]lease_time;
assign lease_time = (IP_lease == 0) ?  52'h7735_8C8C_A6C0 : (IP_lease >> 1) * 12500000; // 24 days if no lease time given
// assign lease_time = (IP_lease == 0) ? 52'h7735_8C8C_A6C0  : (52'd4 * 52'd12500000);  // every 4 seconds for testing


reg [24:0]IP_delay;
reg DHCP_renew;
reg [3:0]renew_DHCP_retries;
reg [51:0]renew_counter;
reg [24:0]renew_timer; 
reg [2:0]renew;
reg printf;
reg DHCP_request_renew;
reg second_time;						// set if can't get a DHCP IP address after two tries.
reg DHCP_discover_broadcast;    // last ditch attempt so do a discovery broadcast

always @(posedge Tx_clock_2)
begin 
case (renew)

0:	begin 
	renew_timer <= 0;
		if (DHCP_ACK) begin							 // only run if we have a  valid DHCP supplied IP address
			if (renew_counter == lease_time )begin
				renew_counter <= 0;
				renew <= renew + 1'b1;
			end
			else renew_counter <= renew_counter + 1'b1;
		end 
		else renew <= 0;
	end 
// Renew DHCP IP address
1:	begin
		if (second_time) 
			renew <= 4;
		else begin 
			DHCP_request_renew <= 1'b1;
			renew <= renew + 1'b1;
		end 
	end

// delay so the request is seen then return
2:	renew <= renew + 1'b1;

 
// get an IP address from the DHCP server, move to next state if successful, if not reset lease timer to 1/4 previous value
3: begin
	DHCP_request_renew <= 0;
		if (renew_timer != 2 * 12500000) begin  // delay for 2 seconds before we look for ACK, NAK or time_out
			renew_timer <= renew_timer + 1'b1;
			renew <= 3;
		end 		
		else begin
			if (DHCP_NAK || time_out) begin		// did not renew so set timer to lease_time/4
				second_time <= 1'b1;
				renew_counter = (lease_time - lease_time >> 4);  // i.e. 0.75 * lease_time
				renew <= 0;
			end
			else begin	
				renew_counter <= 0; 					// did renew so reset counter and continue.
				renew <= 0;
			end 
		end
	end 

// have not got an IP address the second time we tryed so use a broadcast and loop here
4:	begin 
	DHCP_discover_broadcast <= 1'b1;				// do a DHCP discovery
	renew <= renew + 1'b1;
	end 
	
// if we get a DHCP_ACK then continue else give up 
5:	begin
	DHCP_discover_broadcast <= 0;
		if (renew_timer != 2 * 12500000) begin  // delay for 2 seconds before we look for ACK, NAK or time_out
			renew_timer <= renew_timer + 1'b1;
			renew <= 5;
		end 
		else if (DHCP_NAK || time_out) 			// did not renew so give up
				renew <= 5;
		else begin 										// did renew so continue
			second_time <= 0;
			renew <= 0;
		end 
	end 	
default: renew <= 0;
endcase
end 

//----------------------------------------------------------------------------------
//  See if we can get an IP address using DHCP
//----------------------------------------------------------------------------------

wire time_out;
wire DHCP_request;

DHCP DHCP_inst(Tx_clock_2, (DHCP_start || DHCP_discover_broadcast), DHCP_renew, DHCP_discover , DHCP_offer, time_out, DHCP_request, DHCP_ACK);


//-----------------------------------------------------
//   Rx_MAC - PHY Receive Interface  
//-----------------------------------------------------

wire [7:0]ping_data[0:59];
wire [15:0]Port;
wire [15:0]Discovery_Port;		// PC port doing a Discovery
wire broadcast;
wire ARP_request;
wire ping_request;
wire Rx_enable;
wire this_MAC;  					// set when packet addressed to this MAC
wire DHCP_offer; 					// set when we get a valid DHCP_offer
wire [31:0]YIADDR;				// DHCP supplied IP address for this board
wire [31:0]DHCP_IP;  			// IP address of DHCP server offering IP address 
wire DHCP_ACK, DHCP_NAK;
wire [31:0]PC_IP;					// IP address of the PC we are connecting to
wire [31:0]Discovery_IP;		// IP address of the PC doing a Discovery
wire [47:0]PC_MAC;				// MAC address of the PC we are connecting to
wire [47:0]Discovery_MAC;		// MAC address of the PC doing a Discovery
wire [31:0]Use_IP;				// Assigned IP address, if zero then use DHCP
wire METIS_discovery;			// pulse high when Metis_discovery received
wire [47:0]ARP_PC_MAC; 			// MAC address of PC requesting ARP
wire [31:0]ARP_PC_IP;			// IP address of PC requesting ARP
wire [47:0]Ping_PC_MAC; 		// MAC address of PC requesting ping
wire [31:0]Ping_PC_IP;			// IP address of PC requesting ping
wire [15:0]Length;				// Lenght of frame - used by ping
wire data_match;					// for debug use 
wire PHY_100T_state;				// used as system clock at 100T
wire [7:0] Rx_fifo_data;		// byte from PHY to send to Rx_fifo
wire rs232_write_strobe;
wire seq_error;					// set when we receive a sequence error
wire run;							// set to send data to PC
wire wide_spectrum;				// set to send wide spectrum data
wire [31:0]IP_lease;				// holds IP lease in seconds from DHCP ACK packet
wire [47:0]DHCP_MAC;				// MAC address of DHCP server 
wire erase;							// set when we receive an erase EPCS16 command
wire erase_ACK;					// set when ASMI interface acks the erase command
wire [31:0]num_blocks;			// number of 256 byte blocks to save in EPCS16
wire EPCS_FIFO_enable;			// EPCS fifo write enable
wire IP_write_done;
wire [31:0] IP_to_write;


Rx_MAC Rx_MAC_inst (.PHY_RX_CLOCK(PHY_RX_CLOCK), .PHY_data_clock(PHY_data_clock),.RX_DV(RX_DV), .PHY_RX(PHY_RX),
			        .broadcast(broadcast), .ARP_request(ARP_request), .ping_request(ping_request),  
			        .Rx_enable(Rx_enable), .this_MAC(this_MAC), .Rx_fifo_data(Rx_fifo_data), .ping_data(ping_data),
			        .DHCP_offer(DHCP_offer),
			        .This_MAC(This_MAC), .YIADDR(YIADDR), .DHCP_ACK(DHCP_ACK), .DHCP_NAK(DHCP_NAK),
			        .METIS_discovery(METIS_discovery), .METIS_discover_sent(METIS_discover_sent), .PC_IP(PC_IP), .PC_MAC(PC_MAC),
			        .This_IP(This_IP), .Length(Length), .PHY_100T_state(PHY_100T_state),
			        .ARP_PC_MAC(ARP_PC_MAC), .ARP_PC_IP(ARP_PC_IP), .Ping_PC_MAC(Ping_PC_MAC), 
			        .Ping_PC_IP(Ping_PC_IP), .Port(Port), .seq_error(seq_error), .data_match(data_match),
			        .run(run), .IP_lease(IP_lease), .DHCP_IP(DHCP_IP), .DHCP_MAC(DHCP_MAC),
			        .erase(erase), .erase_ACK(erase_ACK), .num_blocks(num_blocks), .EPCS_FIFO_enable(EPCS_FIFO_enable),
			        .wide_spectrum(wide_spectrum), .IP_write_done(IP_write_done), .write_IP(write_IP),
					  .IP_to_write(IP_to_write) 
			        );
			        


//-----------------------------------------------------
//   Tx_MAC - PHY Transmit Interface  
//-----------------------------------------------------

wire [10:0] PHY_Tx_rdused;  
wire LED;
wire Tx_fifo_rdreq;
wire ARP_sent;
wire  DHCP_discover;
reg  [7:0] RS232_data;
reg  RS232_Tx;
wire DHCP_request_sent;
wire DHCP_discover_sent;
wire METIS_discover_sent;
wire Tx_CTL;
wire [3:0]TD;


Tx_MAC Tx_MAC_inst (.Tx_clock(Tx_clock), .Tx_clock_2(Tx_clock_2), .IF_rst(IF_rst),
					.Send_ARP(Send_ARP),.ping_reply(ping_reply),.PHY_Tx_data(PHY_Tx_data),
					.PHY_Tx_rdused(PHY_Tx_rdused), .ping_data(ping_data), .LED(LED),
					.Tx_fifo_rdreq(Tx_fifo_rdreq),.Tx_CTL(PHY_TX_EN), .ARP_sent(ARP_sent),
					.ping_sent(ping_sent), .TD(PHY_TX),.DHCP_request(DHCP_request),
					.DHCP_discover_sent(DHCP_discover_sent), .This_MAC(This_MAC),
					.DHCP_discover(DHCP_discover), .DHCP_IP(DHCP_IP), .DHCP_request_sent(DHCP_request_sent),
					.METIS_discovery(METIS_discovery), .PC_IP(PC_IP), .PC_MAC(PC_MAC), .Length(Length),
			        .Port(Port), .This_IP(This_IP), .METIS_discover_sent(METIS_discover_sent),
			        .ARP_PC_MAC(ARP_PC_MAC), .ARP_PC_IP(ARP_PC_IP), .Ping_PC_IP(Ping_PC_IP),
			        .Ping_PC_MAC(Ping_PC_MAC), .speed_100T(1'b1), .Tx_reset(Tx_reset),
			        .run(run), .IP_valid(IP_valid), .printf(printf), .IP_lease(IP_lease),
			        .DHCP_MAC(DHCP_MAC), .DHCP_request_renew(DHCP_request_renew),
			        .erase_done(erase_done), .erase_done_ACK(erase_done_ACK), .send_more(send_more),
			        .send_more_ACK(send_more_ACK), .Hermes_serialno(Hermes_serialno),
			        .sp_fifo_rddata(sp_fifo_rddata), .sp_fifo_rdreq(sp_fifo_rdreq), 
			        .sp_fifo_rdused(), .wide_spectrum(wide_spectrum), .have_sp_data(sp_data_ready),
					  .AssignIP(AssignIP)
			        ); 

//------------------------ sequence ARP and Ping requests -----------------------------------

reg Send_ARP;
reg ping_reply;
reg ping_sent;
reg [16:0]times_up;			// time out counter so code wont hang here
reg [1:0] state;

localparam IDLE = 2'd0, ARP = 2'd1, PING = 2'd2;

always @ (posedge PHY_RX_CLOCK)
begin
	case (state)
	IDLE: begin
				times_up   <= 0;
				Send_ARP   <= 0;
				ping_reply <= 0;
				if (ARP_request) state <= ARP;
				else if (ping_request) state <= PING;
			end
	
	ARP:	begin	
				Send_ARP <= 1'b1;
				if (ARP_sent || times_up > 100000) state <= IDLE;
				times_up <= times_up + 17'd1;
			end
			
	PING:	begin
				ping_reply <= 1'b1;	
				if (ping_sent || times_up > 100000) state <= IDLE;
				times_up <= times_up + 17'd1;
			end 

	default: state = IDLE;
	endcase
end



//----------------------------------------------------
//   Receive PHY FIFO 
//----------------------------------------------------

/*
					    PHY_Rx_fifo (16k bytes) 
					
						---------------------
	  Rx_fifo_data |data[7:0]	  wrfull | PHY_wrfull ----> Flash LED!
						|				         |
		Rx_enable	|wrreq				   |
						|					      |									    
	PHY_data_clock	|>wrclk	 			   |
						---------------------								
  IF_PHY_drdy     |rdreq		  q[15:0]| IF_PHY_data [swap Endian] 
					   |					      |					  			
			       	|   		     rdempty| IF_PHY_rdempty 
			         |                    | 							
			 IF_clk	|>rdclk rdusedw[12:0]| 		    
					   ---------------------								
					   |                    |
			 IF_rst  |aclr                |								
					   ---------------------								
 
 NOTE: the rdempty stays asserted until enough words have been written to the input port to fill an entire word on the 
 output port. Hence 4 writes must take place for this to happen. 
 Also, rdusedw indicates how many 16 bit samples are available to be read. 
 
*/

wire PHY_wrfull;
wire IF_PHY_rdempty;
wire IF_PHY_drdy;


PHY_Rx_fifo PHY_Rx_fifo_inst(.wrclk (PHY_data_clock),.rdreq (IF_PHY_drdy),.rdclk (IF_clk),.wrreq(Rx_enable),
                .data (Rx_fifo_data),.q ({IF_PHY_data[7:0],IF_PHY_data[15:8]}), .rdempty(IF_PHY_rdempty),
                .wrfull(PHY_wrfull),.aclr(IF_rst | PHY_wrfull));


					 
					 
//------------------------------------------------
//   SP_fifo  (16384 words) dual clock FIFO
//------------------------------------------------

/*
        The spectrum data FIFO is 16 by 16384 words long on the input.
        Output is in Bytes for easy interface to the PHY code
        NB: The output flags are only valid after a read/write clock has taken place

       
							   SP_fifo
						---------------------
	      temp_ADC |data[15:0]	   wrfull| sp_fifo_wrfull
						|				         |
	sp_fifo_wrreq	|wrreq	     wrempty| sp_fifo_wrempty
						|				         |
			C122_clk	|>wrclk              | 
						---------------------
	sp_fifo_rdreq	|rdreq		   q[7:0]| sp_fifo_rddata
						|                    | 
						|				         |
		Tx_clock_2	|>rdclk		         | 
						|		               | 
						---------------------
						|                    |
	 C122_rst OR   |aclr                |
		!run   	   |                    |
	    				---------------------
		
*/

wire  sp_fifo_rdreq;
wire [7:0]sp_fifo_rddata;
wire sp_fifo_wrempty;
wire sp_fifo_wrfull;
wire sp_fifo_wrreq;


//--------------------------------------------------
//   Wideband Spectrum Data 
//--------------------------------------------------

//	When wide_spectrum is set and sp_fifo_wrempty then fill fifo with 16k words 
// of consecutive ADC samples.  Pass have_sp_data to Tx_MAC to indicate that 
// data is available.
// Reset fifo when !run so the data always starts at a known state.


wire have_sp_data;


SP_fifo  SPF (.aclr(C122_rst | !run), .wrclk (C122_clk), .rdclk(Tx_clock_2), 
             .wrreq (sp_fifo_wrreq), .data (temp_ADC), .rdreq (sp_fifo_rdreq),
             .q(sp_fifo_rddata), .wrfull(sp_fifo_wrfull), .wrempty(sp_fifo_wrempty)); 					 
					 
					 
sp_rcv_ctrl SPC (.clk(C122_clk), .reset(C122_rst), .sp_fifo_wrempty(sp_fifo_wrempty),
                 .sp_fifo_wrfull(sp_fifo_wrfull), .write(sp_fifo_wrreq), .have_sp_data(have_sp_data));	
				 
// the wideband data is presented too fast for the PC to swallow so slow down to 12500/4096 = 3kHz
// use a counter and when zero enable the wide spectrum data

reg [15:0]sp_delay;   
wire sp_data_ready;

always @ (posedge Tx_clock_2)
		sp_delay <= sp_delay + 15'd1;
		
assign sp_data_ready = (sp_delay == 0 && have_sp_data); 


	
//--------------------------------------------------------------------------
//			EPCS16 Erase and Program code 
//--------------------------------------------------------------------------

/*
					    EPCS_fifo (1k bytes) 
					
					    ---------------------
	  Rx_fifo_data  |data[7:0]	         | 
					    |				         |
 EPCS_FIFO_enable  |wrreq		         | 
					    |					      |									    
	PHY_data_clock  |>wrclk	 			   |
					    ---------------------								
	   EPCS_rdreq   |rdreq		  q[7:0] | EPCS_data
					    |					      |					  			
			     	    |   		            |  
			          |                   | 							
         Tx_clock  |>rdclk rdusedw[9:0]| EPCS_Rx_used	    
					    ---------------------								
					    |                    |
			  IF_rst  |aclr                |								
					    ---------------------						
*/

wire [7:0]EPCS_data;
wire [9:0]EPCS_Rx_used;
wire  EPCS_rdreq;

EPCS_fifo EPCS_fifo_inst(.wrclk (PHY_data_clock),.rdreq (EPCS_rdreq),.rdclk (Tx_clock),.wrreq(EPCS_FIFO_enable), 
                .data (Rx_fifo_data),.q (EPCS_data), .rdusedw(EPCS_Rx_used), .aclr(IF_rst));

//----------------------------
// 			ASMI Interface
//----------------------------
wire busy;
wire erase_done;
wire send_more;
wire erase_done_ACK;
wire send_more_ACK;
wire reset_FPGA;

ASMI_interface  ASMI_int_inst(.clock(Tx_clock), .busy(busy), .erase(erase), .erase_ACK(erase_ACK), .IF_PHY_data(EPCS_data),
							 .IF_Rx_used(EPCS_Rx_used), .rdreq(EPCS_rdreq), .erase_done(erase_done), .num_blocks(num_blocks),
							 .erase_done_ACK(erase_done_ACK), .send_more(send_more), .send_more_ACK(send_more_ACK), .NCONFIG(reset_FPGA)); 



      
assign IF_mic_Data = 0;



// AD9866 Code
// Code for Half duplex

assign ad9866_txen = FPGA_PTT;
assign ad9866_rxen = ~FPGA_PTT;

assign ad9866_rxclk = C122_clk;
assign ad9866_txclk = C122_clk;


// Code for Full duplex


//assign ad9866_txsync = 1'b0;
//assign ad9866_txquiet = 1'b0;
//assign ad9866_tx = 6'h00;


//reg [11:0] adio;

// Create adio from rxclk, assume it is in sync with C122_clk...

//always @(posedge ad9866_rxclk)
//begin
//	if (ad9866_rxsync == 1'b1)
//		adio[5:0] <= ad9866_rx;
//	else
//		adio[11:6] <= ad9866_rx;
//end





//---------------------------------------------------------
//		De-ramdomizer
//--------------------------------------------------------- 

/*

 A Digital Output Randomizer is fitted to the LTC2208. This complements bits 15 to 1 if 
 bit 0 is 1. This helps to reduce any pickup by the A/D input of the digital outputs. 
 We need to de-ramdomize the LTC2208 data if this is turned on. 
 
*/

reg [15:0]temp_ADC;
reg [15:0] temp_DACD; // for pre-distortion Tx tests
reg ad9866clipp;
reg ad9866clipn;
reg [7:0] dacdclip;


assign temp_DACD = 0;

always @ (posedge C122_clk) 
begin 

  	temp_ADC <= {{4{ad9866_adio[11]}},ad9866_adio};

    if (ad9866_adio == 12'b011111111111)
    	ad9866clipp <= 1'b1;
    else
    	ad9866clipp <= 1'b0;


	if (ad9866_adio == 12'b100000000000)
    	ad9866clipn <= 1'b1;
    else
    	ad9866clipn <= 1'b0;


   	if (DACD[13:12] == 2'b01)
    	dacdclip[7] <= 1'b1;
    else
    	dacdclip[7] <= 1'b0;


   	if (DACD[13:11] == 3'b001)
    	dacdclip[6] <= 1'b1;
    else
    	dacdclip[6] <= 1'b0;


   	if (DACD[13:10] == 4'b0001)
    	dacdclip[5] <= 1'b1;
    else
    	dacdclip[5] <= 1'b0;


   	if (DACD[13:9] == 5'b00001)
    	dacdclip[4] <= 1'b1;
    else
    	dacdclip[4] <= 1'b0;


   	if (DACD[13:8] == 6'b000001)
    	dacdclip[3] <= 1'b1;
    else
    	dacdclip[3] <= 1'b0;


   	if (DACD[13:7] == 7'b0000001)
    	dacdclip[2] <= 1'b1;
    else
    	dacdclip[2] <= 1'b0;


   	if (DACD[13:6] == 8'b00000001)
    	dacdclip[1] <= 1'b1;
    else
    	dacdclip[1] <= 1'b0;


   	if (DACD[13:6] == 9'b000000001)
    	dacdclip[0] <= 1'b1;
    else
    	dacdclip[0] <= 1'b0;


end 


// RX/TX port
assign ad9866_adio = FPGA_PTT ? DACD[13:2] : 12'bZ;




//------------------------------------------------------------------------------
//                 Transfer  Data from IF clock to 122.88MHz clock domain
//------------------------------------------------------------------------------

// cdc_sync is used to transfer from a slow to a fast clock domain

wire  [31:0] C122_LR_data;
wire  C122_DFS0, C122_DFS1;
wire  C122_rst;
wire  signed [15:0] C122_I_PWM;
wire  signed [15:0] C122_Q_PWM;

cdc_sync #(32)
	freq0 (.siga(IF_frequency[0]), .rstb(C122_rst), .clkb(C122_clk), .sigb(C122_frequency_HZ_Tx)); // transfer Tx frequency

cdc_sync #(2)
	rates (.siga({IF_DFS1,IF_DFS0}), .rstb(C122_rst), .clkb(C122_clk), .sigb({C122_DFS1, C122_DFS0})); // sample rate
	
cdc_sync #(16)
    Tx_I  (.siga(IF_I_PWM), .rstb(C122_rst), .clkb(_122MHz), .sigb(C122_I_PWM )); // Tx I data
    
cdc_sync #(16)
    Tx_Q  (.siga(IF_Q_PWM), .rstb(C122_rst), .clkb(_122MHz), .sigb(C122_Q_PWM)); // Tx Q data
    
   

reg signed [15:0]C122_cic_i;
reg signed [15:0]C122_cic_q;
wire C122_ce_out_i;
wire C122_ce_out_q; 

//------------------------------------------------------------------------------
//                 Pulse generators
//------------------------------------------------------------------------------

wire IF_CLRCLK;

//  Create short pulse from posedge of CLRCLK synced to IF_clk for RXF read timing
//  First transfer CLRCLK into IF clock domain
cdc_sync cdc_CRLCLK (.siga(CLRCLK), .rstb(IF_rst), .clkb(IF_clk), .sigb(IF_CLRCLK)); 
//  Now generate the pulse
pulsegen cdc_m   (.sig(IF_CLRCLK), .rst(IF_rst), .clk(IF_clk), .pulse(IF_get_samples));


//---------------------------------------------------------
//		Convert frequency to phase word 
//---------------------------------------------------------

/*	
     Calculates  ratio = fo/fs = frequency/122.88Mhz where frequency is in MHz
	 Each calculation should take no more than 1 CBCLK

	 B scalar multiplication will be used to do the F/122.88Mhz function
	 where: F * C = R
	 0 <= F <= 65,000,000 hz
	 C = 1/122,880,000 hz
	 0 <= R < 1

	 This method will use a 32 bit by 32 bit multiply to obtain the answer as follows:
	 1. F will never be larger than 65,000,000 and it takes 26 bits to hold this value. This will
		be a B0 number since we dont need more resolution than 1 Hz - i.e. fractions of a hertz.
	 2. C is a constant.  Notice that the largest value we could multiply this constant by is B26
		and have a signed value less than 1.  Multiplying again by B31 would give us the biggest
		signed value we could hold in a 32 bit number.  Therefore we multiply by B57 (26+31).
		This gives a value of M2 = 1,172,812,403 (B57/122880000)
	 3. Now if we multiply the B0 number by the B57 number (M2) we get a result that is a B57 number.
		This is the result of the desire single 32 bit by 32 bit multiply.  Now if we want a scaled
		32 bit signed number that has a range -1 <= R < 1, then we want a B31 number.  Thus we shift
		the 64 bit result right 32 bits (B57 -> B31) or merely select the appropriate bits of the
		64 bit result. Sweet!  However since R is always >= 0 we will use an unsigned B32 result
*/

//------------------------------------------------------------------------------
//                 All DSP code is in the Receiver module
//------------------------------------------------------------------------------

reg       [31:0] C122_frequency_HZ [0:NR-1];   // frequency control bits for CORDIC
reg       [31:0] C122_frequency_HZ_Tx;
reg       [31:0] C122_last_freq [0:NR-1];
reg       [31:0] C122_last_freq_Tx;
reg       [31:0] C122_sync_phase_word [0:NR-1];
reg       [31:0] C122_sync_phase_word_Tx;
wire      [63:0] C122_ratio [0:NR-1];
wire      [63:0] C122_ratio_Tx;
wire      [23:0] rx_I [0:NR-1];
wire      [23:0] rx_Q [0:NR-1];
wire             strobe [0:NR-1];
wire  			  IF_IQ_Data_rdy;
wire 		 [47:0] IF_IQ_Data;
wire             test_strobe3;

// set the decimation rate 40 = 48k.....2 = 960k
	
	reg [5:0] rate;
	
	always @ ({C122_DFS1, C122_DFS0})
	begin 
		case ({C122_DFS1, C122_DFS0})
//    	0: rate <= 6'd24;     //  48ksps 
//    	1: rate <= 6'd12;     //  96ksps
//    	2: rate <= 6'd06;     //  192ksps
//    	3: rate <= 6'd03;      //  384ksps    	
//    	default: rate <= 6'd24;    			

    	0: rate <= RATE48;     //  48ksps 
    	1: rate <= RATE96;     //  96ksps
    	2: rate <= RATE192;     //  192ksps
    	// FIXME: What to do for 384ksps with 61.44 MHZ Xtal?
    	3: rate <= RATE384;      //  384ksps    	
    	default: rate <= RATE48;    	

		endcase
	end 

genvar c;
generate
  for (c = 0; c < NR; c = c + 1) // calc freq phase word for 4 freqs (Rx1, Rx2, Rx3, Rx4)
   begin: MDC 
    //  assign C122_ratio[c] = C122_frequency_HZ[c] * M2; // B0 * B57 number = B57 number

   // Note: We add 1/2 M2 (M3) so that we end up with a rounded 32 bit integer below.
    assign C122_ratio[c] = C122_frequency_HZ[c] * M2 + M3; // B0 * B57 number = B57 number 

    always @ (posedge C122_clk)
    begin
      if (C122_cbrise) // time between C122_cbrise is enough for ratio calculation to settle
      begin
        C122_last_freq[c] <= C122_frequency_HZ[c];
        if (C122_last_freq[c] != C122_frequency_HZ[c]) // frequency changed)
          C122_sync_phase_word[c] <= C122_ratio[c][56:25]; // B57 -> B32 number since R is always >= 0  
      end 		
    end

	cdc_mcp #(48)			// Transfer the receiver data and strobe from C122_clk to IF_clk
		IQ_sync (.a_data ({rx_I[c], rx_Q[c]}), .a_clk(C122_clk),.b_clk(IF_clk), .a_data_rdy(strobe[c]),
				.a_rst(C122_rst), .b_rst(IF_rst), .b_data(IF_M_IQ_Data[c]), .b_data_ack(IF_M_IQ_Data_rdy[c]));

	receiver receiver_inst(
	//control
	.clock(C122_clk),
	.rate(rate),
	.frequency(C122_sync_phase_word[c]),
	.out_strobe(strobe[c]),
	//input
	.in_data(temp_ADC),
	//output
	.out_data_I(rx_I[c]),
	.out_data_Q(rx_Q[c]),
	.test_strobe3()
	);

	cdc_sync #(32)
		freq (.siga(IF_frequency[c+1]), .rstb(C122_rst), .clkb(C122_clk), .sigb(C122_frequency_HZ[c])); // transfer Rx1 frequency
end
endgenerate


//wire [15:0] select_input;
//wire [31:0] select_frequency;
//assign select_input = FPGA_PTT ?  temp_DACD : temp_ADC;												// ADC on Rx and DAC on Tx
//assign select_frequency = FPGA_PTT ? C122_sync_phase_word_Tx : C122_sync_phase_word[0]; 	// Rx5 freq on Rx and Tx freq on Tx


//receiver receiver_inst0(   // Rx1
	//control
//	.clock(C122_clk),
//	.rate(rate),
//	.frequency(C122_sync_phase_word[0]),
//	.out_strobe(strobe[0]),
	//input
//	.in_data(temp_ADC),
	//output
//	.out_data_I(rx_I[0]),
//	.out_data_Q(rx_Q[0]),
//	.test_strobe3()
//	);

//receiver receiver_inst1(	// Rx2
	//control
//	.clock(C122_clk),
//	.rate(rate),
//	.frequency(C122_sync_phase_word[1]),
//	.out_strobe(strobe[1]),
	//input
//	.in_data(temp_ADC),
	//output
//	.out_data_I(rx_I[1]),
//	.out_data_Q(rx_Q[1]),
//	.test_strobe3()
//	);



// calc frequency phase word for Tx
//assign C122_ratio_Tx = C122_frequency_HZ_Tx * M2;
// Note: We add 1/2 M2 (M3) so that we end up with a rounded 32 bit integer below.
assign C122_ratio_Tx = C122_frequency_HZ_Tx * M2 + M3; 

always @ (posedge C122_clk)
begin
  if (C122_cbrise)
  begin
    C122_last_freq_Tx <= C122_frequency_HZ_Tx;
	 if (C122_last_freq_Tx != C122_frequency_HZ_Tx)
	  C122_sync_phase_word_Tx <= C122_ratio_Tx[56:25];
  end
end



//---------------------------------------------------------
//    ADC SPI interface 
//---------------------------------------------------------

wire [11:0] AIN1;
wire [11:0] AIN2;
wire [11:0] AIN3;
wire [11:0] AIN4;
wire [11:0] AIN5;  // holds 12 bit ADC value of Forward Power detector.
wire [11:0] AIN6;  // holds 12 bit ADC of 13.8v measurement 

//Hermes_ADC ADC_SPI(.clock(CBCLK), .SCLK(ADCCLK), .nCS(nADCCS), .MISO(ADCMISO), .MOSI(ADCMOSI),
//				   .AIN1(AIN1), .AIN2(AIN2), .AIN3(AIN3), .AIN4(AIN4), .AIN5(AIN5), .AIN6(AIN6));	

assign AIN1 = 0;
assign AIN2 = 0;
assign AIN3 = 0;
assign AIN4 = 0;
assign AIN5 =  200;
assign AIN6 = 1000;
	


reg IF_Filter;
reg IF_Tuner;
reg IF_autoTune;

//---------------------------------------------------------
//                 Transmitter code 
//---------------------------------------------------------	

/* 
	The gain distribution of the transmitter code is as follows.
	Since the CIC interpolating filters do not interpolate by 2^n they have an overall loss.
	
	The overall gain in the interpolating filter is ((RM)^N)/R.  So in this case its 2560^4.
	This is normalised by dividing by ceil(log2(2560^4)).
	
	In which case the normalized gain would be (2560^4)/(2^46) = .6103515625
	
	The CORDIC has an overall gain of 1.647.
	
	Since the CORDIC takes 16 bit I & Q inputs but output needs to be truncated to 14 bits, in order to
	interface to the DAC, the gain is reduced by 1/4 to 0.41175
	
	We need to be able to drive to DAC to its full range in order to maximise the S/N ratio and 
	minimise the amount of PA gain.  We can increase the output of the CORDIC by multiplying it by 4.
	This is simply achieved by setting the CORDIC output width to 16 bits and assigning bits [13:0] to the DAC.
	
	The gain distripution is now:
	
	0.61 * 0.41174 * 4 = 1.00467 
	
	This means that the DAC output will wrap if a full range 16 bit I/Q signal is received. 
	This can be prevented by reducing the output of the CIC filter.
	
	If we subtract 1/128 of the CIC output from itself the level becomes
	
	1 - 1/128 = 0.9921875
	
	Hence the overall gain is now 
	
	0.61 * 0.9921875 * 0.41174 * 4 = 0.996798
	

*/	

reg signed [15:0]C122_fir_i;
reg signed [15:0]C122_fir_q;

// latch I&Q data on strobe from FIR
always @ (posedge _122MHz)
begin 
	if (req1) begin 
		C122_fir_i = C122_I_PWM;
		C122_fir_q = C122_Q_PWM;	
	end 
end 


// Interpolate I/Q samples from 48 kHz to the clock frequency

wire req1, req2;
wire [19:0] y1_r, y1_i; 
wire [15:0] y2_r, y2_i;

FirInterp8_1024 fi (_122MHz, req2, req1, C122_fir_i, C122_fir_q, y1_r, y1_i);  // req2 enables an output sample, req1 requests next input sample.

// GBITS reduced to 31
CicInterpM5 #(.RRRR(192), .IBITS(20), .OBITS(16), .GBITS(31)) in2 ( _122MHz, 1'd1, req2, y1_r, y1_i, y2_r, y2_i);



//---------------------------------------------------------
//    CORDIC NCO 
//---------------------------------------------------------

// Code rotates input at set frequency and produces I & Q 

wire signed [14:0] C122_cordic_i_out;
wire signed [31:0] C122_phase_word_Tx;

wire signed [15:0] I;
wire signed [15:0] Q;

// if in VNA mode use the Rx[0] phase word for the Tx
assign C122_phase_word_Tx = VNA ? C122_sync_phase_word[0] : C122_sync_phase_word_Tx;
assign                  I = VNA ? 16'd19274 : y2_i;   	// select VNA mode if active. Set CORDIC for max DAC output
assign                  Q = VNA ? 0 : y2_r; 					// taking into account CORDICs gain i.e. 0x7FFF/1.7


// NOTE:  I and Q inputs reversed to give correct sideband out 

cpl_cordic #(.OUT_WIDTH(16))
 		cordic_inst (.clock(_122MHz), .frequency(C122_phase_word_Tx), .in_data_I(I),			
		.in_data_Q(Q), .out_data_I(C122_cordic_i_out), .out_data_Q());		
			 	 
/* 
  We can use either the I or Q output from the CORDIC directly to drive the DAC.

    exp(jw) = cos(w) + j sin(w)

  When multplying two complex sinusoids f1 and f2, you get only f1 + f2, no
  difference frequency.

      Z = exp(j*f1) * exp(j*f2) = exp(j*(f1+f2))
        = cos(f1 + f2) + j sin(f1 + f2)
*/

// the CORDIC output is stable on the negative edge of the clock

reg [13:0] DACD;

always @ (negedge _122MHz)
	DACD <= C122_cordic_i_out[13:0];   //gain of 4


//`endif

//------------------------------------------------------------
//  Set Power Output 
//------------------------------------------------------------

// PWM DAC to set drive current to DAC. PWM_count increments 
// using IF_clk. If the count is less than the drive 
// level set by the PC then DAC_ALC will be high, otherwise low.  

//reg [7:0] PWM_count;
//always @ (posedge _122MHz)
//begin 
//	PWM_count <= PWM_count + 1'b1;
//	if (IF_Drive_Level >= PWM_count)
//		DAC_ALC <= 1'b1;
//	else 
//		DAC_ALC <= 1'b0;
//end 


//---------------------------------------------------------
//  Receive DOUT and CDOUT data to put in TX FIFO
//---------------------------------------------------------

wire   [15:0] IF_P_mic_Data;
wire          IF_P_mic_Data_rdy;
wire   [47:0] IF_M_IQ_Data [0:NR-1];
wire [NR-1:0] IF_M_IQ_Data_rdy;
wire   [63:0] IF_tx_IQ_mic_data;
reg           IF_tx_IQ_mic_rdy;
wire   [15:0] IF_mic_Data;
wire    [2:0] IF_chan;
wire    [2:0] IF_last_chan;
wire     [47:0] IF_chan_test;

always @*
begin
  if (IF_rst)
    IF_tx_IQ_mic_rdy = 1'b0;
  else 
      IF_tx_IQ_mic_rdy = IF_M_IQ_Data_rdy[0]; 	// this the strobe signal from the ADC now in IF clock domain
end

assign IF_IQ_Data = IF_M_IQ_Data[IF_chan];

// concatenate the IQ and Mic data to form a 64 bit data word
assign IF_tx_IQ_mic_data = {IF_IQ_Data, IF_mic_Data};  

//----------------------------------------------------------------------------
//     Tx_fifo Control - creates IF_tx_fifo_wdata and IF_tx_fifo_wreq signals
//----------------------------------------------------------------------------

localparam RFSZ = clogb2(RX_FIFO_SZ-1);  // number of bits needed to hold 0 - (RX_FIFO_SZ-1)
localparam TFSZ = clogb2(TX_FIFO_SZ-1);  // number of bits needed to hold 0 - (TX_FIFO_SZ-1)
localparam SFSZ = clogb2(SP_FIFO_SZ-1);  // number of bits needed to hold 0 - (SP_FIFO_SZ-1)

wire     [15:0] IF_tx_fifo_wdata;   		// LTC2208 ADC uses this to send its data to Tx FIFO
wire            IF_tx_fifo_wreq;    		// set when we want to send data to the Tx FIFO
wire            IF_tx_fifo_full;
wire [TFSZ-1:0] IF_tx_fifo_used;
wire            IF_tx_fifo_rreq;
wire            IF_tx_fifo_empty;

wire [RFSZ-1:0] IF_Rx_fifo_used;    		// read side count
wire            IF_Rx_fifo_full;

wire            clean_dash;      			// debounced dash key
wire            clean_dot;       			// debounced dot key
wire            clean_PTT_in;    			// debounced PTT button
wire     [11:0] Penny_ALC;

wire   [RFSZ:0] RX_USED;
wire            IF_tx_fifo_clr;

assign RX_USED = {IF_Rx_fifo_full,IF_Rx_fifo_used};


assign Penny_ALC = AIN5; 

wire VNA_start = VNA && IF_Rx_save && (IF_Rx_ctrl_0[7:1] == 7'b0000_001);  // indicates a frequency change for the VNA.


wire IO4;
wire IO5;
wire IO6;
wire IO8;
wire OVERFLOW;
assign IO4 = 1'b1;
assign IO5 = 1'b1;
assign IO6 = 1'b1;
assign IO8 = 1'b1;
assign OVERFLOW = 1'b0;

Hermes_Tx_fifo_ctrl #(RX_FIFO_SZ, TX_FIFO_SZ) TXFC 
           (IF_rst, IF_clk, IF_tx_fifo_wdata, IF_tx_fifo_wreq, IF_tx_fifo_full,
            IF_tx_fifo_used, IF_tx_fifo_clr, IF_tx_IQ_mic_rdy,
            IF_tx_IQ_mic_data, IF_chan, IF_last_chan, clean_dash, clean_dot, clean_PTT_in, OVERFLOW,
            Penny_serialno, Merc_serialno, Hermes_serialno, Penny_ALC, AIN1, AIN2,
            AIN3, AIN4, AIN6, IO4, IO5, IO6, IO8, VNA_start, VNA);

//------------------------------------------------------------------------
//   Tx_fifo  (1024 words) Dual clock FIFO - Altera Megafunction (dcfifo)
//------------------------------------------------------------------------

/*
        Data from the Tx FIFO Controller  is written to the FIFO using IF_tx_fifo_wreq. 
        FIFO is 1024 WORDS long.
        NB: The output flags are only valid after a read/write clock has taken place
        
        
							--------------------
	IF_tx_fifo_wdata 	|data[15:0]		 wrful| IF_tx_fifo_full
						   |				         |
	IF_tx_fifo_wreq	|wreq		     wrempty| IF_tx_fifo_empty
						   |				   	   |
		IF_clk			|>wrclk	 wrused[9:0]| IF_tx_fifo_used
						   ---------------------
    Tx_fifo_rdreq		|rdreq		   q[7:0]| PHY_Tx_data
						   |					      |
	   Tx_clock_2		|>rdclk		  rdempty| 
						   |		  rdusedw[10:0]| PHY_Tx_rdused  (0 to 2047 bytes)
						   ---------------------
						   |                    |
 IF_tx_fifo_clr OR  	|aclr                |
	IF_rst				---------------------
				
        

*/

Tx_fifo Tx_fifo_inst(.wrclk (IF_clk),.rdreq (Tx_fifo_rdreq),.rdclk (Tx_clock_2),.wrreq (IF_tx_fifo_wreq), 
                .data ({IF_tx_fifo_wdata[7:0], IF_tx_fifo_wdata[15:8]}),.q (PHY_Tx_data),.wrusedw(IF_tx_fifo_used), .wrfull(IF_tx_fifo_full),
                .rdempty(),.rdusedw(PHY_Tx_rdused),.wrempty(IF_tx_fifo_empty),.aclr(IF_rst || IF_tx_fifo_clr ));

wire [7:0] PHY_Tx_data;
reg [3:0]sync_TD;
wire PHY_Tx_rdempty;             
             


//---------------------------------------------------------
//   Rx_fifo  (2048 words) single clock FIFO
//---------------------------------------------------------

wire [15:0] IF_Rx_fifo_rdata;
reg         IF_Rx_fifo_rreq;    // controls reading of fifo
wire [15:0] IF_PHY_data;

wire [15:0] IF_Rx_fifo_wdata;
reg         IF_Rx_fifo_wreq;

FIFO #(RX_FIFO_SZ) RXF (.rst(IF_rst), .clk (IF_clk), .full(IF_Rx_fifo_full), .usedw(IF_Rx_fifo_used), 
          .wrreq (IF_Rx_fifo_wreq), .data (IF_PHY_data), 
          .rdreq (IF_Rx_fifo_rreq), .q (IF_Rx_fifo_rdata) );


//------------------------------------------------------------
//   Sync and  C&C  Detector
//------------------------------------------------------------

/*

  Read the value of IF_PHY_data whenever IF_PHY_drdy is set.
  Look for sync and if found decode the C&C data.
  Then send subsequent data to Rx FIF0 until end of frame.
	
*/

reg   [2:0] IF_SYNC_state;
reg   [2:0] IF_SYNC_state_next;
reg   [7:0] IF_SYNC_frame_cnt; 	// 256-4 words = 252 words
reg   [7:0] IF_Rx_ctrl_0;   		// control C0 from PC
reg   [7:0] IF_Rx_ctrl_1;   		// control C1 from PC
reg   [7:0] IF_Rx_ctrl_2;   		// control C2 from PC
reg   [7:0] IF_Rx_ctrl_3;   		// control C3 from PC
reg   [7:0] IF_Rx_ctrl_4;   		// control C4 from PC
reg         IF_Rx_save;


localparam SYNC_IDLE   = 1'd0,
           SYNC_START  = 1'd1,
           SYNC_RX_1_2 = 2'd2,
           SYNC_RX_3_4 = 2'd3,
           SYNC_FINISH = 3'd4;

always @ (posedge IF_clk)
begin
  if (IF_rst)
    IF_SYNC_state <= #IF_TPD SYNC_IDLE;
  else
    IF_SYNC_state <= #IF_TPD IF_SYNC_state_next;

  if (IF_rst)
    IF_Rx_save <= #IF_TPD 1'b0;
  else
    IF_Rx_save <= #IF_TPD IF_PHY_drdy && (IF_SYNC_state == SYNC_RX_3_4);

  if (IF_PHY_drdy && (IF_SYNC_state == SYNC_START) && (IF_PHY_data[15:8] == 8'h7F))
    IF_Rx_ctrl_0  <= #IF_TPD IF_PHY_data[7:0];

  if (IF_PHY_drdy && (IF_SYNC_state == SYNC_RX_1_2))
  begin
    IF_Rx_ctrl_1  <= #IF_TPD IF_PHY_data[15:8];
    IF_Rx_ctrl_2  <= #IF_TPD IF_PHY_data[7:0];
  end

  if (IF_PHY_drdy && (IF_SYNC_state == SYNC_RX_3_4))
  begin
    IF_Rx_ctrl_3  <= #IF_TPD IF_PHY_data[15:8];
    IF_Rx_ctrl_4  <= #IF_TPD IF_PHY_data[7:0];
  end

  if (IF_SYNC_state == SYNC_START)
    IF_SYNC_frame_cnt <= 0;					    					// reset sync counter
  else if (IF_PHY_drdy && (IF_SYNC_state == SYNC_FINISH))
    IF_SYNC_frame_cnt <= IF_SYNC_frame_cnt + 1'b1;		    // increment if we have data to store
end

always @*
begin
  case (IF_SYNC_state)
    // state SYNC_IDLE  - loop until we find start of sync sequence
    SYNC_IDLE:
    begin
      IF_Rx_fifo_wreq  = 1'b0;             // Note: Sync bytes not saved in Rx_fifo

      if (IF_rst || !IF_PHY_drdy) 
        IF_SYNC_state_next = SYNC_IDLE;    // wait till we get data from PC
      else if (IF_PHY_data == 16'h7F7F)
        IF_SYNC_state_next = SYNC_START;   // possible start of sync
      else
        IF_SYNC_state_next = SYNC_IDLE;
    end	

    // check for 0x7F  sync character & get Rx control_0 
    SYNC_START:
    begin
      IF_Rx_fifo_wreq  = 1'b0;             // Note: Sync bytes not saved in Rx_fifo

      if (!IF_PHY_drdy)              
        IF_SYNC_state_next = SYNC_START;   // wait till we get data from PC
      else if (IF_PHY_data[15:8] == 8'h7F)
        IF_SYNC_state_next = SYNC_RX_1_2;  // have sync so continue
      else
        IF_SYNC_state_next = SYNC_IDLE;    // start searching for sync sequence again
    end

    
    SYNC_RX_1_2:                        	 // save Rx control 1 & 2
    begin
      IF_Rx_fifo_wreq  = 1'b0;             // Note: Rx control 1 & 2 not saved in Rx_fifo

      if (!IF_PHY_drdy)              
        IF_SYNC_state_next = SYNC_RX_1_2;  // wait till we get data from PC
      else
        IF_SYNC_state_next = SYNC_RX_3_4;
    end

    SYNC_RX_3_4:                        	 // save Rx control 3 & 4
    begin
      IF_Rx_fifo_wreq  = 1'b0;             // Note: Rx control 3 & 4 not saved in Rx_fifo

      if (!IF_PHY_drdy)              
        IF_SYNC_state_next = SYNC_RX_3_4;  // wait till we get data from PC
      else
        IF_SYNC_state_next = SYNC_FINISH;
    end

    // Remainder of data goes to Rx_fifo, re-start looking
    // for a new SYNC at end of this frame. 
    // Note: due to the use of IF_PHY_drdy data will only be written to the 
    // Rx fifo if there is room. Also the frame_count will only be incremented if IF_PHY_drdy is true.
    SYNC_FINISH:
    begin    
	  IF_Rx_fifo_wreq  = IF_PHY_drdy;
	  if (IF_SYNC_frame_cnt == ((512-8)/2)) begin  // frame ended, go get sync again
		IF_SYNC_state_next = SYNC_IDLE;
	  end 
	  else IF_SYNC_state_next = SYNC_FINISH;
    end

    default:
    begin
      IF_Rx_fifo_wreq  = 1'b0;
      IF_SYNC_state_next = SYNC_IDLE;
    end
	endcase
end

wire have_room;
assign have_room = (IF_Rx_fifo_used < RX_FIFO_SZ - ((512-8)/2)) ? 1'b1 : 1'b0;  // the /2 is because we send 16 bit values

// prevent read from PHY fifo if empty and writing to Rx fifo if not enough room 
assign  IF_PHY_drdy = have_room & ~IF_PHY_rdempty;

//assign IF_PHY_drdy = ~IF_PHY_rdempty;



//---------------------------------------------------------
//              Decode Command & Control data
//---------------------------------------------------------

/*
	Decode IF_Rx_ctrl_0....IF_Rx_ctrl_4.

	Decode frequency (both Tx and Rx if full duplex selected), PTT, Speed etc

	The current frequency is set by the PC by decoding 
	IF_Rx_ctrl_1... IF_Rx_ctrl_4 when IF_Rx_ctrl_0[7:1] = 7'b0000_001
		
      The Rx Sampling Rate, either 192k, 96k or 48k is set by
      the PC by decoding IF_Rx_ctrl_1 when IF_Rx_ctrl_0[7:1] are all zero. IF_Rx_ctrl_1
      decodes as follows:

      IF_Rx_ctrl_1 = 8'bxxxx_xx00  - 48kHz
      IF_Rx_ctrl_1 = 8'bxxxx_xx01  - 96kHz
      IF_Rx_ctrl_1 = 8'bxxxx_xx10  - 192kHz

	Decode PTT from PC. Held in IF_Rx_ctrl_0[0] as follows
	
	0 = PTT inactive
	1 = PTT active
	
	Decode Attenuator settings on Alex, when IF_Rx_ctrl_0[7:1] = 0, IF_Rx_ctrl_3[1:0] indicates the following 
	
	00 = 0dB
	01 = 10dB
	10 = 20dB
	11 = 30dB
	
	Decode ADC & Attenuator settings on Hermes, when IF_Rx_ctrl_0[7:1] = 0, IF_Rx_ctrl_3[4:2] indicates the following
	
	000 = Random, Dither, Preamp OFF
	1xx = Random ON
	x1x = Dither ON
	xx1 = Preamp ON **** replace with attenuator
	
	Decode Rx relay settings on Alex, when IF_Rx_ctrl_0[7:1] = 0, IF_Rx_ctrl_3[6:5] indicates the following
	
	00 = None
	01 = Rx 1
	10 = Rx 2
	11 = Transverter
	
	Decode Tx relay settigs on Alex, when IF_Rx_ctrl_0[7:1] = 0, IF_Rx_ctrl_4[1:0] indicates the following
	
	00 = Tx 1
	01 = Tx 2
	10 = Tx 3
	
	Decode Rx_1_out relay settigs on Alex, when IF_Rx_ctrl_0[7:1] = 0, IF_Rx_ctrl_3[7] indicates the following

	1 = Rx_1_out on 

	When IF_Rx_ctrl_0[7:1] == 7'b0001_010 decodes as follows:
	
	IF_Line_In_Gain		<= IF_Rx_ctrl2[4:0]	// decode 5-bit line gain setting
	
*/

reg   [6:0] IF_OC;       			// open collectors on Hermes
reg         IF_mode;     			// normal or Class E PA operation 
reg         IF_RAND;     			// when set randomizer in ADCon
reg         IF_DITHER;   			// when set dither in ADC on
reg   [1:0] IF_ATTEN;    			// decode attenuator setting on Alex
reg         Preamp;					// selects input attenuator setting, 0 = 20dB, 1 = 0dB (preamp ON)
reg   [1:0] IF_TX_relay; 			// Tx relay setting on Alex
reg         IF_Rout;     			// Rx1 out on Alex
reg   [1:0] IF_RX_relay; 			// Rx relay setting on Alex 
reg  [31:0] IF_frequency[0:5]; 	// Tx, Rx1, Rx2, Rx3, Rx4, Rx5
reg         IF_duplex;
reg         IF_DFS1;
reg			IF_DFS0;
reg   [7:0] IF_Drive_Level; 		// Tx drive level
reg         IF_Mic_boost;			// Mic boost 0 = 0dB, 1 = 20dB
reg         IF_Line_In;				// Selects input, mic = 0, line = 1
reg   [4:0] IF_Line_In_Gain;		// Sets Line-In Gain value (00000=-32.4 dB to 11111=+12 dB in 1.5 dB steps)
reg         IF_Apollo;				// Selects Alex (0) or Apollo (1)
reg 			VNA;						// Selects VNA mode when set. 
reg		   Alex_manual; 	  		// set if manual selection of Alex relays active
reg         Alex_6m_preamp; 		// set if manual selection and 6m preamp selected
reg   [6:0] Alex_manual_LPF;		// Alex LPF relay selection in manual mode
reg   [5:0] Alex_manual_HPF;		// Alex HPF relay selection in manual mode
reg   [4:0] Hermes_atten;			// 0-31 dB Heremes attenuator value
reg			Hermes_atten_enable; // enable/disable bit for Hermes attenuator
reg			TR_relay_disable;		// Alex T/R relay disable option

always @ (posedge IF_clk)
begin 
  if (IF_rst)
  begin // set up default values - 0 for now
    // RX_CONTROL_1
    {IF_DFS1, IF_DFS0} <= 2'b00;   	// decode speed 
    // RX_CONTROL_2
    IF_mode            <= 1'b0;    	// decode mode, normal or Class E PA
    IF_OC              <= 7'b0;    	// decode open collectors on Hermes
    // RX_CONTROL_3
    IF_ATTEN           <= 2'b0;    	// decode Alex attenuator setting 
    Preamp             <= 1'b1;    	// decode Preamp (Attenuator), default on
    IF_DITHER          <= 1'b1;    	// decode dither on or off
    IF_RAND            <= 1'b0;    	// decode randomizer on or off
    IF_RX_relay        <= 2'b0;    	// decode Alex Rx relays
    IF_Rout            <= 1'b0;    	// decode Alex Rx_1_out relay
	 TR_relay_disable   <= 1'b0;     // decode Alex T/R relay disable
    // RX_CONTROL_4
    IF_TX_relay        <= 2'b0;    	// decode Alex Tx Relays
    IF_duplex          <= 1'b0;    	// not in duplex mode
	 IF_last_chan       <= 3'b000;  	// default single receiver
    IF_Mic_boost       <= 1'b0;    	// mic boost off 
    IF_Drive_Level     <= 8'b0;	   // drive at minimum
	 IF_Line_In			  <= 1'b0;		// select Mic input, not Line in
	 IF_Filter			  <= 1'b0;		// Apollo filter disabled (bypassed)
	 IF_Tuner			  <= 1'b0;		// Apollo tuner disabled (bypassed)
	 IF_autoTune	     <= 1'b0;		// Apollo auto-tune disabled
	 IF_Apollo			  <= 1'b0;     //	Alex selected		
	 VNA					  <= 1'b0;		// VNA disabled
	 Alex_manual		  <= 1'b0; 	  	// default manual Alex filter selection (0 = auto selection, 1 = manual selection)
	 Alex_manual_HPF	  <= 6'b0;		// default manual settings, no Alex HPF filters selected
	 Alex_6m_preamp	  <= 1'b0;		// default not set
	 Alex_manual_LPF	  <= 7'b0;		// default manual settings, no Alex LPF filters selected
	 IF_Line_In_Gain	  <= 5'b0;		// default line-in gain at min
	 Hermes_atten		  <= 5'b0;		// default zero input attenuation
	 Hermes_atten_enable <= 1'b0;    // default disable Hermes attenuator
	
  end
  else if (IF_Rx_save) 					// all Rx_control bytes are ready to be saved
  begin 										// Need to ensure that C&C data is stable 
    if (IF_Rx_ctrl_0[7:1] == 7'b0000_000)
    begin
      // RX_CONTROL_1
      {IF_DFS1, IF_DFS0}  <= IF_Rx_ctrl_1[1:0]; // decode speed 
      // RX_CONTROL_2
      IF_mode             <= IF_Rx_ctrl_2[0];   // decode mode, normal or Class E PA
      IF_OC               <= IF_Rx_ctrl_2[7:1]; // decode open collectors on Penelope
      // RX_CONTROL_3
      IF_ATTEN            <= IF_Rx_ctrl_3[1:0]; // decode Alex attenuator setting 
      Preamp              <= IF_Rx_ctrl_3[2];  // decode Preamp (Attenuator)  1 = On (0dB atten), 0 = Off (20dB atten)
      IF_DITHER           <= IF_Rx_ctrl_3[3];   // decode dither on or off
      IF_RAND             <= IF_Rx_ctrl_3[4];   // decode randomizer on or off
      IF_RX_relay         <= IF_Rx_ctrl_3[6:5]; // decode Alex Rx relays
      IF_Rout             <= IF_Rx_ctrl_3[7];   // decode Alex Rx_1_out relay
      // RX_CONTROL_4
      IF_TX_relay         <= IF_Rx_ctrl_4[1:0]; // decode Alex Tx Relays
      IF_duplex           <= IF_Rx_ctrl_4[2];   // save duplex mode
      IF_last_chan	     <= IF_Rx_ctrl_4[5:3]; // number of IQ streams to send to PC
    end
    if (IF_Rx_ctrl_0[7:1] == 7'b0001_001)
    begin
	  IF_Drive_Level	  <= IF_Rx_ctrl_1;	    	// decode drive level 
	  IF_Mic_boost		  <= IF_Rx_ctrl_2[0];   	// decode mic boost 0 = 0dB, 1 = 20dB  
	  IF_Line_In		  <= IF_Rx_ctrl_2[1];		// 0 = Mic input, 1 = Line In
	  IF_Filter			  <= IF_Rx_ctrl_2[2];		// 1 = enable Apollo filter
	  IF_Tuner			  <= IF_Rx_ctrl_2[3];		// 1 = enable Apollo tuner
	  IF_autoTune		  <= IF_Rx_ctrl_2[4];		// 1 = begin Apollo auto-tune
	  IF_Apollo         <= IF_Rx_ctrl_2[5];      // 1 = Apollo enabled, 0 = Alex enabled 
	  Alex_manual		  <= IF_Rx_ctrl_2[6]; 	  	// manual Alex HPF/LPF filter selection (0 = disable, 1 = enable)
	  VNA					  <= IF_Rx_ctrl_2[7];		// 1 = enable VNA mode
	  Alex_manual_HPF	  <= IF_Rx_ctrl_3[5:0];		// Alex HPF filters select
	  Alex_6m_preamp	  <= IF_Rx_ctrl_3[6];		// 6M low noise amplifier (0 = disable, 1 = enable)
	  TR_relay_disable  <= IF_Rx_ctrl_3[7];		// Alex T/R relay disable option (0=TR relay enabled, 1=TR relay disabled)
	  Alex_manual_LPF	  <= IF_Rx_ctrl_4[6:0];		// Alex LPF filters select	  
	end
	if (IF_Rx_ctrl_0[7:1] == 7'b0001_010)
	begin
	  IF_Line_In_Gain   <= IF_Rx_ctrl_2[4:0];		// decode line-in gain setting
	  Hermes_atten      <= IF_Rx_ctrl_4[4:0];    // decode input attenuation setting
	  Hermes_atten_enable <= IF_Rx_ctrl_4[5];    // decode Hermes attenuator enable/disable
	end
  end
end	

always @ (posedge IF_clk)
begin 
  if (IF_rst)
  begin // set up default values - 0 for now
    IF_frequency[0]    <= 32'd0;
    IF_frequency[1]    <= 32'd0;
    IF_frequency[2]    <= 32'd0;
    IF_frequency[3]    <= 32'd0;
    IF_frequency[4]    <= 32'd0;
    IF_frequency[5]    <= 32'd0;
  end
  else if (IF_Rx_save)
  begin
      if (IF_Rx_ctrl_0[7:1] == 7'b0000_001)   // decode IF_frequency[0]
      begin
		  IF_frequency[0]   <= {IF_Rx_ctrl_1, IF_Rx_ctrl_2, IF_Rx_ctrl_3, IF_Rx_ctrl_4}; // Tx frequency
			if (!IF_duplex && (IF_last_chan == 3'b000))
				IF_frequency[1] <= IF_frequency[0]; //				  
		end
		if (IF_Rx_ctrl_0[7:1] == 7'b0000_010) // decode Rx1 frequency
      begin
			if (!IF_duplex && (IF_last_chan == 3'b000)) // Rx1 frequency
			begin
				IF_frequency[1] <= IF_frequency[0];
			end				  
         else
         	begin
				IF_frequency[1] <= {IF_Rx_ctrl_1, IF_Rx_ctrl_2, IF_Rx_ctrl_3, IF_Rx_ctrl_4}; 
			end
		end

		if (IF_Rx_ctrl_0[7:1] == 7'b0000_011) begin // decode Rx2 frequency
			if (IF_last_chan >= 3'b001) IF_frequency[2] <= {IF_Rx_ctrl_1, IF_Rx_ctrl_2, IF_Rx_ctrl_3, IF_Rx_ctrl_4};  // Rx2 frequency
			else IF_frequency[2] <= IF_frequency[0];  
		end 

		if (IF_Rx_ctrl_0[7:1] == 7'b0000_100) begin // decode Rx3 frequency
			if (IF_last_chan >= 3'b010) IF_frequency[3] <= {IF_Rx_ctrl_1, IF_Rx_ctrl_2, IF_Rx_ctrl_3, IF_Rx_ctrl_4};  // Rx3 frequency
			else IF_frequency[3] <= IF_frequency[0];  
		end 

		 if (IF_Rx_ctrl_0[7:1] == 7'b0000_101) begin // decode Rx4 frequency
			if (IF_last_chan >= 3'b011) IF_frequency[4] <= {IF_Rx_ctrl_1, IF_Rx_ctrl_2, IF_Rx_ctrl_3, IF_Rx_ctrl_4};  // Rx4 frequency
			else IF_frequency[4] <= IF_frequency[0];  
		end 

		 if (IF_Rx_ctrl_0[7:1] == 7'b0000_110) begin // decode Rx5 frequency
			if (IF_last_chan >= 3'b100) IF_frequency[5] <= {IF_Rx_ctrl_1, IF_Rx_ctrl_2, IF_Rx_ctrl_3, IF_Rx_ctrl_4};  // Rx5 frequency
			else IF_frequency[5] <= IF_frequency[0];  
		end 
		 
		 
//--------------------------------------------------------------------------------------------------------
 end
end

assign FPGA_PTT = IF_Rx_ctrl_0[0]; // IF_Rx_ctrl_0 only updated when we get correct sync sequence


//------------------------------------------------------------
//  Attenuator 
//------------------------------------------------------------

// set the attenuator according to whether Hermes_atten_enable and Preamp bits are set 
//wire [4:0] atten_data;

wire ad9866rqst;
wire [15:0] ad9866data;


assign ad9866rqst = 1'b0;
assign ad9866data = 16'h00;

// Hack to use IF_DITHER to switch highest bit of attenuation
assign ad9866_pga = {~IF_DITHER, ~Hermes_atten};


//---------------------------------------------------------
//   State Machine to manage PWM interface
//---------------------------------------------------------
/*

    The code loops until there are at least 4 words in the Rx_FIFO.

    The first word is the Left audio followed by the Right audio
    which is followed by I data and finally the Q data.
    	
    The words sent to the D/A converters must be sent at the sample rate
    of the A/D converters (48kHz) so is synced to the negative edge of the CLRCLK (via IF_get_rx_data).
*/

reg   [2:0] IF_PWM_state;      // state for PWM
reg   [2:0] IF_PWM_state_next; // next state for PWM
//reg  [15:0] IF_Left_Data;      // Left 16 bit PWM data for D/A converter
//reg  [15:0] IF_Right_Data;     // Right 16 bit PWM data for D/A converter
reg  [15:0] IF_I_PWM;          // I 16 bit PWM data for D/A conveter
reg  [15:0] IF_Q_PWM;          // Q 16 bit PWM data for D/A conveter
wire        IF_get_samples;
wire        IF_get_rx_data;

assign IF_get_rx_data = IF_get_samples;

localparam PWM_IDLE     = 0,
           PWM_START    = 1,
           PWM_LEFT     = 2,
           PWM_RIGHT    = 3,
           PWM_I_AUDIO  = 4,
           PWM_Q_AUDIO  = 5;

always @ (posedge IF_clk) 
begin
  if (IF_rst)
    IF_PWM_state   <= #IF_TPD PWM_IDLE;
  else
    IF_PWM_state   <= #IF_TPD IF_PWM_state_next;

  // get Left audio
//  if (IF_PWM_state == PWM_LEFT)
//    IF_Left_Data   <= #IF_TPD IF_Rx_fifo_rdata;

  // get Right audio
//  if (IF_PWM_state == PWM_RIGHT)
//    IF_Right_Data  <= #IF_TPD IF_Rx_fifo_rdata;

  // get I audio
  if (IF_PWM_state == PWM_I_AUDIO)
    IF_I_PWM       <= #IF_TPD IF_Rx_fifo_rdata;

  // get Q audio
  if (IF_PWM_state == PWM_Q_AUDIO)
    IF_Q_PWM       <= #IF_TPD IF_Rx_fifo_rdata;

end

always @*
begin
  case (IF_PWM_state)
    PWM_IDLE:
    begin
      IF_Rx_fifo_rreq = 1'b0;

      if (!IF_get_rx_data  || RX_USED[RFSZ:2] == 1'b0 ) // RX_USED < 4
        IF_PWM_state_next = PWM_IDLE;    // wait until time to get the donuts every 48kHz from oven (RX_FIFO)
      else
        IF_PWM_state_next = PWM_START;   // ah! now it's time to get the donuts
    end

    // Start packaging the donuts
    PWM_START:
    begin
      IF_Rx_fifo_rreq    = 1'b1;
      IF_PWM_state_next  = PWM_LEFT;
    end

    // get Left audio
    PWM_LEFT:
    begin
      IF_Rx_fifo_rreq    = 1'b1;
      IF_PWM_state_next  = PWM_RIGHT;
    end

    // get Right audio
    PWM_RIGHT:
    begin
      IF_Rx_fifo_rreq    = 1'b1;
      IF_PWM_state_next  = PWM_I_AUDIO;
    end

    // get I audio
   PWM_I_AUDIO:
    begin
      IF_Rx_fifo_rreq    = 1'b1;
      IF_PWM_state_next  = PWM_Q_AUDIO;
    end

    // get Q audio
    PWM_Q_AUDIO:
    begin
      IF_Rx_fifo_rreq    = 1'b0;
      IF_PWM_state_next  = PWM_IDLE; // truck has left the shipping dock
    end

   default:
    begin
      IF_Rx_fifo_rreq    = 1'b0;
      IF_PWM_state_next  = PWM_IDLE;
    end
  endcase
end

//---------------------------------------------------------
//  Debounce PTT input - active low
//---------------------------------------------------------

//debounce de_PTT(.clean_pb(clean_PTT_in), .pb(~PTT), .clk(IF_clk));
assign clean_PTT_in = 0;


//---------------------------------------------------------
//  Debounce dot key - active low
//---------------------------------------------------------

//debounce de_dot(.clean_pb(clean_dot), .pb(~KEY_DOT), .clk(IF_clk));
assign clean_dot = 0;

//---------------------------------------------------------
//  Debounce dash key - active low
//---------------------------------------------------------

//debounce de_dash(.clean_pb(clean_dash), .pb(~KEY_DASH), .clk(IF_clk));
assign clean_dash = 0;


// AD9866 Instance
ad9866 ad9866_inst(.reset(~ad9866_rst_n),.clk(ad9866spiclk),.sclk(ad9866_sclk),.sdio(ad9866_sdio),.sdo(ad9866_sdo),.sen_n(ad9866_sen_n),.dataout(),.extrqst(ad9866rqst),.extdata(ad9866data));


localparam half_second = 10000000; // at 48MHz clock rate

	
Led_flash Flash_LED0(.clock(C122_clk), .signal(ad9866clipp), .LED(leds[0]), .period(half_second));
Led_flash Flash_LED1(.clock(C122_clk), .signal(ad9866clipn), .LED(leds[1]), .period(half_second));

//Led_flash Flash_LED0(.clock(C122_clk), .signal(dacdclip[0]), .LED(leds[0]), .period(half_second));
//Led_flash Flash_LED1(.clock(C122_clk), .signal(dacdclip[1]), .LED(leds[1]), .period(half_second));
Led_flash Flash_LED2(.clock(C122_clk), .signal(dacdclip[2]), .LED(leds[2]), .period(half_second));
Led_flash Flash_LED3(.clock(C122_clk), .signal(dacdclip[3]), .LED(leds[3]), .period(half_second));
Led_flash Flash_LED4(.clock(C122_clk), .signal(dacdclip[4]), .LED(leds[4]), .period(half_second));	
Led_flash Flash_LED5(.clock(C122_clk), .signal(dacdclip[5]), .LED(leds[5]), .period(half_second));
Led_flash Flash_LED6(.clock(C122_clk), .signal(dacdclip[6]), .LED(leds[6]), .period(half_second));
//Led_flash Flash_LED7(.clock(C122_clk), .signal(dacdclip[7]), .LED(leds[7]), .period(half_second));		


reg [25:0] counter;

always @ (posedge C122_clk)
begin
	counter <= counter + 1;
end
assign leds[7] = counter[25];



reg [15:0] resetcounter;
always @ (posedge rstclk or negedge extreset)
	if (~extreset) resetcounter <= 16'h00;
	else if (~resetcounter[15]) resetcounter <= resetcounter + 16'h01;

assign ad9866_rst_n = resetcounter[15];



function integer clogb2;
input [31:0] depth;
begin
  for(clogb2=0; depth>0; clogb2=clogb2+1)
  depth = depth >> 1;
end
endfunction


endmodule 
