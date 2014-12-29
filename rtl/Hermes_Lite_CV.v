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

	// AD9866
	output [5:0] ad9866_pga,
	inout [11:0] ad9866_adio,
	output ad9866_rxen,
	output ad9866_rxclk,
	output ad9866_txen,
	output ad9866_txclk,
	output ad9866_sclk,
    output ad9866_sdio,
    input  ad9866_sdo,
    output ad9866_sen_n,
    output ad9866_rst_n,
   
    // RMII Ethernet PHY
    output [1:0] rmii_tx,
    output rmii_tx_en,
    input [1:0] rmii_rx,
    input rmii_osc,
    input rmii_crs_dv,
    inout PHY_MDIO,
    output PHY_MDC
);

// PARAMETERS

// Ethernet Interface
parameter MAC = {8'h00,8'h1c,8'hc0,8'ha2,8'h22,8'h5c};
parameter IP = {8'd0,8'd0,8'd0,8'd0};

// ADC Oscillator
//61440000 or 73728000
parameter CLK_FREQ = 61440000;

// Number of Receivers
parameter NR = 2; // number of receivers to implement



// Clocks
wire IF_clk;
wire slowclk;
wire testAD9866clk;
wire iAD9866clk;
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
	.outclk(iAD9866clk)
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
	.AD9866clk(iAD9866clk),

	.IF_clk(IF_clk),
	.ad9866spiclk(IF_clk),
	.rstclk(slowclk),
	.EEPROM_clock(slowclk),
	.IF_locked(IF_locked),

 	.extreset(extreset),
	.leds(leds), 

	// AD9866
	.ad9866_pga(ad9866_pga),
	.ad9866_adio(ad9866_adio),
	.ad9866_rxen(ad9866_rxen),
	.ad9866_rxclk(ad9866_rxclk),
	.ad9866_txen(ad9866_txen),
	.ad9866_txclk(ad9866_txclk),
	.ad9866_sclk(ad9866_sclk),
    .ad9866_sdio(ad9866_sdio),
    .ad9866_sdo(ad9866_sdo),
    .ad9866_sen_n(ad9866_sen_n),
    .ad9866_rst_n(ad9866_rst_n),
   
    // MMI Ethernet PHY
  	.PHY_TX(PHY_TX),
  	.PHY_TX_EN(PHY_TX_EN),        
  	.PHY_TX_CLOCK(PHY_TX_CLOCK),
  	.PHY_RX(PHY_RX),     
  	.RX_DV(RX_DV),
  	.PHY_RX_CLOCK(PHY_RX_CLOCK),         
  	.PHY_RESET_N(PHY_RESET_N),
	.PHY_MDIO(PHY_MDIO),             
	.PHY_MDC(PHY_MDC)
);             

endmodule 
