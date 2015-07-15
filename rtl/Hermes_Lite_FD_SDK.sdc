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

create_clock -period 73.728MHz	  [get_ports AD9866clk]					-name AD9866clk
create_clock -period 50.000MHz 	  [get_ports clk50mhz]					-name clk50mhz
create_clock -period 25.000MHz	  [get_ports PHY_TX_CLOCK]				-name PHY_TX_CLOCK	
create_clock -period 25.000MHz    [get_ports PHY_RX_CLOCK] 				-name PHY_RX_CLOCK
create_clock -period 147.456MHz	  [get_ports ad9866_rxclk]				-name ad9866_rxclk

derive_pll_clocks 
derive_clock_uncertainty


#*************************************************************************************
# Create Generated ClocK
#*************************************************************************************
# internally generated clocks
#
create_generated_clock -divide_by 2 -source PHY_RX_CLOCK -name PHY_RX_CLOCK_2 {hermes_lite_core:hermes_lite_core_inst|PHY_RX_CLOCK_2}
create_generated_clock -divide_by 2 -source PHY_TX_CLOCK -name Tx_clock_2 {hermes_lite_core:hermes_lite_core_inst|Tx_clock_2}
create_generated_clock -divide_by 20 -source AD9866clk -name BCLK {hermes_lite_core:hermes_lite_core_inst|Hermes_clk_lrclk_gen:clrgen|BCLK}



#*************************************************************************************
# Set Clock Groups
#*************************************************************************************


set_clock_groups -asynchronous -group { PHY_TX_CLOCK \
					Tx_clock_2 \
					PHY_RX_CLOCK \
					PHY_RX_CLOCK_2 \
					} \
					-group {ad9866_rxclk AD9866clk BCLK} \
					-group {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[0]} \
					-group {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[1]} \
					-group {PLL_IF_inst|altpll_component|auto_generated|pll1|clk[2]} 



## set input delays
create_clock -period 25.000MHz -name vrxclk

set_input_delay -add_delay -max -clock vrxclk 31.0 [get_ports {RX_DV}]
set_input_delay -add_delay -min -clock vrxclk 9.0 [get_ports {RX_DV}]

set_input_delay -add_delay -max -clock vrxclk 31.0 [get_ports {PHY_RX[*]}]
set_input_delay -add_delay -min -clock vrxclk 9.0 [get_ports {PHY_RX[*]}]


# set output delays
create_clock -period 25.000MHz -name vtxclk

set_output_delay -add_delay -max -clock vtxclk 10.0 [get_ports {PHY_TX_EN}]
set_output_delay -add_delay -min -clock vtxclk -2.0 [get_ports {PHY_TX_EN}]

set_output_delay -add_delay -max -clock vtxclk 10.0 [get_ports {PHY_TX[*]}]
set_output_delay -add_delay -min -clock vtxclk -2.0 [get_ports {PHY_TX[*]}]



## AD9866 RX Path

set_input_delay -add_delay -max -clock ad9866_rxclk 3.78 [get_ports {ad9866_rxsync}]
set_input_delay -add_delay -min -clock ad9866_rxclk 0.5 [get_ports {ad9866_rxsync}]

set_input_delay -add_delay -max -clock ad9866_rxclk 3.78 [get_ports {ad9866_rx[*]}]
set_input_delay -add_delay -min -clock ad9866_rxclk 0.5 [get_ports {ad9866_rx[*]}]


## AD9866 TX Path
## Adjust for PCB delays 

set_multicycle_path -to [get_ports {ad9866_txsync}] -setup -start 2
set_multicycle_path -to [get_ports {ad9866_txsync}] -hold -start 0

set_multicycle_path -to [get_ports {ad9866_tx[*]}] -setup -start 2
set_multicycle_path -to [get_ports {ad9866_tx[*]}] -hold -start 0

set_output_delay -add_delay -max -clock ad9866_rxclk 2.0 [get_ports {ad9866_txsync}]
set_output_delay -add_delay -min -clock ad9866_rxclk -0.3 [get_ports {ad9866_txsync}]

set_output_delay -add_delay -max -clock ad9866_rxclk 2.0 [get_ports {ad9866_tx[*]}]
set_output_delay -add_delay -min -clock ad9866_rxclk -0.3 [get_ports {ad9866_tx[*]}]


## Slow outputs
set_false_path -from * -to {leds[*] userout[*] exp_ptt_n}

## Slow inputs
set_false_path -from {extreset exp_present dipsw[*]} -to *
