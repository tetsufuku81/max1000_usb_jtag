-------------------------------------------------------------------------------
-- Project   : USB-JTAG
-- File      : led_control.vhd
-- Title     : JTAGロジック LEDコントローラ
--------------------------------------------------------------------------------
--+-----+-----------+-----------------------------------------------------------
-- Ver   Date        Description
--+-----+-----------+-----------------------------------------------------------
-- 00.00 2019/06/26  Created
--+-----+-----------+-----------------------------------------------------------
-- 00.01 2019/06/30  Modified
--                    LED輝度調整のためにPWM機能を追加
--+-----+-----------+-----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity led_control is
  PORT
  (
    clk       : in  std_logic;      -- 24MHz
    rst_n     : in  std_logic;      -- リセット(負論理)
    led_o     : out std_logic       -- LED制御(正論理)
  );
end led_control;


architecture rtl of led_control is
------------------------------------------------------------
-- 変数宣言
------------------------------------------------------------
-- カウンタ
signal count_100us          : std_logic_vector(11 downto 0);
signal count_1s             : std_logic_vector(13 downto 0);
signal led                  : std_logic;

-- PWM制御    -- 2019/06/30 追加
signal pwm_cnt_cycle        : std_logic_vector(17 downto 0);
signal pwm_h                : std_logic;


begin


------------------------------------------------------------
-- PWM制御
-- 2019/06/30 追加
------------------------------------------------------------
-- 1周期カウント
process (rst_n, clk)
begin
if (rst_n = '0') then
  pwm_cnt_cycle <= (others => '0');
  
elsif (clk'event and clk = '1') then
  if (pwm_cnt_cycle = "111010100101111111") then
    pwm_cnt_cycle <= (others => '0');
  else
    pwm_cnt_cycle <= pwm_cnt_cycle + 1;
  end if;
  
end if;
end process;

-- H期間カウント
process (rst_n, clk)
begin
if (rst_n = '0') then
  pwm_h <= '0';
  
elsif (clk'event and clk = '1') then
  if (pwm_cnt_cycle <= "00" & "1011101101111111") then
    pwm_h <= '1';
  else
    pwm_h <= '0';
  end if;
  
end if;
end process;


------------------------------------------------------------
-- 100usカウンタ
------------------------------------------------------------
process (rst_n, clk)
begin
if (rst_n = '0') then
  count_100us <= (others => '0');
  
elsif (clk'event and clk = '1') then
  if (count_100us = "100101011111") then
    count_100us <= (others => '0');
  else
    count_100us <= count_100us + 1;
  end if;
  
end if;
end process;


------------------------------------------------------------
-- 1sカウンタ
------------------------------------------------------------
process (rst_n, clk)
begin
if (rst_n = '0') then
  count_1s <= (others => '0');
  
elsif (clk'event and clk = '1') then
  if (count_100us = "100101011111") then
  
    if (count_1s = "10011100001111") then
      count_1s <= (others => '0');
    else
      count_1s <= count_1s + 1;
    end if;
    
  end if;
end if;
end process;


------------------------------------------------------------
-- LED制御
------------------------------------------------------------
process (rst_n, clk)
begin
if (rst_n = '0') then
  led <= '0';
elsif (clk'event and clk = '1') then
  if (count_100us = "100101011111") then
    if (count_1s = "10011100001111") then
      led <= not led;
    end if;
  end if;
end if;
end process;


------------------------------------------------------------
-- 出力FF
------------------------------------------------------------
process (rst_n, clk)
begin
if (rst_n = '0') then
  led_o <= '0';
  
elsif (clk'event and clk = '1') then
  led_o <= led and pwm_h;                 -- 2019/06/30 PWM追加
  
end if;
end process;


end rtl;
