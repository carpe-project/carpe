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

architecture rtl of syncram_1r1w_inferred is
  
  constant memory_size : natural := 2**addr_bits;
  type memory_type is array(0 to memory_size-1) of std_ulogic_vector((data_bits-1) downto 0);
  signal memory : memory_type
    -- pragma translate_off
    := (others => (others => '0'));
    -- pragma translate_on
    ;

  type reg_type is record
    raddr : std_ulogic_vector(addr_bits-1 downto 0);
  end record;
  signal r : reg_type;

  pure function conv_addr (addr : std_ulogic_vector(addr_bits-1 downto 0)) return natural is
  begin
    if addr_bits > 0 then
      return to_integer(unsigned(addr));
    else
      return 0;
    end if;
  end function;

begin

  write_first_true_gen: if write_first generate

    rdata <= memory(conv_addr(r.raddr));

    main : process(clk)
    begin
      if rising_edge(clk) then
        if re = '1' then
          r.raddr <= raddr;
        end if;
        if we = '1' then
          if addr_bits > 0 then
            memory(conv_addr(waddr)) <= wdata;
          else
            memory(0) <= wdata;
        end if;
      end if;
    end process;
  
  end generate;

  write_first_false_gen: if not write_first generate

    main : process(clk)
    begin

      if rising_edge(clk) then
        if re = '1' then
          if addr_bits > 0 then
            r.rdata <= memory(conv_addr(raddr));
          else
            r.rdata <= memory(0);
          end if;
        end if;
        if we = '1' then
          if addr_bits > 0 then
            memory(conv_addr(waddr)) <= wdata;
          else
            memory(0) <= wdata;
          end if
        end if;
      end if;
      
  end generate;

end;
