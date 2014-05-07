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
use util.logic_pkg.all;

architecture rtl of mul_trunc_seq_inferred is

  type comb_type is record
    src1_tmp : std_ulogic_vector(src_bits downto 0);
    src2_tmp : std_ulogic_vector(src_bits downto 0);
    result_tmp : std_ulogic_vector(2*src_bits+1 downto 0);
    overflow_tmp : std_ulogic;
  end record;
  signal c : comb_type;

  type pipe_entry_type is record
    valid : std_ulogic;
    overflow : std_ulogic;
    result : std_ulogic_vector(src_bits-1 downto 0);
  end record;
  constant pipe_entry_x : pipe_entry_type := (
    valid => 'X',
    overflow => 'X',
    result => (others =>'X')
    );

  type reg_type is array(latency-1 downto 0) of pipe_entry_type;
  constant reg_x : reg_type := (
    others => pipe_entry_x
    );
  signal r, r_next : reg_type;
  
begin

  c.src1_tmp <= (src1(src_bits-1) and not unsgnd) & src1;
  c.src2_tmp <= (src2(src_bits-1) and not unsgnd) & src2;
  c.result_tmp <= std_ulogic_vector(signed(c.src1_tmp) * signed(c.src2_tmp));
  c.overflow_tmp <= not (
    (all_zeros(c.result_tmp(2*src_bits-1 downto src_bits)) and (unsgnd or not c.result_tmp(src_bits-1))) or
    (not unsgnd and all_ones(c.result_tmp(2*src_bits-1 downto src_bits-1)))
    );

  status_latency_gt_1 : if latency > 1 generate
    r_next(latency-1).valid <= (r(latency-1).valid or r(latency-2).valid) and not en;
    status_latency_gt_2 : if latency > 2 generate
      status_loop : for n in latency-2 downto 1 generate
        r_next(n).valid <= r(n-1).valid and not en;
      end generate;
    end generate;
    r_next(0).valid <= en;
  end generate;
  status_latency_eq_1 : if latency = 1 generate
    r_next(0).valid <= r(0).valid or en;
  end generate;

  with en select
    r_next(0).overflow <= r(0).overflow  when '0',
                          c.overflow_tmp when '1',
                          'X'            when others;
  with en select
    r_next(0).result <= r(0).result                       when '0',
                   c.result_tmp(src_bits-1 downto 0) when '1',
                   (others => 'X')                   when others;
  pipe_loop : for n in latency-1 downto 1 generate
    with en select
      r_next(n).overflow <= r(n-1).overflow when '0',
                            'X'             when others;
    with en select
      r_next(n).result   <= r(n-1).result   when '0',
                            (others => 'X') when others;
  end generate;

  valid <= r(latency-1).valid;
  result <= r(latency-1).result;
  overflow <= r(latency-1).overflow;
  
  seq : process(clk) is
  begin

    if rising_edge(clk) then
      r <= r_next;
    end if;
    
  end process;
  
end;
