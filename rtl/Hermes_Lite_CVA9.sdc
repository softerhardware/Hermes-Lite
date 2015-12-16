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

create_clock -period 73.728MHz	  [get_ports AD9866clk]		-name AD9866clk
create_clock -period 24.000MHz	  [get_ports clk]			-name clk

create_clock -period 73.728MHz	[get_ports ad9866_rxclk] -name ad9866_rxclk
create_clock -period 73.728MHz  [get_ports ad9866_txclk] -name ad9866_txclk



#*************************************************************************************
# Create Generated Clock
#*************************************************************************************
# internally generated clocks
#


create_clock -name clk50mhz				-period 20.000 	[get_ports {clk50mhz}]
create_clock -name PHY_RX_CLOCK 		-period 8.000 	-waveform {2 6} [get_ports {PHY_RX_CLOCK}]

#virtual base clocks on required inputs
create_clock -name virt_PHY_RX_CLOCK 	-period 8.000

#derive_pll_clocks -use_net_name
#derive_clock_uncertainty

## pll clocks from derive_pll_clocks with better names

create_generated_clock -source {hermes_lite_core_inst|ethernet_inst|network_inst|rgmii_send_inst|phyclocks_inst|phyclocks_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|refclkin} -divide_by 2 -multiply_by 15 -duty_cycle 50.00 -name {hermes_lite_core:hermes_lite_core_inst|ethernet:ethernet_inst|network:network_inst|rgmii_send:rgmii_send_inst|phyclocks:phyclocks_inst|phyclocks_0002:phyclocks_inst|altera_pll:altera_pll_i|general[0].gpll~FRACTIONAL_PLL_O_VCOPH0} {hermes_lite_core_inst|ethernet_inst|network_inst|rgmii_send_inst|phyclocks_inst|phyclocks_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}
    
