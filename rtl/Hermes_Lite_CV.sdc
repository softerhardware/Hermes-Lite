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

create_clock -period 61.440MHz	  [get_ports AD9866clk]		-name AD9866clk
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
create_generated_clock -divide_by 2 -source {RMII2MII_rev2:RMII2MII_inst|rx_clk} -name PHY_RX_CLOCK_2 {hermes_lite_core:hermes_lite_core_inst|PHY_RX_CLOCK_2}
create_generated_clock -divide_by 2 -source {RMII2MII_rev2:RMII2MII_inst|tx_clk} -name Tx_clock_2 {hermes_lite_core:hermes_lite_core_inst|Tx_clock_2}


#*************************************************************************************
# Set Clock Groups
#*************************************************************************************


set_clock_groups -asynchronous -group {rmii_osc \
					PHY_TX_CLOCK \
					Tx_clock_2 \
					PHY_RX_CLOCK \
					PHY_RX_CLOCK_2 \
					} \
					-group {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[0]} \
					-group {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[1]} \
					-group {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[2]} \
					-group {AD9866clk} 


## set input delays
set_input_delay -clock { rmii_osc } 9 [get_ports {rmii_crs_dv}]
set_input_delay -clock { rmii_osc } 9 [get_ports {rmii_rx[*]}]


# set output delays
set_output_delay -clock { rmii_osc } 9.5 [get_ports {rmii_tx_en}]
set_output_delay -clock { rmii_osc } 9.5 [get_ports {rmii_tx[*]}] 
