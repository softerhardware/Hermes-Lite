# Hermes.sdc
#
#
#
#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3


#**************************************************************************************
# Create Clock
#**************************************************************************************
# externally generated clocks (with respect to the FPGA)
#

create_clock -period 61.440MHz	  [get_ports AD9866clk]					-name AD9866clk
create_clock -period 50.000MHz 	  [get_ports clk50mhz]					-name clk50mhz
create_clock -period 25.000MHz	  [get_ports PHY_TX_CLOCK]				-name PHY_TX_CLOCK	
create_clock -period 25.000MHz    [get_ports PHY_RX_CLOCK] 				-name PHY_RX_CLOCK


##derive_pll_clocks 


#*************************************************************************************
# Create Generated ClocK
#*************************************************************************************
# internally generated clocks
#
create_generated_clock -divide_by 2 -source PHY_RX_CLOCK -name PHY_RX_CLOCK_2 {hermes_lite_core:hermes_lite_core_inst|PHY_RX_CLOCK_2}
create_generated_clock -divide_by 2 -source PHY_TX_CLOCK -name Tx_clock_2 {hermes_lite_core:hermes_lite_core_inst|Tx_clock_2}

create_generated_clock -source {ad9866clk_sdk_inst|altpll_component|auto_generated|pll1|inclk[0]} -master_clock AD9866clk -divide_by 1 -multiply_by 1 -duty_cycle 50.00 -name AD9866clkX1 {ad9866clk_sdk_inst|altpll_component|auto_generated|pll1|clk[1]}

create_generated_clock -source {ad9866clk_sdk_inst|altpll_component|auto_generated|pll1|inclk[0]} -master_clock AD9866clk -divide_by 1 -multiply_by 2 -duty_cycle 50.00 -name AD9866clkX2 {ad9866clk_sdk_inst|altpll_component|auto_generated|pll1|clk[0]}

create_generated_clock -source {PLL_IF_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 230 -multiply_by 221 -duty_cycle 50.00 -name IF_clk  {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]}
    
create_generated_clock -source {PLL_IF_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 180 -multiply_by 221 -duty_cycle 50.00 -name testAD9866clk {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]}
    
create_generated_clock -source {PLL_IF_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 3710 -multiply_by 221 -duty_cycle 50.00 -name slowclk {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]}
 

derive_clock_uncertainty


#*************************************************************************************
# Set Clock Groups
#*************************************************************************************


set_clock_groups -asynchronous -group { PHY_TX_CLOCK \
					Tx_clock_2 \
					PHY_RX_CLOCK \
					PHY_RX_CLOCK_2 \
					} \
					-group { IF_clk } \
					-group { testAD9866clk } \
					-group { slowclk } \
					-group { AD9866clk } \
					-group { AD9866clkX1 AD9866clkX2 }


# set input delays
set_input_delay -clock { PHY_RX_CLOCK } 22 [get_ports {RX_DV}]
set_input_delay -clock { PHY_RX_CLOCK } 22 [get_ports {PHY_RX[*]}]


# set output delays
set_output_delay -clock { PHY_TX_CLOCK } 18 [get_ports {PHY_TX_EN}]
set_output_delay -clock { PHY_TX_CLOCK } 18 [get_ports {PHY_TX[*]}] 

