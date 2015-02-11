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


derive_pll_clocks 
derive_clock_uncertainty


#*************************************************************************************
# Create Generated ClocK
#*************************************************************************************
# internally generated clocks
#
create_generated_clock -divide_by 2 -source PHY_RX_CLOCK -name PHY_RX_CLOCK_2 {hermes_lite_core:hermes_lite_core_inst|PHY_RX_CLOCK_2}
create_generated_clock -divide_by 2 -source PHY_TX_CLOCK -name Tx_clock_2 {hermes_lite_core:hermes_lite_core_inst|Tx_clock_2}


#*************************************************************************************
# Set Clock Groups
#*************************************************************************************


set_clock_groups -asynchronous -group { PHY_TX_CLOCK \
					Tx_clock_2 \
					PHY_RX_CLOCK \
					PHY_RX_CLOCK_2 \
					} \
					-group {AD9866clk} \
					-group {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]} \
					-group {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]} \
					-group {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]} 



# set input delays
set_input_delay -clock { PHY_RX_CLOCK } 22 [get_ports {RX_DV}]
set_input_delay -clock { PHY_RX_CLOCK } 22 [get_ports {PHY_RX[*]}]


# set output delays
set_output_delay -clock { PHY_TX_CLOCK } 18 [get_ports {PHY_TX_EN}]
set_output_delay -clock { PHY_TX_CLOCK } 18 [get_ports {PHY_TX[*]}] 


## AD9866 RX Path

set_output_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] 1.5 [get_ports {ad9866_rxen}]
set_output_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] -0.5 [get_ports {ad9866_rxen}]

set_input_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] 1.5 [get_ports {ad9866_adio[*]}]
set_input_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] -0.5 [get_ports {ad9866_adio[*]}]


## AD9866 TX Path


set_output_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_txclk] 1.5 [get_ports {ad9866_txen}]
set_output_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_txclk] -0.5 [get_ports {ad9866_txen}]

set_output_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_txclk] 1.5 [get_ports {ad9866_adio[*]}]
set_output_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_txclk] -0.5 [get_ports {ad9866_adio[*]}]

