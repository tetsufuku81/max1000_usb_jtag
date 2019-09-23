-------------------------------------------------------------------------------
-- Project   : USB-JTAG
-- File      : reset_control.vhd
-- Title     : JTAGロジック リセットコントローラ
--------------------------------------------------------------------------------
--+-----+-----------+-----------------------------------------------------------
-- Ver   Date        Description
--+-----+-----------+-----------------------------------------------------------
-- 00.00 2019/06/26  Created
--+-----+-----------+-----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity reset_control is
  PORT
  (
    clk       : in  std_logic;      -- 24MHz
    conf_done : in  std_logic;      -- CONF_DONE コンフィグ完了でLにアサートされる
    rst_o     : out std_logic       -- CONF_DONE Lにアサート後64msでリセット解除
  );
end reset_control;


architecture rtl of reset_control is
------------------------------------------------------------
-- 変数宣言
------------------------------------------------------------
-- カウンタ
signal count_100us          : std_logic_vector(11 downto 0);
signal count_ms             : std_logic_vector(9 downto 0);   
signal rst                  : std_logic;


begin


------------------------------------------------------------
-- 100usカウンタ
------------------------------------------------------------
process (conf_done, clk)
begin
if (conf_done = '0') then
  count_100us <= (others => '0');
  
elsif (clk'event and clk = '1') then
  if (rst = '0') then
    if (count_100us = "100101011111") then
      count_100us <= (others => '0');
    else
      count_100us <= count_100us + 1;
    end if;
  end if;
end if;
end process;


------------------------------------------------------------
-- 64msカウンタ
------------------------------------------------------------
process (conf_done, clk)
begin
if (conf_done = '0') then
  count_ms <= (others => '0');
  
elsif (clk'event and clk = '1') then
  if (count_100us = "100101011111" and count_ms <= "1001111111") then
    count_ms <= count_ms + 1;
  end if;
  
end if;
end process;


------------------------------------------------------------
-- リセット信号生成
------------------------------------------------------------
process (conf_done, clk)
begin
if (conf_done = '0') then
  rst <= '0';
  
elsif (clk'event and clk = '1') then
  if (count_ms = "1001111111") then
    rst <= '1';
  end if;
  
end if;
end process;


------------------------------------------------------------
-- 出力FF
------------------------------------------------------------
process (conf_done, clk)
begin
if (conf_done = '0') then
  rst_o <= '0';
  
elsif (clk'event and clk = '1') then
  rst_o <= rst;
  
end if;
end process;


end rtl;
