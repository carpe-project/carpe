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

architecture rtl of encoder_inferred is
begin

  input_bits_1 : if input_bits = 1 generate
    mux : block
      signal sel : std_ulogic_vector(0 downto 0);
    begin
      sel <= datain(0 downto 0);
      with sel select
        dataout <= "1" when "1",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_2 : if input_bits = 2 generate
    mux : block
      signal sel : std_ulogic_vector(1 downto 0);
    begin
      sel <= datain(1 downto 0);
      with sel select
        dataout <= "0" when "01",
                   "1" when "10",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_3 : if input_bits = 3 generate
    mux : block
      signal sel : std_ulogic_vector(2 downto 0);
    begin
      sel <= datain(2 downto 0);
      with sel select
        dataout <= "00" when "001",
                   "01" when "010",
                   "10" when "100",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_4 : if input_bits = 4 generate
    mux : block
      signal sel : std_ulogic_vector(3 downto 0);
    begin
      sel <= datain(3 downto 0);
      with sel select
        dataout <= "00" when "0001",
                   "01" when "0010",
                   "10" when "0100",
                   "11" when "1000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_5 : if input_bits = 5 generate
    mux : block
      signal sel : std_ulogic_vector(4 downto 0);
    begin
      sel <= datain(4 downto 0);
      with sel select
        dataout <= "000" when "00001",
                   "001" when "00010",
                   "010" when "00100",
                   "011" when "01000",
                   "100" when "10000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_6 : if input_bits = 6 generate
    mux : block
      signal sel : std_ulogic_vector(5 downto 0);
    begin
      sel <= datain(5 downto 0);
      with sel select
        dataout <= "000" when "000001",
                   "001" when "000010",
                   "010" when "000100",
                   "011" when "001000",
                   "100" when "010000",
                   "101" when "100000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_7 : if input_bits = 7 generate
    mux : block
      signal sel : std_ulogic_vector(6 downto 0);
    begin
      sel <= datain(6 downto 0);
      with sel select
        dataout <= "000" when "0000001",
                   "001" when "0000010",
                   "010" when "0000100",
                   "011" when "0001000",
                   "100" when "0010000",
                   "101" when "0100000",
                   "110" when "1000000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_8 : if input_bits = 8 generate
    mux : block
      signal sel : std_ulogic_vector(7 downto 0);
    begin
      sel <= datain(7 downto 0);
      with sel select
        dataout <= "000" when "00000001",
                   "001" when "00000010",
                   "010" when "00000100",
                   "011" when "00001000",
                   "100" when "00010000",
                   "101" when "00100000",
                   "110" when "01000000",
                   "111" when "10000000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_9 : if input_bits = 9 generate
    mux : block
      signal sel : std_ulogic_vector(8 downto 0);
    begin
      sel <= datain(8 downto 0);
      with sel select
        dataout <= "0000" when "000000001",
                   "0001" when "000000010",
                   "0010" when "000000100",
                   "0011" when "000001000",
                   "0100" when "000010000",
                   "0101" when "000100000",
                   "0110" when "001000000",
                   "0111" when "010000000",
                   "1000" when "100000000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_10 : if input_bits = 10 generate
    mux : block
      signal sel : std_ulogic_vector(9 downto 0);
    begin
      sel <= datain(9 downto 0);
      with sel select
        dataout <= "0000" when "0000000001",
                   "0001" when "0000000010",
                   "0010" when "0000000100",
                   "0011" when "0000001000",
                   "0100" when "0000010000",
                   "0101" when "0000100000",
                   "0110" when "0001000000",
                   "0111" when "0010000000",
                   "1000" when "0100000000",
                   "1001" when "1000000000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_11 : if input_bits = 11 generate
    mux : block
      signal sel : std_ulogic_vector(10 downto 0);
    begin
      sel <= datain(10 downto 0);
      with sel select
        dataout <= "0000" when "00000000001",
                   "0001" when "00000000010",
                   "0010" when "00000000100",
                   "0011" when "00000001000",
                   "0100" when "00000010000",
                   "0101" when "00000100000",
                   "0110" when "00001000000",
                   "0111" when "00010000000",
                   "1000" when "00100000000",
                   "1001" when "01000000000",
                   "1010" when "10000000000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_12 : if input_bits = 12 generate
    mux : block
      signal sel : std_ulogic_vector(11 downto 0);
    begin
      sel <= datain(11 downto 0);
      with sel select
        dataout <= "0000" when "000000000001",
                   "0001" when "000000000010",
                   "0010" when "000000000100",
                   "0011" when "000000001000",
                   "0100" when "000000010000",
                   "0101" when "000000100000",
                   "0110" when "000001000000",
                   "0111" when "000010000000",
                   "1000" when "000100000000",
                   "1001" when "001000000000",
                   "1010" when "010000000000",
                   "1011" when "100000000000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_13 : if input_bits = 13 generate
    mux : block
      signal sel : std_ulogic_vector(12 downto 0);
    begin
      sel <= datain(12 downto 0);
      with sel select
        dataout <= "0000" when "0000000000001",
                   "0001" when "0000000000010",
                   "0010" when "0000000000100",
                   "0011" when "0000000001000",
                   "0100" when "0000000010000",
                   "0101" when "0000000100000",
                   "0110" when "0000001000000",
                   "0111" when "0000010000000",
                   "1000" when "0000100000000",
                   "1001" when "0001000000000",
                   "1010" when "0010000000000",
                   "1011" when "0100000000000",
                   "1100" when "1000000000000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_14 : if input_bits = 14 generate
    mux : block
      signal sel : std_ulogic_vector(13 downto 0);
    begin
      sel <= datain(13 downto 0);
      with sel select
        dataout <= "0000" when "00000000000001",
                   "0001" when "00000000000010",
                   "0010" when "00000000000100",
                   "0011" when "00000000001000",
                   "0100" when "00000000010000",
                   "0101" when "00000000100000",
                   "0110" when "00000001000000",
                   "0111" when "00000010000000",
                   "1000" when "00000100000000",
                   "1001" when "00001000000000",
                   "1010" when "00010000000000",
                   "1011" when "00100000000000",
                   "1100" when "01000000000000",
                   "1101" when "10000000000000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_15 : if input_bits = 15 generate
    mux : block
      signal sel : std_ulogic_vector(14 downto 0);
    begin
      sel <= datain(14 downto 0);
      with sel select
        dataout <= "0000" when "000000000000001",
                   "0001" when "000000000000010",
                   "0010" when "000000000000100",
                   "0011" when "000000000001000",
                   "0100" when "000000000010000",
                   "0101" when "000000000100000",
                   "0110" when "000000001000000",
                   "0111" when "000000010000000",
                   "1000" when "000000100000000",
                   "1001" when "000001000000000",
                   "1010" when "000010000000000",
                   "1011" when "000100000000000",
                   "1100" when "001000000000000",
                   "1101" when "010000000000000",
                   "1110" when "100000000000000",
                   (others => 'X') when others;
    end block;
  end generate;

  input_bits_16 : if input_bits = 16 generate
    mux : block
      signal sel : std_ulogic_vector(15 downto 0);
    begin
      sel <= datain(15 downto 0);
      with sel select
      dataout <= "0000" when "0000000000000001",
                 "0001" when "0000000000000010",
                 "0010" when "0000000000000100",
                 "0011" when "0000000000001000",
                 "0100" when "0000000000010000",
                 "0101" when "0000000000100000",
                 "0110" when "0000000001000000",
                 "0111" when "0000000010000000",
                 "1000" when "0000000100000000",
                 "1001" when "0000001000000000",
                 "1010" when "0000010000000000",
                 "1011" when "0000100000000000",
                 "1100" when "0001000000000000",
                 "1101" when "0010000000000000",
                 "1110" when "0100000000000000",
                 "1111" when "1000000000000000",
                 (others => 'X') when others;
    end block;
  end generate;

  input_bits_out_of_range : if input_bits > 16 generate
    input_bits_out_of_rance_proc : process is
    begin
      assert input_bits > 16 report "input_bits is out of range" severity failure;
      wait;
    end process;
  end generate;

end;
