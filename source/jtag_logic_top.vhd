-------------------------------------------------------------------------------
-- Project   : USB-JTAG
-- File      : jtag_logic_top.vhd
-- Title     : JTAGロジックTOPソース
--------------------------------------------------------------------------------
--+-----+-----------+-----------------------------------------------------------
-- Ver   Date        Description
--+-----+-----------+-----------------------------------------------------------
-- 00.00 2019/06/13  Created
--+-----+-----------+-----------------------------------------------------------
-- 00.01 2019/06/26  Modified
--                    ・リセットコンローラ、LEDコントローラを追加
--+-----+-----------+-----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity jtag_logic_top is
  PORT
  (
    CLK : IN STD_LOGIC;        -- external 24/25 MHz oscillator
    nRXF : IN STD_LOGIC;       -- FT245BM nRXF
    nTXE : IN STD_LOGIC;       -- FT245BM nTXE
    B_TDO  : IN STD_LOGIC;     -- JTAG input: TDO, AS/PS input: CONF_DONE
    B_ASDO : IN STD_LOGIC;     -- AS input: DATAOUT, PS input: nSTATUS
    B_TCK  : BUFFER STD_LOGIC; -- JTAG output: TCK to chain, AS/PS DCLK
    B_TMS  : BUFFER STD_LOGIC; -- JTAG output: TMS to chain, AS/PS nCONFIG
    B_NCE  : BUFFER STD_LOGIC; -- AS output: nCE
    B_NCS  : BUFFER STD_LOGIC; -- AS output: nCS
    B_TDI  : BUFFER STD_LOGIC; -- JTAG output: TDI to chain, AS: ASDI, PS: DATA0
    B_OE   : BUFFER STD_LOGIC; -- LED output/output driver enable 
    nRD : OUT STD_LOGIC;       -- FT245BM nRD
    WR : OUT STD_LOGIC;        -- FT245BM WR
    D : INOUT STD_LOGIC_VECTOR(7 downto 0);-- FT245BM D[7..0]
    conf_done_i   : in  std_logic; -- Config Done             -- 2019/06/26 追加
    rst_o         : out std_logic; -- Reset Output            -- 2019/06/26 追加
    led_o         : out std_logic  -- LED Output              -- 2019/06/26 追加
  );
end jtag_logic_top;

architecture rtl of jtag_logic_top is
------------------------------------------------------------
-- コンポーネント宣言
------------------------------------------------------------
-- JTAG Logic
component jtag_logic
	PORT
	(
		CLK : IN STD_LOGIC;        -- external 24/25 MHz oscillator
		nRXF : IN STD_LOGIC;       -- FT245BM nRXF
		nTXE : IN STD_LOGIC;       -- FT245BM nTXE
		B_TDO  : IN STD_LOGIC;     -- JTAG input: TDO, AS/PS input: CONF_DONE
		B_ASDO : IN STD_LOGIC;     -- AS input: DATAOUT, PS input: nSTATUS
		B_TCK  : BUFFER STD_LOGIC; -- JTAG output: TCK to chain, AS/PS DCLK
		B_TMS  : BUFFER STD_LOGIC; -- JTAG output: TMS to chain, AS/PS nCONFIG
		B_NCE  : BUFFER STD_LOGIC; -- AS output: nCE
		B_NCS  : BUFFER STD_LOGIC; -- AS output: nCS
		B_TDI  : BUFFER STD_LOGIC; -- JTAG output: TDI to chain, AS: ASDI, PS: DATA0
		B_OE   : BUFFER STD_LOGIC; -- LED output/output driver enable 
		nRD : OUT STD_LOGIC;       -- FT245BM nRD
		WR : OUT STD_LOGIC;        -- FT245BM WR
		D : INOUT STD_LOGIC_VECTOR(7 downto 0) -- FT245BM D[7..0]
	);
END component;

-- PLL
component pll
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
END component;

-- 2019/06/26 追加
-- リセットコントローラ
component reset_control
  PORT
  (
    clk       : in  std_logic;      -- 24MHz
    conf_done : in  std_logic;      -- CONF_DONE コンフィグ完了でLにアサートされる
    rst_o     : out std_logic       -- CONF_DONE Lにアサート後64msでリセット解除
  );
end component;

-- 2019/06/26 追加
-- LEDコントローラ
component led_control
  PORT
  (
    clk       : in  std_logic;      -- 24MHz
    rst_n     : in  std_logic;      -- リセット(負論理)
    led_o     : out std_logic       -- LED制御(正論理)
  );
end component;

------------------------------------------------------------
-- 変数宣言
------------------------------------------------------------
-- PLL 出力クロック
signal clk_pll          : std_logic;
-- リセット信号
signal rst_n            : std_logic;      -- 2019/06/26 追加


begin
-- JTAG Logic
u_jtag_logic_01: jtag_logic
port map(
    CLK       => clk_pll ,
    nRXF      => nRXF    ,
    nTXE      => nTXE    ,
    B_TDO     => B_TDO   ,
    B_ASDO    => B_ASDO  ,
    B_TCK     => B_TCK   ,
    B_TMS     => B_TMS   ,
    B_NCE     => B_NCE   ,
    B_NCS     => B_NCS   ,
    B_TDI     => B_TDI   ,
    B_OE      => B_OE    ,
    nRD       => nRD     ,
    WR        => WR      ,
    D         => D       
);
  
-- PLL
u_pll_01: pll
port map(
    areset		=> '0',
    inclk0		=> CLK,
    c0		    => clk_pll,
    locked		=> open
);

-- 2019/06/26 追加
-- リセットコントローラ
u_reset_control_01: reset_control
port map(
  clk         => clk_pll      , --: in  std_logic;      -- 24MHz
  conf_done   => conf_done_i  , --: in  std_logic;      -- CONF_DONE コンフィグ完了でLにアサートされる
  rst_o       => rst_n          --: out std_logic       -- CONF_DONE Lにアサート後64msでリセット解除
);

-- 2019/06/26 追加
-- LEDコントローラ
u_led_control_01: led_control
port map(
  clk         => clk_pll    , --: in  std_logic;      -- 24MHz
  rst_n       => rst_n      , --: in  std_logic;      -- リセット(負論理)
  led_o       => led_o        --: out std_logic       -- LED制御(正論理)
);


rst_o <= rst_n;

end rtl;
