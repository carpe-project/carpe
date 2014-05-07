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


library util;
use util.logic_pkg.all;

architecture rtl of lfsr_inferred is

  subtype state_type is std_ulogic_vector(state_bits-1 downto 0);

  constant taps : state_type := lfsr_taps(state_bits);

  type comb_type is record
    state_next : state_type;
  end record;
  signal c : comb_type;
  
  type reg_type is record
    state : state_type;
  end record;
  signal r, r_next : reg_type;
  
begin

  -- Galois style
  state_next_gen : for n in state_bits-2 downto 0 generate
    tap : if taps(n) = '1' generate
      c.state_next(n) <= r.state(n+1) xor r.state(0);
    end generate;
    no_tap : if taps(n) = '0' generate
      c.state_next(n) <= r.state(n+1);
    end generate;
  end generate;
  c.state_next(state_bits-1) <= r.state(0);

  with en select
    r_next.state <= c.state_next    when '1',
                    r.state         when '0',
                    (others => 'X') when others;

  output <= r.state(0);

  seq : process (clk) is
  begin
    if rising_edge(clk) then
      case rstn is
        when '1' =>
          r <= r_next;
        when '0' =>
          r.state(0) <= '1';
          r.state(state_bits-1 downto 1) <= (others => '0');
        when others =>
          r <= (state => (others => 'X'));
      end case;
    end if;
  end process;
  
end;
