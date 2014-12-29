-- RMII<->MII translator


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;


ENTITY RMII2MII_rev2 IS
	PORT
	( 
		clk : IN STD_LOGIC;
		resetn : IN STD_LOGIC;
		phy_RXD : IN STD_LOGIC_VECTOR(1 downto 0);
		phy_CRS : IN STD_LOGIC;
		mac_RXD : OUT STD_LOGIC_VECTOR(3 downto 0);
		mac_RX_CLK : OUT STD_LOGIC;
		mac_RX_DV : OUT STD_LOGIC;
		mac_TXD : IN STD_LOGIC_VECTOR(3 downto 0);
		mac_TX_EN : IN STD_LOGIC;
		phy_TXD : OUT STD_LOGIC_VECTOR(1 downto 0);
		phy_TX_EN : OUT STD_LOGIC;
		mac_TX_CLK : OUT STD_LOGIC;
		
		mac_MDC_in 	: in std_logic;
		phy_MDC_out	: out std_logic;
		mac_MDO_oen	: in std_logic;
		mac_MDO_in 	: in std_logic;
		phy_MDIO	: inout std_logic;
		mac_MDI_out	: out std_logic;
		
		phy_resetn	: out std_logic
);
	
END RMII2MII_rev2;


ARCHITECTURE arch_RMII2MII_rev2 OF RMII2MII_rev2 IS

signal sreset : std_logic;
signal low_rxd_intern	: std_logic_vector(1 downto 0);	-- the lower output regs
signal out_rxd_intern	: std_logic_vector(3 downto 0);	-- the output regs

signal rx_clk	: std_logic;					-- the 25MHz Transmit clock
signal tx_clk	: std_logic;					-- the 25MHz internal Transmit clock

signal rxen		: std_logic;					-- the output
signal run		: std_logic;
signal run2		: std_logic;
signal txstat   : std_logic;

signal crs_intern	: std_logic;
signal crs_intern2	: std_logic;
signal rxd_intern	: std_logic_vector(1 downto 0);
signal rxd_intern2	: std_logic_vector(1 downto 0);

signal txd_intern : std_logic_vector(1 downto 0);	-- the output regs
signal txen		: std_logic;					-- the output

	
BEGIN

--generate the tri-state signal MDIO

p_mdio: process (mac_MDO_oen, mac_MDO_in)
begin
  if mac_MDO_oen='0' then
	phy_MDIO <= mac_MDO_in;
  else
    phy_MDIO <= 'Z';
  end if;
end process p_mdio; 

phy_MDC_out <= mac_MDC_in;
mac_MDI_out <= phy_MDIO;


--generating the receive signals
--and the rx_clk

p_reset: process(clk,resetn)
begin
	if rising_edge(clk) then
		sreset <= not resetn;
    end if;
end process p_reset;


p_in: process(clk,sreset)
begin
	if (sreset = '1') then
			crs_intern	<= '0';
			crs_intern2	<= '0';
			rxd_intern	<= "00";
			rxd_intern2	<= "00";
			phy_resetn	<= '0';
			-- phy_RXD		<= "00";
	elsif rising_edge(clk) then
			phy_resetn	<= '1';
			-- phy_RXD		<= "ZZ";
			crs_intern	<= phy_CRS;
			crs_intern2	<= crs_intern;
			rxd_intern	<= phy_RXD;
			rxd_intern2	<= rxd_intern;
	--else
	--	phy_RXD		<= "ZZ";
	end if; 
end process p_in;

mac_RX_DV	<= run2;

p_on: process(clk,sreset)
begin
	if (sreset = '1') then
		run		<= '0';
		run2	<= '0';
	elsif rising_edge(clk) then
		if (crs_intern = '0')and(crs_intern2 = '0')and(rx_clk = '0') then
			run	<= '0';
		elsif (crs_intern = '1')and(rxd_intern = "01") then
			run	<= '1';
		end if;
		if (rx_clk = '1') then
			run2	<= run;
		end if;
	end if;
end process p_on;


p_receive: process(clk,sreset)
begin
	if (sreset = '1') then
		rx_clk	<= '0';
		low_rxd_intern	<= "00";
		out_rxd_intern	<= "0000";
	elsif rising_edge(clk) then
	 -- generate 25Mhz rx_clk and the mac_rx_tx_clk
		if (run = '0')and(crs_intern = '1')and(rxd_intern = "01") then
			rx_clk 	<= '0';
		else
			rx_clk	<= not rx_clk;
		end if;

		if (rx_clk = '0') then	
			low_rxd_intern	<= rxd_intern2;
		end if;
		
		if (run = '0') then
			out_rxd_intern	<= "0000";
		else
			if (rx_clk = '1') then
				out_rxd_intern	<= rxd_intern2 & low_rxd_intern;
			end if;
		end if;
	end if;
		
end process p_receive;

mac_RXD		<= out_rxd_intern;
mac_RX_CLK	<= rx_clk;


--tranmit MAC->PHY
--an own clk is generated for transmitting

p_transmit: process(clk,sreset)
begin
	if (sreset = '1') then
		txd_intern	<= "00";
		txen   <= '0';
		tx_clk <= '0';
		txstat <= '0';
	elsif rising_edge(clk) then
		
		if (mac_TX_EN = '0') then
			txd_intern	<= "00";
			txen	<= '0';
			txstat <= '0';			
		else
			if (txstat = '0') then	-- mux the transmit-data
				txd_intern	<= mac_TXD(1 downto 0);
			else
				txd_intern	<= mac_TXD(3 downto 2);
			end if;
			txstat <= (not txstat);
			txen	<= '1';
		end if;

		tx_clk <= (not tx_clk);	-- generate the internal 25Mhz TX_CLK

	end if;
end process p_transmit;

phy_TXD		<= txd_intern;
phy_TX_EN	<= txen;
mac_TX_CLK	<= tx_clk;

END arch_RMII2MII_rev2;