create_generated_clock -source {hermes_lite_core_inst|ethernet_inst|network_inst|rgmii_send_inst|phyclocks_inst|phyclocks_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 3 -duty_cycle 50.00 -name clock_125MHz {hermes_lite_core_inst|ethernet_inst|network_inst|rgmii_send_inst|phyclocks_inst|phyclocks_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}

create_generated_clock -source {hermes_lite_core_inst|ethernet_inst|network_inst|rgmii_send_inst|phyclocks_inst|phyclocks_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 3 -phase 90.00 -duty_cycle 50.00 -name clock_90_125MHz {hermes_lite_core_inst|ethernet_inst|network_inst|rgmii_send_inst|phyclocks_inst|phyclocks_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}
   
create_generated_clock -source {hermes_lite_core_inst|ethernet_inst|network_inst|rgmii_send_inst|phyclocks_inst|phyclocks_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 150 -duty_cycle 50.00 -name clock_2_5MHz {hermes_lite_core_inst|ethernet_inst|network_inst|rgmii_send_inst|phyclocks_inst|phyclocks_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|divclk}


    
create_generated_clock -source {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|refclkin} -divide_by 2 -multiply_by 36 -duty_cycle 50.00 -name {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|general[0].gpll~FRACTIONAL_PLL_O_VCOPH0} {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}
    
create_generated_clock -source {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 9 -duty_cycle 50.00 -name {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[0]} {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}
    
create_generated_clock -source {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 144 -duty_cycle 50.00 -name {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[2]} {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}
    
create_generated_clock -source {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 7 -duty_cycle 50.00 -name {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[1]} {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}




#**************************************************************
# Create Generated Clock (internal to the FPGA)
#**************************************************************
# NOTE: Whilst derive_pll_clocks constrains PLL clocks if these are connected to an FPGA output pin then a generated
# clock needs to be attached to the pin and a false path set to it

create_generated_clock -name tx_output_clock -source [get_pins {hermes_lite_core_inst|ethernet_inst|network_inst|rgmii_send_inst|phyclocks_inst|phyclocks_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] [get_ports {PHY_TX_CLOCK_out}]


create_generated_clock -divide_by 20 -source AD9866clk -name BCLK {hermes_lite_core:hermes_lite_core_inst|Hermes_clk_lrclk_gen:clrgen|BCLK}

derive_clock_uncertainty

#************************************************************** 
# Set Input Delay
#**************************************************************

# If setup and hold delays are equal then only need to specify once without max or min 

#PHY Data in 
set_input_delay  -max 0.8  -clock virt_PHY_RX_CLOCK [get_ports {PHY_RX[*] RX_DV}]
set_input_delay  -min -0.8 -clock virt_PHY_RX_CLOCK -add_delay [get_ports {PHY_RX[*] RX_DV}]
set_input_delay  -max 0.8 -clock virt_PHY_RX_CLOCK -clock_fall -add_delay [get_ports {PHY_RX[*] RX_DV}]
set_input_delay  -min -0.8 -clock virt_PHY_RX_CLOCK -clock_fall -add_delay [get_ports {PHY_RX[*] RX_DV}]


#PHY PHY_MDIO Data in +/- 10nS setup and hold
#set_input_delay  10  -clock clock_2_5MHz {PHY_INT_N}
set_input_delay  10  -clock clock_2_5MHz -reference_pin [get_ports PHY_MDC] {PHY_MDIO}


#**************************************************************
# Set Output Delay
#**************************************************************

# If setup and hold delays are equal then only need to specify once without max or min 

#PHY
set_output_delay  -max 1.0  -clock tx_output_clock [get_ports {PHY_TX[*] PHY_TX_EN}]
set_output_delay  -min -0.8 -clock tx_output_clock [get_ports {PHY_TX[*] PHY_TX_EN}]  -add_delay
set_output_delay  -max 1.0  -clock tx_output_clock [get_ports {PHY_TX[*] PHY_TX_EN}]  -clock_fall -add_delay
set_output_delay  -min -0.8 -clock tx_output_clock [get_ports {PHY_TX[*] PHY_TX_EN}]  -clock_fall -add_delay

#PHY (2.5MHz)
set_output_delay  10 -clock clock_2_5MHz -reference_pin [get_ports PHY_MDC] {PHY_MDIO}


#*************************************************************************************
# Set Clock Groups
#*************************************************************************************


set_clock_groups -asynchronous -group { \
					clock_125MHz \
					clock_90_125MHz \
					clock_2_5MHz \
					tx_output_clock \
				       } \
					-group {PHY_RX_CLOCK } \
					-group {clk50mhz } \
					-group {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[0] \
					ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[2]} \
					-group {ifclocks_cv:ifclocks_cv_inst|ifclocks_cv_0002:ifclocks_cv_inst|altera_pll:altera_pll_i|outclk_wire[1]} \
					-group {AD9866clk BCLK} \
					-group {clk}


#**************************************************************
# Set Maximum Delay
#************************************************************** 

set_max_delay -from clock_125MHz -to clock_125MHz 21
set_max_delay -from clock_125MHz -to tx_output_clock 3

set_max_delay -from clock_2_5MHz -to clock_125MHz 22 

#set_max_delay -from PHY_RX_CLOCK -to PHY_RX_CLOCK 10



#**************************************************************
# Set Minimum Delay
#**************************************************************

set_min_delay -from clock_90_125MHz -to tx_output_clock -2

#set_min_delay -from PHY_RX_CLOCK -to PHY_RX_CLOCK -4



#**************************************************************
# Set False Paths
#**************************************************************

# Set false path to generated clocks that feed output pins
set_false_path -to [get_ports {PHY_MDC}]

# Set false paths to remove irrelevant setup and hold analysis 
set_false_path -fall_from  virt_PHY_RX_CLOCK -rise_to PHY_RX_CLOCK -setup
set_false_path -rise_from  virt_PHY_RX_CLOCK -fall_to PHY_RX_CLOCK -setup
set_false_path -fall_from  virt_PHY_RX_CLOCK -fall_to PHY_RX_CLOCK -hold
set_false_path -rise_from  virt_PHY_RX_CLOCK -rise_to PHY_RX_CLOCK -hold

set_false_path -fall_from [get_clocks clock_125MHz] -rise_to [get_clocks tx_output_clock] -setup
set_false_path -rise_from [get_clocks clock_125MHz] -fall_to [get_clocks tx_output_clock] -setup
set_false_path -fall_from [get_clocks clock_125MHz] -fall_to [get_clocks tx_output_clock] -hold
set_false_path -rise_from [get_clocks clock_125MHz] -rise_to [get_clocks tx_output_clock] -hold




## AD9866 RX Path

## rxen is not time critical and is on 48 MHz clock
set_output_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] 1 [get_ports {ad9866_rxen}]
set_output_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] -2.5 [get_ports {ad9866_rxen}]
 
set_input_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] 4.0 [get_ports {ad9866_adio[*]}]
set_input_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_rxclk] 1.5 [get_ports {ad9866_adio[*]}]


## AD9866 TX Path

## txen is not time critical and is on 48 MHz clock
set_output_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_txclk] 1 [get_ports {ad9866_txen}]
set_output_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_txclk] -2.5 [get_ports {ad9866_txen}]

set_output_delay -add_delay -max -clock AD9866clk -reference_pin [get_ports ad9866_txclk] 1 [get_ports {ad9866_adio[*]}]
set_output_delay -add_delay -min -clock AD9866clk -reference_pin [get_ports ad9866_txclk] -2.5 [get_ports {ad9866_adio[*]}]
