-- -*- vhdl -*-
-------------------------------------------------------------------------------
-- Copyright (c) 2012, The CARPE Project, All rights reserved.               --
-- See the AUTHORS file for individual contributors.                         --
--                                                                           --
-- Copyright and related rights are licensed under the Solderpad             --
-- Hardware License, Version 0.51 (the "License"); you may not use this      --
-- file except in compliance with the License. You may obtain a copy of      --
-- the License at http://solderpad.org/licenses/SHL-0.51.                    --
--                                                                           --
-- Unless required by applicable law or agreed to in writing, software,      --
-- hardware and materials distributed under this License is distributed      --
-- on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,        --
-- either express or implied. See the License for the specific language      --
-- governing permissions and limitations under the License.                  --
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

architecture rtl of prioritizer_inferred is
begin

  input_bits_1 : if input_bits = 1 generate
    dataout <= datain;
  end generate;
  
  input_bits_2 : if input_bits = 2 generate
    dataout <= (others => 'X')    when is_x(datain(1)) else
               "10"               when datain(1) = '1' else
               "0X"               when is_x(datain(0)) else
               "01"               when datain(0) = '1' else
               (others => 'X');
  end generate;
  
  input_bits_3 : if input_bits = 3 generate
    dataout <= (others => 'X')    when is_x(datain(2)) else
               "100"              when datain(2) = '1' else
               "0XX"              when is_x(datain(1)) else
               "010"              when datain(1) = '1' else
               "00X"              when is_x(datain(0)) else
               "001"              when datain(0) = '1' else
               (others => 'X');
  end generate;
  
  input_bits_4 : if input_bits = 4 generate
    dataout <= (others => 'X')    when is_x(datain(3)) else
               "1000"             when datain(3) = '1' else
               "0XXX"             when is_x(datain(2)) else
               "0100"             when datain(2) = '1' else
               "00XX"             when is_x(datain(1)) else
               "0010"             when datain(1) = '1' else
               "000X"             when is_x(datain(0)) else
               "0001"             when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_5 : if input_bits = 5 generate
    dataout <= (others => 'X')    when is_x(datain(4)) else
               "10000"            when datain(4) = '1' else
               "0XXXX"            when is_x(datain(3)) else
               "01000"            when datain(3) = '1' else
               "00XXX"            when is_x(datain(2)) else
               "00100"            when datain(2) = '1' else
               "000XX"            when is_x(datain(1)) else
               "00010"            when datain(1) = '1' else
               "0000X"            when is_x(datain(0)) else
               "00001"            when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_6 : if input_bits = 6 generate
    dataout <= (others => 'X')    when is_x(datain(5)) else
               "100000"           when datain(5) = '1' else
               "0XXXXX"           when is_x(datain(4)) else
               "010000"           when datain(4) = '1' else
               "00XXXX"           when is_x(datain(3)) else
               "001000"           when datain(3) = '1' else
               "000XXX"           when is_x(datain(2)) else
               "000100"           when datain(2) = '1' else
               "0000XX"           when is_x(datain(1)) else
               "000010"           when datain(1) = '1' else
               "00000X"           when is_x(datain(0)) else
               "000001"           when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_7 : if input_bits = 7 generate
    dataout <= (others => 'X')    when is_x(datain(6)) else
               "1000000"          when datain(6) = '1' else
               "0XXXXXX"          when is_x(datain(5)) else
               "0100000"          when datain(5) = '1' else
               "00XXXXX"          when is_x(datain(4)) else
               "0010000"          when datain(4) = '1' else
               "000XXXX"          when is_x(datain(3)) else
               "0001000"          when datain(3) = '1' else
               "0000XXX"          when is_x(datain(2)) else
               "0000100"          when datain(2) = '1' else
               "00000XX"          when is_x(datain(1)) else
               "0000010"          when datain(1) = '1' else
               "000000X"          when is_x(datain(0)) else
               "0000001"          when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_8 : if input_bits = 8 generate
    dataout <= (others => 'X')    when is_x(datain(7)) else
               "10000000"         when datain(7) = '1' else
               "0XXXXXXX"         when is_x(datain(6)) else
               "01000000"         when datain(6) = '1' else
               "00XXXXXX"         when is_x(datain(5)) else
               "00100000"         when datain(5) = '1' else
               "000XXXXX"         when is_x(datain(4)) else
               "00010000"         when datain(4) = '1' else
               "0000XXXX"         when is_x(datain(3)) else
               "00001000"         when datain(3) = '1' else
               "00000XXX"         when is_x(datain(2)) else
               "00000100"         when datain(2) = '1' else
               "000000XX"         when is_x(datain(1)) else
               "00000010"         when datain(1) = '1' else
               "0000000X"         when is_x(datain(0)) else
               "00000001"         when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_9 : if input_bits = 9 generate
    dataout <= (others => 'X')    when is_x(datain(8)) else
               "100000000"        when datain(8) = '1' else
               "0XXXXXXXX"        when is_x(datain(7)) else
               "010000000"        when datain(7) = '1' else
               "00XXXXXXX"        when is_x(datain(6)) else
               "001000000"        when datain(6) = '1' else
               "000XXXXXX"        when is_x(datain(5)) else
               "000100000"        when datain(5) = '1' else
               "0000XXXXX"        when is_x(datain(4)) else
               "000010000"        when datain(4) = '1' else
               "00000XXXX"        when is_x(datain(3)) else
               "000001000"        when datain(3) = '1' else
               "000000XXX"        when is_x(datain(2)) else
               "000000100"        when datain(2) = '1' else
               "0000000XX"        when is_x(datain(1)) else
               "000000010"        when datain(1) = '1' else
               "00000000X"        when is_x(datain(0)) else
               "000000001"        when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_10 : if input_bits = 10 generate
    dataout <= (others => 'X')    when is_x(datain(9)) else
               "1000000000"       when datain(9) = '1' else
               "0XXXXXXXXX"       when is_x(datain(8)) else
               "0100000000"       when datain(8) = '1' else
               "00XXXXXXXX"       when is_x(datain(7)) else
               "0010000000"       when datain(7) = '1' else
               "000XXXXXXX"       when is_x(datain(6)) else
               "0001000000"       when datain(6) = '1' else
               "0000XXXXXX"       when is_x(datain(5)) else
               "0000100000"       when datain(5) = '1' else
               "00000XXXXX"       when is_x(datain(4)) else
               "0000010000"       when datain(4) = '1' else
               "000000XXXX"       when is_x(datain(3)) else
               "0000001000"       when datain(3) = '1' else
               "0000000XXX"       when is_x(datain(2)) else
               "0000000100"       when datain(2) = '1' else
               "00000000XX"       when is_x(datain(1)) else
               "0000000010"       when datain(1) = '1' else
               "000000000X"       when is_x(datain(0)) else
               "0000000001"       when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_11 : if input_bits = 11 generate
    dataout <= (others => 'X')    when is_x(datain(10)) else
               "10000000000"      when datain(10) = '1' else
               "0XXXXXXXXXX"      when is_x(datain(9)) else
               "01000000000"      when datain(9) = '1' else
               "00XXXXXXXXX"      when is_x(datain(8)) else
               "00100000000"      when datain(8) = '1' else
               "000XXXXXXXX"      when is_x(datain(7)) else
               "00010000000"      when datain(7) = '1' else
               "0000XXXXXXX"      when is_x(datain(6)) else
               "00001000000"      when datain(6) = '1' else
               "00000XXXXXX"      when is_x(datain(5)) else
               "00000100000"      when datain(5) = '1' else
               "000000XXXXX"      when is_x(datain(4)) else
               "00000010000"      when datain(4) = '1' else
               "0000000XXXX"      when is_x(datain(3)) else
               "00000001000"      when datain(3) = '1' else
               "00000000XXX"      when is_x(datain(2)) else
               "00000000100"      when datain(2) = '1' else
               "000000000XX"      when is_x(datain(1)) else
               "00000000010"      when datain(1) = '1' else
               "0000000000X"      when is_x(datain(0)) else
               "00000000001"      when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_12 : if input_bits = 12 generate
    dataout <= (others => 'X')    when is_x(datain(11)) else
               "100000000000"     when datain(11) = '1' else
               "0XXXXXXXXXXX"     when is_x(datain(10)) else
               "010000000000"     when datain(10) = '1' else
               "00XXXXXXXXXX"     when is_x(datain(9)) else
               "001000000000"     when datain(9) = '1' else
               "000XXXXXXXXX"     when is_x(datain(8)) else
               "000100000000"     when datain(8) = '1' else
               "0000XXXXXXXX"     when is_x(datain(7)) else
               "000010000000"     when datain(7) = '1' else
               "00000XXXXXXX"     when is_x(datain(6)) else
               "000001000000"     when datain(6) = '1' else
               "000000XXXXXX"     when is_x(datain(5)) else
               "000000100000"     when datain(5) = '1' else
               "0000000XXXXX"     when is_x(datain(4)) else
               "000000010000"     when datain(4) = '1' else
               "00000000XXXX"     when is_x(datain(3)) else
               "000000001000"     when datain(3) = '1' else
               "000000000XXX"     when is_x(datain(2)) else
               "000000000100"     when datain(2) = '1' else
               "0000000000XX"     when is_x(datain(1)) else
               "000000000010"     when datain(1) = '1' else
               "00000000000X"     when is_x(datain(0)) else
               "000000000001"     when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_13 : if input_bits = 13 generate
    dataout <= (others => 'X')    when is_x(datain(12)) else
               "1000000000000"    when datain(12) = '1' else
               "0XXXXXXXXXXXX"    when is_x(datain(11)) else
               "0100000000000"    when datain(11) = '1' else
               "00XXXXXXXXXXX"    when is_x(datain(10)) else
               "0010000000000"    when datain(10) = '1' else
               "000XXXXXXXXXX"    when is_x(datain(9)) else
               "0001000000000"    when datain(9) = '1' else
               "0000XXXXXXXXX"    when is_x(datain(8)) else
               "0000100000000"    when datain(8) = '1' else
               "00000XXXXXXXX"    when is_x(datain(7)) else
               "0000010000000"    when datain(7) = '1' else
               "000000XXXXXXX"    when is_x(datain(6)) else
               "0000001000000"    when datain(6) = '1' else
               "0000000XXXXXX"    when is_x(datain(5)) else
               "0000000100000"    when datain(5) = '1' else
               "00000000XXXXX"    when is_x(datain(4)) else
               "0000000010000"    when datain(4) = '1' else
               "000000000XXXX"    when is_x(datain(3)) else
               "0000000001000"    when datain(3) = '1' else
               "0000000000XXX"    when is_x(datain(2)) else
               "0000000000100"    when datain(2) = '1' else
               "00000000000XX"    when is_x(datain(1)) else
               "0000000000010"    when datain(1) = '1' else
               "000000000000X"    when is_x(datain(0)) else
               "0000000000001"    when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_14 : if input_bits = 14 generate
    dataout <= (others => 'X')    when is_x(datain(13)) else
               "10000000000000"   when datain(13) = '1' else
               "0XXXXXXXXXXXXX"   when is_x(datain(12)) else
               "01000000000000"   when datain(12) = '1' else
               "00XXXXXXXXXXXX"   when is_x(datain(11)) else
               "00100000000000"   when datain(11) = '1' else
               "000XXXXXXXXXXX"   when is_x(datain(10)) else
               "00010000000000"   when datain(10) = '1' else
               "0000XXXXXXXXXX"   when is_x(datain(9)) else
               "00001000000000"   when datain(9) = '1' else
               "00000XXXXXXXXX"   when is_x(datain(8)) else
               "00000100000000"   when datain(8) = '1' else
               "000000XXXXXXXX"   when is_x(datain(7)) else
               "00000010000000"   when datain(7) = '1' else
               "0000000XXXXXXX"   when is_x(datain(6)) else
               "00000001000000"   when datain(6) = '1' else
               "00000000XXXXXX"   when is_x(datain(5)) else
               "00000000100000"   when datain(5) = '1' else
               "000000000XXXXX"   when is_x(datain(4)) else
               "00000000010000"   when datain(4) = '1' else
               "0000000000XXXX"   when is_x(datain(3)) else
               "00000000001000"   when datain(3) = '1' else
               "00000000000XXX"   when is_x(datain(2)) else
               "00000000000100"   when datain(2) = '1' else
               "000000000000XX"   when is_x(datain(1)) else
               "00000000000010"   when datain(1) = '1' else
               "0000000000000X"   when is_x(datain(0)) else
               "00000000000001"   when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_15 : if input_bits = 15 generate
    dataout <= (others => 'X')    when is_x(datain(14)) else
               "100000000000000"  when datain(14) = '1' else
               "0XXXXXXXXXXXXXX"  when is_x(datain(13)) else
               "010000000000000"  when datain(13) = '1' else
               "00XXXXXXXXXXXXX"  when is_x(datain(12)) else
               "001000000000000"  when datain(12) = '1' else
               "000XXXXXXXXXXXX"  when is_x(datain(11)) else
               "000100000000000"  when datain(11) = '1' else
               "0000XXXXXXXXXXX"  when is_x(datain(10)) else
               "000010000000000"  when datain(10) = '1' else
               "00000XXXXXXXXXX"  when is_x(datain(9)) else
               "000001000000000"  when datain(9) = '1' else
               "000000XXXXXXXXX"  when is_x(datain(8)) else
               "000000100000000"  when datain(8) = '1' else
               "0000000XXXXXXXX"  when is_x(datain(7)) else
               "000000010000000"  when datain(7) = '1' else
               "00000000XXXXXXX"  when is_x(datain(6)) else
               "000000001000000"  when datain(6) = '1' else
               "000000000XXXXXX"  when is_x(datain(5)) else
               "000000000100000"  when datain(5) = '1' else
               "0000000000XXXXX"  when is_x(datain(4)) else
               "000000000010000"  when datain(4) = '1' else
               "00000000000XXXX"  when is_x(datain(3)) else
               "000000000001000"  when datain(3) = '1' else
               "000000000000XXX"  when is_x(datain(2)) else
               "000000000000100"  when datain(2) = '1' else
               "0000000000000XX"  when is_x(datain(1)) else
               "000000000000010"  when datain(1) = '1' else
               "00000000000000X"  when is_x(datain(0)) else
               "000000000000001"  when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_16 : if input_bits = 16 generate
    dataout <= (others => 'X')    when is_x(datain(15)) else
               "1000000000000000" when datain(15) = '1' else
               "0XXXXXXXXXXXXXXX" when is_x(datain(14)) else
               "0100000000000000" when datain(14) = '1' else
               "00XXXXXXXXXXXXXX" when is_x(datain(13)) else
               "0010000000000000" when datain(13) = '1' else
               "000XXXXXXXXXXXXX" when is_x(datain(12)) else
               "0001000000000000" when datain(12) = '1' else
               "0000XXXXXXXXXXXX" when is_x(datain(11)) else
               "0000100000000000" when datain(11) = '1' else
               "00000XXXXXXXXXXX" when is_x(datain(10)) else
               "0000010000000000" when datain(10) = '1' else
               "000000XXXXXXXXXX" when is_x(datain(9)) else
               "0000001000000000" when datain(9) = '1' else
               "0000000XXXXXXXXX" when is_x(datain(8)) else
               "0000000100000000" when datain(8) = '1' else
               "00000000XXXXXXXX" when is_x(datain(7)) else
               "0000000010000000" when datain(7) = '1' else
               "000000000XXXXXXX" when is_x(datain(6)) else
               "0000000001000000" when datain(6) = '1' else
               "0000000000XXXXXX" when is_x(datain(5)) else
               "0000000000100000" when datain(5) = '1' else
               "00000000000XXXXX" when is_x(datain(4)) else
               "0000000000010000" when datain(4) = '1' else
               "000000000000XXXX" when is_x(datain(3)) else
               "0000000000001000" when datain(3) = '1' else
               "0000000000000XXX" when is_x(datain(2)) else
               "0000000000000100" when datain(2) = '1' else
               "00000000000000XX" when is_x(datain(1)) else
               "0000000000000010" when datain(1) = '1' else
               "000000000000000X" when is_x(datain(0)) else
               "0000000000000001" when datain(0) = '1' else
               (others => 'X');
  end generate;

  input_bits_out_of_range : if input_bits > 16 generate
    input_bits_out_of_rance_proc : process is
    begin
      assert input_bits > 16 report "input_bits is out of range" severity failure;
      wait;
    end process;
  end generate;
  
end;
