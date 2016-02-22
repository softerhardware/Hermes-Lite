

module ethernet (
	input clk50mhz,
	// Send to ethernet
	output Tx_clock_2_o,
	output Tx_fifo_rdreq_o,
	input [7:0] PHY_Tx_data_i,
	input [10:0] PHY_Tx_rdused_i,

	input [7:0] sp_fifo_rddata_i,	
	input  sp_data_ready_i,
	output sp_fifo_rdreq_o,

	// Receive from ethernet
	output PHY_data_clock_o,
	output Rx_enable_o,
	output [7:0] Rx_fifo_data_o,

	// Status
	output this_MAC_o,
	output run_o,
	input IF_rst_i,
	output reset_o,
	input [1:0] dipsw_i,
	input [7:0] AssignNR,

    // MII Ethernet PHY
  	output [3:0] PHY_TX,
  	output PHY_TX_EN,              //PHY Tx enable
  	input  PHY_TX_CLOCK,           //PHY Tx data clock
  	output PHY_TX_CLOCK_out,
  	input  [3:0] PHY_RX,     
  	input  RX_DV,                  //PHY has data flag
  	input  PHY_RX_CLOCK,           //PHY Rx data clock
  	output PHY_RESET_N,  
    inout PHY_MDIO,
    output PHY_MDC
);

parameter MAC;
parameter IP;
parameter Hermes_serialno;

assign PHY_TX_CLOCK_out = 1'b0;

localparam read_reg_address = 5'h10; 	// PHY register to read from - gives connect speed and fully duplex	

wire sp_data_ready;
wire sp_fifo_rdreq;
wire [7:0] sp_fifo_rddata;
wire [7:0] PHY_Tx_data;

wire IF_rst;

wire [1:0] dipsw;
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

assign PHY_data_clock_o = PHY_data_clock;
assign Tx_clock_2_o = Tx_clock_2;

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
//reg read_MAC; 
wire MAC_ready;
reg DHCP_start;
reg [24:0]delay;
reg duplex;						// set when we are connected full duplex
//reg speed_100T;				// set when we are connected at 100MHz
reg Tx_reset;					// when set prevents HPSDR UDP/IP Tx data being sent
reg [2:0]DHCP_retries;		// DHCP retry counter
reg IP_valid;					// set when Metis has a valid IP address assigned by DHCP or APIPA
reg Assigned_IP_valid;		// set if IP address assigned by PC is not 0.0.0.0. or 255.255.255.255
reg use_IPIPA;					// set when no DHCP or assigned IP available so use APIAP
//reg read_IP_address;			// set when we wish to read IP address from EEPROM


always @ (posedge Tx_clock_2)
begin
	case (start_up)
	// get the MAC address for this board
0:	begin 
		IP_valid <= 1'b0;							// clear IP valid flag
		Assigned_IP_valid <= 1'b0;				// clear IP in flash memory valid
		reset <= 1'b1;
		Tx_reset <= 1'b1;							// prevent I&Q data Tx until all initialised 
		//read_MAC <= 1'b1;
		use_IPIPA <= 0;							// clear IPIPA flag
		start_up <= start_up + 1'b1;
	end
	// wait until we have read the EEPROM then the IP address
1:  begin
		if (MAC_ready) begin 					// MAC_ready goes high when EEPROM read
			//read_MAC <= 0;
			//read_IP_address <= 1'b1;						// set read IP flag
			start_up <= start_up + 1'b1;
		end
		else start_up <= 1'b1;
	end
	// read the IP address from EEPROM then set up the PHY
2:	begin
		if (IP_ready) begin
			//read_IP_address <= 0;
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
			//speed_100T <= 0;
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
			//speed_100T  <= register_data[1];
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
assign This_MAC = {MAC[47:2],~dipsw[1],MAC[0]};
assign AssignIP = IP;
assign MAC_ready = 1'b1;
assign IP_ready = 1'b1;

					
//------------------------------------------------------------------------------------
//  If DHCP provides an IP address for Metis use that else use a random APIPA address
//------------------------------------------------------------------------------------

// Use an APIPA address of 169.254.(last two bytes of the MAC address)

wire [31:0] This_IP;
wire [31:0]AssignIP;			// IP address read from EEPROM

assign This_IP =  Assigned_IP_valid ? AssignIP : 
				              use_IPIPA ? {8'd169, 8'd254, This_MAC[15:0]} : YIADDR;

//----------------------------------------------------------------------------------
// Read/Write the  PHY MDIO registers (NOTE: Max clock frequency is 25 MHz)
//----------------------------------------------------------------------------------
wire write_done; 
reg write_PHY;
reg read_PHY;
wire PHY_clock;
wire read_done;
wire [15:0]register_data; 
wire PHY_MDIO_clk;
assign PHY_MDIO_clk = Tx_clock_2; //EEPROM_clock;

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
// Below is to avoid multiplication, note that large lease times may lose msbs in shift
assign lease_time = (IP_lease == 0) ?  52'h7735_8C8C_A6C0 : IP_lease << 23; // (IP_lease >> 1) * 12500000; // 24 days if no lease time given
// assign lease_time = (IP_lease == 0) ? 52'h7735_8C8C_A6C0  : (52'd4 * 52'd12500000);  // every 4 seconds for testing


reg [24:0]IP_delay;
reg DHCP_renew;
reg [3:0]renew_DHCP_retries;
reg [51:0]renew_counter;
reg [24:0]renew_timer; 
reg [2:0]renew;
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
			        .wide_spectrum(wide_spectrum)
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
			        .run(run), .IP_valid(IP_valid),
			        .DHCP_MAC(DHCP_MAC), .DHCP_request_renew(DHCP_request_renew),
			        .Hermes_serialno(Hermes_serialno),
			        .sp_fifo_rddata(sp_fifo_rddata), .sp_fifo_rdreq(sp_fifo_rdreq), 
			        .sp_fifo_rdused(), .wide_spectrum(wide_spectrum), .have_sp_data(sp_data_ready),
					  .AssignIP(AssignIP), .IDHermesLite(dipsw[0]), .AssignNR(AssignNR)
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

assign Tx_fifo_rdreq_o = Tx_fifo_rdreq;
assign PHY_Tx_data = PHY_Tx_data_i;
assign PHY_Tx_rdused = PHY_Tx_rdused_i;

assign sp_fifo_rddata = sp_fifo_rddata_i;
assign sp_data_ready = sp_data_ready_i;


assign Rx_enable_o = Rx_enable;
assign Rx_fifo_data_o = Rx_fifo_data;

assign this_MAC_o = this_MAC;

assign run_o = run;
assign sp_fifo_rdreq_o = sp_fifo_rdreq;

assign IF_rst = IF_rst_i;
assign reset_o = reset;

assign dipsw = dipsw_i;

assign PHY_RESET_N = 1'b1;  						// Allow PYH to run for now

endmodule