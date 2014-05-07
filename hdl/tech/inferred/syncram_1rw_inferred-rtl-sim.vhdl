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

library util;
use util.numeric_pkg.all;
use util.logic_pkg.all;
use util.names_pkg.all;

use std.textio.all;

architecture rtl of syncram_1rw_inferred is

  pure function conv_addr (addr : std_ulogic_vector(addr_bits-1 downto 0)) return natural is
  begin
    if addr_bits > 0 then
      return to_integer(unsigned(addr));
    else
      return 0;
    end if;
  end function;

  constant memory_size : natural := 2**addr_bits;
  type memory_type is array(0 to memory_size-1) of std_ulogic_vector((data_bits-1) downto 0);

  -- fill the memory with pseudo-random (but reproduceable) data
  pure function memory_init return memory_type is
    constant lfsr_bits : natural := addr_bits + log2ceil(data_bits) + 1;
    variable lfsr : std_ulogic_vector(lfsr_bits-1 downto 0);
    constant taps : std_ulogic_vector(lfsr_bits-1 downto 0) := lfsr_taps(lfsr_bits);
    variable ret : memory_type;
    variable initial_bit : integer;
    variable name : line;
  begin
    name := new string'(entity_path_name(syncram_1rw_inferred'path_name));
    for n in name.all'range loop
      initial_bit := (initial_bit + character'pos(name.all(n))) mod lfsr_bits;
    end loop;
    deallocate(name);
    lfsr := (others => '0');
    lfsr(0) := '1';
    lfsr(initial_bit) := '1';
    for n in 0 to memory_size-1 loop
      for m in data_bits-1 downto 0 loop
        ret(n)(m) := lfsr(0);
        lfsr(lfsr_bits-1 downto 0) := lfsr(0) & (lfsr(lfsr_bits-1 downto 1) xor ((lfsr_bits-2 downto 0 => lfsr(0)) and taps(lfsr_bits-2 downto 0)));
      end loop;
    end loop;
    return ret;
  end;
  
  signal memory : memory_type := memory_init;

begin

  main : process(clk)
  begin
    
    if rising_edge(clk) then

      assert not is_x(en) report "en is invalid" severity warning;
      if en = '1' then
        assert not is_x(we) report "ew is invalid" severity warning;
        assert not is_x(addr) report "addr is invalid" severity warning;
        if we = '1' then
          if not is_x(addr) then
            memory(conv_addr(addr)) <= wdata;
          end if;
          rdata <= (others => 'X');
        else
          rdata <= memory(conv_addr(addr));
        end if;

      end if;
      
    end if;
    
  end process;
  
end;
