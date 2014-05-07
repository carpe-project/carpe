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

library util;
use util.numeric_pkg.all;

architecture rtl of decoder_inferred is

begin

  output_bits_1 : if output_bits = 1 generate
    dataout <= "1";
  end generate;

  output_bits_2 : if output_bits = 2 generate
    mux : block
      signal sel : std_ulogic_vector(0 downto 0);
    begin
      sel <= datain(0 downto 0);
      with sel select
        dataout <= "01" when "0",
                   "10" when "1",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_3 : if output_bits = 3 generate
    mux : block
      signal sel : std_ulogic_vector(1 downto 0);
    begin
      sel <= datain(1 downto 0);
      with sel select
        dataout <= "001" when "00",
                   "010" when "01",
                   "100" when "10",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_4 : if output_bits = 4 generate
    mux : block
      signal sel : std_ulogic_vector(1 downto 0);
    begin
      sel <= datain(1 downto 0);
      with sel select
        dataout <= "0001" when "00",
                   "0010" when "01",
                   "0100" when "10",
                   "1000" when "11",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_5 : if output_bits = 5 generate
    mux : block
      signal sel : std_ulogic_vector(2 downto 0);
    begin
      sel <= datain(2 downto 0);
      with sel select
        dataout <= "00001" when "000",
                   "00010" when "001",
                   "00100" when "010",
                   "01000" when "011",
                   "10000" when "100",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_6 : if output_bits = 6 generate
    mux : block
      signal sel : std_ulogic_vector(2 downto 0);
    begin
      sel <= datain(2 downto 0);
      with sel select
        dataout <= "000001" when "000",
                   "000010" when "001",
                   "000100" when "010",
                   "001000" when "011",
                   "010000" when "100",
                   "100000" when "101",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_7 : if output_bits = 7 generate
    mux : block
      signal sel : std_ulogic_vector(2 downto 0);
    begin
      sel <= datain(2 downto 0);
      with sel select
        dataout <= "0000001" when "000",
                   "0000010" when "001",
                   "0000100" when "010",
                   "0001000" when "011",
                   "0010000" when "100",
                   "0100000" when "101",
                   "1000000" when "110",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_8 : if output_bits = 8 generate
    mux : block
      signal sel : std_ulogic_vector(2 downto 0);
    begin
      sel <= datain(2 downto 0);
      with sel select
        dataout <= "00000001" when "000",
                   "00000010" when "001",
                   "00000100" when "010",
                   "00001000" when "011",
                   "00010000" when "100",
                   "00100000" when "101",
                   "01000000" when "110",
                   "10000000" when "111",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_9 : if output_bits = 9 generate
    mux : block
      signal sel : std_ulogic_vector(3 downto 0);
    begin
      sel <= datain(3 downto 0);
      with sel select
        dataout <= "000000001" when "0000",
                   "000000010" when "0001",
                   "000000100" when "0010",
                   "000001000" when "0011",
                   "000010000" when "0100",
                   "000100000" when "0101",
                   "001000000" when "0110",
                   "010000000" when "0111",
                   "100000000" when "1000",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_10 : if output_bits = 10 generate
    mux : block
      signal sel : std_ulogic_vector(3 downto 0);
    begin
      sel <= datain(3 downto 0);
      with sel select
        dataout <= "0000000001" when "0000",
                   "0000000010" when "0001",
                   "0000000100" when "0010",
                   "0000001000" when "0011",
                   "0000010000" when "0100",
                   "0000100000" when "0101",
                   "0001000000" when "0110",
                   "0010000000" when "0111",
                   "0100000000" when "1000",
                   "1000000000" when "1001",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_11 : if output_bits = 11 generate
    mux : block
      signal sel : std_ulogic_vector(3 downto 0);
    begin
      sel <= datain(3 downto 0);
      with sel select
        dataout <= "00000000001" when "0000",
                   "00000000010" when "0001",
                   "00000000100" when "0010",
                   "00000001000" when "0011",
                   "00000010000" when "0100",
                   "00000100000" when "0101",
                   "00001000000" when "0110",
                   "00010000000" when "0111",
                   "00100000000" when "1000",
                   "01000000000" when "1001",
                   "10000000000" when "1010",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_12 : if output_bits = 12 generate
    mux : block
      signal sel : std_ulogic_vector(3 downto 0);
    begin
      sel <= datain(3 downto 0);
      with sel select
        dataout <= "000000000001" when "0000",
                   "000000000010" when "0001",
                   "000000000100" when "0010",
                   "000000001000" when "0011",
                   "000000010000" when "0100",
                   "000000100000" when "0101",
                   "000001000000" when "0110",
                   "000010000000" when "0111",
                   "000100000000" when "1000",
                   "001000000000" when "1001",
                   "010000000000" when "1010",
                   "100000000000" when "1011",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_13 : if output_bits = 13 generate
    mux : block
      signal sel : std_ulogic_vector(3 downto 0);
    begin
      sel <= datain(3 downto 0);
      with sel select
        dataout <= "0000000000001" when "0000",
                   "0000000000010" when "0001",
                   "0000000000100" when "0010",
                   "0000000001000" when "0011",
                   "0000000010000" when "0100",
                   "0000000100000" when "0101",
                   "0000001000000" when "0110",
                   "0000010000000" when "0111",
                   "0000100000000" when "1000",
                   "0001000000000" when "1001",
                   "0010000000000" when "1010",
                   "0100000000000" when "1011",
                   "1000000000000" when "1100",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_14 : if output_bits = 14 generate
    mux : block
      signal sel : std_ulogic_vector(3 downto 0);
    begin
      sel <= datain(3 downto 0);
      with sel select
        dataout <= "00000000000001" when "0000",
                   "00000000000010" when "0001",
                   "00000000000100" when "0010",
                   "00000000001000" when "0011",
                   "00000000010000" when "0100",
                   "00000000100000" when "0101",
                   "00000001000000" when "0110",
                   "00000010000000" when "0111",
                   "00000100000000" when "1000",
                   "00001000000000" when "1001",
                   "00010000000000" when "1010",
                   "00100000000000" when "1011",
                   "01000000000000" when "1100",
                   "10000000000000" when "1101",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_15 : if output_bits = 15 generate
    mux : block
      signal sel : std_ulogic_vector(3 downto 0);
    begin
      sel <= datain(3 downto 0);
      with sel select
        dataout <= "000000000000001" when "0000",
                   "000000000000010" when "0001",
                   "000000000000100" when "0010",
                   "000000000001000" when "0011",
                   "000000000010000" when "0100",
                   "000000000100000" when "0101",
                   "000000001000000" when "0110",
                   "000000010000000" when "0111",
                   "000000100000000" when "1000",
                   "000001000000000" when "1001",
                   "000010000000000" when "1010",
                   "000100000000000" when "1011",
                   "001000000000000" when "1100",
                   "010000000000000" when "1101",
                   "100000000000000" when "1110",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_16 : if output_bits = 16 generate
    mux : block
      signal sel : std_ulogic_vector(3 downto 0);
    begin
      sel <= datain(3 downto 0);
      with sel select
        dataout <= "0000000000000001" when "0000",
                   "0000000000000010" when "0001",
                   "0000000000000100" when "0010",
                   "0000000000001000" when "0011",
                   "0000000000010000" when "0100",
                   "0000000000100000" when "0101",
                   "0000000001000000" when "0110",
                   "0000000010000000" when "0111",
                   "0000000100000000" when "1000",
                   "0000001000000000" when "1001",
                   "0000010000000000" when "1010",
                   "0000100000000000" when "1011",
                   "0001000000000000" when "1100",
                   "0010000000000000" when "1101",
                   "0100000000000000" when "1110",
                   "1000000000000000" when "1111",
                   (others => 'X') when others;
    end block;
  end generate;

  output_bits_out_of_range : if output_bits > 16 generate
    output_bits_out_of_rance_proc : process is
    begin
      assert output_bits > 16 report "output_bits is out of range" severity failure;
      wait;
    end process;
  end generate;

end;
