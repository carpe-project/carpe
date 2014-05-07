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

architecture rtl of syncram_1r1w_inferred is

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
    name := new string'(entity_path_name(syncram_1r1w_inferred'path_name));
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
  
  pure function conv_addr (addr : std_ulogic_vector(addr_bits-1 downto 0)) return natural is
  begin
    if addr_bits > 0 then
      return to_integer(unsigned(addr));
    else
      return 0;
    end if;
  end function;

  signal memory : memory_type := memory_init;

  type reg_type is record
    raddr  : std_ulogic_vector(addr_bits-1 downto 0);
  end record;
  signal r : reg_type;

begin

  write_process : process(clk)
  begin
    if rising_edge(clk) then
      
      assert not is_x(we) report "we is invalid" severity warning;
      if we = '1' then
        assert not is_x(waddr) report "waddr is invalid" severity warning;
        if not is_x(waddr) then
          memory(conv_addr(waddr)) <= wdata;
        end if;
      end if;
      
    end if;
  end process;
  
  write_first_true_gen: if write_first generate
    
    rdata <= memory(conv_addr(r.raddr)) when not is_x(r.raddr) else (others => 'X');

    read_process : process(clk)
    begin
      if rising_edge(clk) then
        
        assert not is_x(re) report "re is invalid" severity warning;
        if re = '1' then
            r.raddr <= raddr;
        end if;
        
      end if;
    end process;
  
  end generate;

  write_first_false_gen: if not write_first generate

    main : process(clk)
    begin

      if rising_edge(clk) then
        
        assert not is_x(re) report "re is invalid" severity warning;
        if re = '1' then
          rdata <= memory(conv_addr(raddr));
        end if;

      end if;
      
    end process;
      
  end generate;
  
end;
