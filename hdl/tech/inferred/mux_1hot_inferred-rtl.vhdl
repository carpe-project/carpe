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
use ieee.numeric_std.all;

architecture rtl of mux_1hot_inferred is

  type mux_type is array (sel_bits-1 downto 0) of std_ulogic_vector(data_bits-1 downto 0);

  type comb_type is record
    m : mux_type;
  end record;
  signal c : comb_type;
  
begin

  sel_bit_loop : for n in sel_bits-1 downto 0 generate
    data_bit_loop : for m in data_bits-1 downto 0 generate
      c.m(n)(m) <= din(n, m);
    end generate;
  end generate;
  
  sel_bits_0 : if sel_bits = 0 generate
    dout <= "";
  end generate;
  
  sel_bits_1 : if sel_bits = 1 generate
    mux : block
      signal sel_tmp : std_ulogic_vector(0 downto 0);
    begin
      sel_tmp <= sel(0 downto 0);
      with sel_tmp select
        dout <= c.m(0)          when "1",
                (others => 'X') when others;
    end block;
  end generate;
  
  sel_bits_2 : if sel_bits = 2 generate
    mux : block
      signal sel_tmp : std_ulogic_vector(1 downto 0);
    begin
      sel_tmp <= sel(1 downto 0);
      with sel_tmp select
        dout <= c.m(0)          when "01",
                c.m(1)          when "10",
                (others => 'X') when others;
    end block;
  end generate;
  
  sel_bits_3 : if sel_bits = 3 generate
    mux : block
      signal sel_tmp : std_ulogic_vector(2 downto 0);
    begin
      sel_tmp <= sel(2 downto 0);
      with sel_tmp select
        dout <= c.m(0)          when "001",
                c.m(1)          when "010",
                c.m(2)          when "100",
                (others => 'X') when others;
    end block;
  end generate;

  sel_bits_4 : if sel_bits = 4 generate
    mux : block
      signal sel_tmp : std_ulogic_vector(3 downto 0);
    begin
      sel_tmp <= sel(3 downto 0);
      with sel_tmp select
        dout <= c.m(0)          when "0001",
                c.m(1)          when "0010",
                c.m(2)          when "0100",
                c.m(3)          when "1000",
                (others => 'X') when others;
    end block;
  end generate;

  sel_bits_5 : if sel_bits = 5 generate
    mux : block
      signal sel_tmp : std_ulogic_vector(4 downto 0);
    begin
      sel_tmp <= sel(4 downto 0);
      with sel_tmp select
        dout <= c.m(0)          when "00001",
                c.m(1)          when "00010",
                c.m(2)          when "00100",
                c.m(3)          when "01000",
                c.m(4)          when "10000",
                (others => 'X') when others;
    end block;
  end generate;

  sel_bits_6 : if sel_bits = 6 generate
    mux : block
      signal sel_tmp : std_ulogic_vector(5 downto 0);
    begin
      sel_tmp <= sel(5 downto 0);
      with sel_tmp select
        dout <= c.m(0)          when "000001",
                c.m(1)          when "000010",
                c.m(2)          when "000100",
                c.m(3)          when "001000",
                c.m(4)          when "010000",
                c.m(5)          when "100000",
                (others => 'X') when others;
    end block;
  end generate;

  sel_bits_7 : if sel_bits = 7 generate
    mux : block
      signal sel_tmp : std_ulogic_vector(6 downto 0);
    begin
      sel_tmp <= sel(6 downto 0);
      with sel_tmp select
        dout <= c.m(0)          when "0000001",
                c.m(1)          when "0000010",
                c.m(2)          when "0000100",
                c.m(3)          when "0001000",
                c.m(4)          when "0010000",
                c.m(5)          when "0100000",
                c.m(6)          when "1000000",
                (others => 'X') when others;
    end block;
  end generate;

  sel_bits_8 : if sel_bits = 8 generate
    mux : block
      signal sel_tmp : std_ulogic_vector(7 downto 0);
    begin
      sel_tmp <= sel(7 downto 0);
      with sel_tmp select
        dout <= c.m(0)          when "00000001",
                c.m(1)          when "00000010",
                c.m(2)          when "00000100",
                c.m(3)          when "00001000",
                c.m(4)          when "00010000",
                c.m(5)          when "00100000",
                c.m(6)          when "01000000",
                c.m(7)          when "10000000",
                (others => 'X') when others;
    end block;
  end generate;

  sel_bits_out_of_range : if sel_bits > 8 generate
    error_process : process is
    begin
      assert sel_bits <= 8 report "sel_bits out of range" severity failure;
      wait;
    end process;
  end generate;
  
  
end;
