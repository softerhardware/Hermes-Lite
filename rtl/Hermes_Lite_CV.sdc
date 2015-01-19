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

##derive_pll_clocks -use_net_name

#*************************************************************************************
# Create Generated ClocK
#*************************************************************************************
# internally generated clocks
#
create_generated_clock -divide_by 2 -source [get_ports rmii_osc] -name PHY_RX_CLOCK {RMII2MII_rev2:RMII2MII_inst|rx_clk}
create_generated_clock -divide_by 2 -source [get_ports rmii_osc] -name PHY_TX_CLOCK {RMII2MII_rev2:RMII2MII_inst|tx_clk}
create_generated_clock -divide_by 2 -source {RMII2MII_rev2:RMII2MII_inst|rx_clk} -name PHY_RX_CLOCK_2 {hermes_lite_core:hermes_lite_core_inst|PHY_RX_CLOCK_2}
create_generated_clock -divide_by 2 -source {RMII2MII_rev2:RMII2MII_inst|tx_clk} -name Tx_clock_2 {hermes_lite_core:hermes_lite_core_inst|Tx_clock_2}

create_generated_clock -source {ad9866clk_cv_inst|ad9866clk_cv_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|refclkin} -master_clock AD9866clk -divide_by 2 -multiply_by 12 -duty_cycle 50.00 -name {ad9866clk_cv_inst|ad9866clk_cv_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]} {ad9866clk_cv_inst|ad9866clk_cv_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}

create_generated_clock -source {ad9866clk_cv_inst|ad9866clk_cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 6 -duty_cycle 50.00 -name AD9866clkX1 {ad9866clk_cv_inst|ad9866clk_cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}

create_generated_clock -source {ad9866clk_cv_inst|ad9866clk_cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 3 -duty_cycle 50.00 -name AD9866clkX2 {ad9866clk_cv_inst|ad9866clk_cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}


create_generated_clock -source {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|refclkin} -divide_by 2 -multiply_by 92 -duty_cycle 50.00 -name {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]} {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}

create_generated_clock -source {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 23 -duty_cycle 50.00 -name IF_clk {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}

create_generated_clock -source {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 368 -duty_cycle 50.00 -name slowclk {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}

create_generated_clock -source {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|vco0ph[0]} -divide_by 18 -duty_cycle 50.00 -name testAD9866clk {ifclocks_cv_inst|ifclocks_cv_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}


derive_clock_uncertainty

#*************************************************************************************
# Set Clock Groups
#*************************************************************************************

set_clock_groups -asynchronous -group {rmii_osc \
					PHY_TX_CLOCK \
					Tx_clock_2 \
					PHY_RX_CLOCK \
					PHY_RX_CLOCK_2 \
					} \
					-group { IF_clk } \
					-group { testAD9866clk } \
					-group { slowclk } \
					-group { AD9866clk } \
					-group { AD9866clkX1 AD9866clkX2 }

## set input delays
set_input_delay -clock { rmii_osc } 9 [get_ports {rmii_crs_dv}]
set_input_delay -clock { rmii_osc } 9 [get_ports {rmii_rx[*]}]


# set output delays
set_output_delay -clock { rmii_osc } 7.5 [get_ports {rmii_tx_en}]
set_output_delay -clock { rmii_osc } 7.5 [get_ports {rmii_tx[*]}] 
