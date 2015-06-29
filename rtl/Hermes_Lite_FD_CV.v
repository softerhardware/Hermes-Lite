//
//  Hermes Lite Core Wrapper for BeMicro CV
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
// (C) Steve Haynal KF7O 2014
//

module Hermes_Lite(

	input exp_present,
	input AD9866clk,
	input clk,
 	input extreset,
	output [7:0] leds,
	output exp_ptt_n,
	output [6:0] userout,
	input [2:0] dipsw,

	// AD9866
	output [5:0] ad9866_pga,

	//inout [11:0] ad9866_adio,
	input [5:0] ad9866_rx,
	output [5:0] ad9866_tx,
	
	//output ad9866_rxen,
	input ad9866_rxsync,
	
	//output ad9866_clk,
	input ad9866_rxclk,
	
	//output ad9866_txen,
	output ad9866_txsync,

	//output ad9866_txclk,
	output ad9866_txquietn,

	output ad9866_sclk,
    output ad9866_sdio,
    input  ad9866_sdo,
    output ad9866_sen_n,
    output ad9866_rst_n,
    output ad9866_mode,
   
    // RMII Ethernet PHY
(* useioff = 1 *)     output [1:0] rmii_tx,
	output rmii_tx_en,
(* useioff = 1 *)     input [1:0] rmii_rx,
    input rmii_osc,
	input rmii_crs_dv,
    inout PHY_MDIO,
    output PHY_MDC,

	//12 bit adc's (ADC78H90CIMT)
	output ADCMOSI,                
	output ADCCLK,
 	input  ADCMISO,
	output nADCCS
);

// PARAMETERS

// Ethernet Interface
// 5c release, 4a testing
parameter MAC = {8'h00,8'h1c,8'hc0,8'ha2,8'h22,8'h5c};
parameter IP = {8'd0,8'd0,8'd0,8'd0};
//parameter IP = {8'd192,8'd168,8'd33,8'd241};

// Clock Frequency
//parameter CLK_FREQ = 61440000;
parameter CLK_FREQ = 73728000;

// Number of Receivers
parameter NR = 2; // number of receivers to implement



// Clocks
wire IF_clk;
wire slowclk;
wire testAD9866clk;
wire AD9866clkX1;
wire IF_locked;
ifclocks_cv ifclocks_cv_inst(
	.refclk(clk),
	.rst(1'b0),
	.outclk_0(IF_clk),
	.outclk_1(testAD9866clk),
	.outclk_2(slowclk),
	.locked(IF_locked)
	);

// RMII2MII Conversion
wire [3:0] PHY_TX;
wire PHY_TX_EN;              //PHY Tx enable
reg PHY_TX_CLOCK;           //PHY Tx data clock
wire [3:0] PHY_RX;     
wire RX_DV;                  //PHY has data flag
reg PHY_RX_CLOCK;           //PHY Rx data clock
wire PHY_RESET_N;

RMII2MII_rev2 RMII2MII_inst(
	.clk(rmii_osc),
	.resetn(1'b1),
	.phy_RXD(rmii_rx),
	.phy_CRS(rmii_crs_dv),
	.mac_RXD(PHY_RX),
	.mac_RX_CLK(PHY_RX_CLOCK),
	.mac_RX_DV(RX_DV),
	.mac_TXD(PHY_TX),
	.mac_TX_EN(PHY_TX_EN),
	.phy_TXD(rmii_tx),
	.phy_TX_EN(rmii_tx_en),
	.mac_TX_CLK(PHY_TX_CLOCK),
	.mac_MDC_in(),
	.phy_MDC_out(),
	.mac_MDO_oen(),
	.mac_MDO_in(),
	.phy_MDIO(),
	.mac_MDI_out(),
	.phy_resetn()
);


// PLL clk must me on input 2 or 3
clkmux_cv clkmux (
	.inclk0x(AD9866clk),
	.inclk1x(AD9866clk),
	.inclk2x(testAD9866clk),
	.clkselect({~exp_present,1'b0}),
	.outclk(AD9866clkX1)
);

// Hermes Lite Core
hermes_lite_core #(
	.MAC(MAC),
	.IP(IP),
	.CLK_FREQ(CLK_FREQ),
	.NR(NR)
	) 

	hermes_lite_core_inst(
	.exp_present(exp_present),
	.AD9866clkX1(AD9866clkX1),

	.IF_clk(IF_clk),
	.ad9866spiclk(IF_clk),
	.rstclk(slowclk),
	.EEPROM_clock(slowclk),
	.IF_locked(IF_locked),

 	.extreset(extreset),
	.leds(leds), 
	.exp_ptt_n(exp_ptt_n),
	.userout(userout),
	.dipsw(dipsw),

	// AD9866
	.ad9866_pga(ad9866_pga),
	//.ad9866_adio(ad9866_adio),
	.ad9866_tx(ad9866_tx),
	.ad9866_rx(ad9866_rx),
	.ad9866_rxsync(ad9866_rxsync),
	.ad9866_rxclk(ad9866_rxclk),
	.ad9866_txsync(ad9866_txsync),
	.ad9866_txquietn(ad9866_txquietn),
	.ad9866_sclk(ad9866_sclk),
    .ad9866_sdio(ad9866_sdio),
    .ad9866_sdo(ad9866_sdo),
    .ad9866_sen_n(ad9866_sen_n),
    .ad9866_rst_n(ad9866_rst_n),
   	.ad9866_mode(ad9866_mode),
   
    // MMI Ethernet PHY
  	.PHY_TX(PHY_TX),
  	.PHY_TX_EN(PHY_TX_EN),        
  	.PHY_TX_CLOCK(PHY_TX_CLOCK),
  	.PHY_RX(PHY_RX),     
  	.RX_DV(RX_DV),
  	.PHY_RX_CLOCK(PHY_RX_CLOCK),         
  	.PHY_RESET_N(PHY_RESET_N),
	.PHY_MDIO(PHY_MDIO),             
	.PHY_MDC(PHY_MDC),

	//12 bit adc's (ADC78H90CIMT)
	.ADCMOSI(ADCMOSI),                
	.ADCCLK(ADCCLK),
 	.ADCMISO(ADCMISO),
	.nADCCS(nADCCS)	
);             

//reg clkcheck;
//always @(negedge rmii_osc)
//	clkcheck <= PHY_TX_CLOCK ^ PHY_RX_CLOCK;

//assign leds = { ileds[7:1],~clkcheck };

endmodule 
