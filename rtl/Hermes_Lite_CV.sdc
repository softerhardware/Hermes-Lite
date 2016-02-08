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

##create_clock -period 79.872MHz	  [get_ports AD9866clk]		-name AD9866clk
##create_clock -period 73.728MHz	  [get_ports AD9866clk]		-name AD9866clk
create_clock -period 76.800MHz	  [get_ports AD9866clk]		-name AD9866clk
create_clock -period 50.000MHz	  [get_ports rmii_osc]		-name rmii_osc
create_clock -period 24.000MHz	  [get_ports clk]			-name clk

derive_pll_clocks -use_net_name
derive_clock_uncertainty


#*************************************************************************************
# Create Generated ClocK
#*************************************************************************************
# internally generated clocks
#
create_generated_clock -divide_by 2 -source [get_ports rmii_osc] -name PHY_RX_CLOCK {RMII2MII_rev2:RMII2MII_inst|rx_clk}
create_generated_clock -divide_by 2 -source [get_ports rmii_osc] -name PHY_TX_CLOCK {RMII2MII_rev2:RMII2MII_inst|tx_clk}
create_generated_clock -divide_by 2 -source {RMII2MII_rev2:RMII2MII_inst|rx_clk} -name PHY_RX_CLOCK_2 {hermes_lite_core:hermes_lite_core_inst|ethernet:ethernet_inst|PHY_RX_CLOCK_2}
create_generated_clock -divide_by 2 -source {RMII2MII_rev2:RMII2MII_inst|tx_clk} -name Tx_clock_2 {hermes_lite_core:hermes_lite_core_inst|ethernet:ethernet_inst|Tx_clock_2}
create_generated_clock -divide_by 20 -source AD9866clk -name BCLK {hermes_lite_core:hermes_lite_core_inst|Hermes_clk_lrclk_gen:clrgen|BCLK}


#*************************************************************************************
# Set Clock Groups
#*************************************************************************************


set_clock_groups -asynchronous -group {rmii_osc \
					PHY_TX_CLOCK \
					Tx_clock_2 \
					PHY_RX_CLOCK \
					PHY_RX_CLOCK_2 \
					} \
					-group {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[0] \
					ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[2]} \
					-group {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[1]} \
					-group {AD9866clk BCLK} 


## set input delays
create_clock -period 50.000MHz -name vrmii_osc

set_input_delay -add_delay -max -clock vrmii_osc 15.00 [get_ports {rmii_crs_dv}]
set_input_delay -add_delay -min -clock vrmii_osc 2.00 [get_ports {rmii_crs_dv}]

set_input_delay -add_delay -max -clock vrmii_osc 15.00 [get_ports {rmii_rx[*]}]
set_input_delay -add_delay -min -clock vrmii_osc 2.00 [get_ports {rmii_rx[*]}]

# set output delays
set_output_delay -add_delay -max -clock vrmii_osc 6.0 [get_ports {rmii_tx_en}]
set_output_delay -add_delay -min -clock vrmii_osc -5.5 [get_ports {rmii_tx_en}]

set_output_delay -add_delay -max -clock vrmii_osc 6.0 [get_ports {rmii_tx[*]}]
set_output_delay -add_delay -min -clock vrmii_osc -5.5 [get_ports {rmii_tx[*]}]



## AD9866 RX Path

#set_output_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] 1.5 [get_ports {ad9866_rxen}]
#set_output_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] -0.5 [get_ports {ad9866_rxen}]

#set_input_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] 1.5 [get_ports {ad9866_adio[*]}]
#set_input_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] -0.5 [get_ports {ad9866_adio[*]}]


## AD9866 TX Path


#set_output_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_txclk] 1.5 [get_ports {ad9866_txen}]
#set_output_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_txclk] -0.5 [get_ports {ad9866_txen}]

#set_output_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_txclk] 1.5 [get_ports {ad9866_adio[*]}]
#set_output_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_txclk] -0.5 [get_ports {ad9866_adio[*]}]


## Slow outputs
#set_false_path -from * -to {leds[*] userout[*] exp_ptt_n}

## Slow inputs
#set_false_path -from {extreset exp_present dipsw[*]} -to *

set_max_delay -from PHY_RX_CLOCK_2 -to Tx_clock_2 20
set_max_delay -from PHY_RX_CLOCK -to Tx_clock_2 20
set_max_delay -from Tx_clock_2 -to PHY_RX_CLOCK_2 20
set_max_delay -from PHY_TX_CLOCK -to PHY_RX_CLOCK_2 20

#set_min_delay -from PHY_RX_CLOCK_2 -to Tx_clock_2 1
#set_min_delay -from PHY_RX_CLOCK -to Tx_clock_2 1
#set_min_delay -from Tx_clock_2 -to PHY_RX_CLOCK_2 1
#set_min_delay -from PHY_TX_CLOCK -to PHY_RX_CLOCK_2 1