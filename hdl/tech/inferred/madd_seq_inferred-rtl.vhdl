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

architecture rtl of madd_seq_inferred is

  type comb_type is record
    src1_tmp : std_ulogic_vector(src1_bits downto 0);
    src2_tmp : std_ulogic_vector(src2_bits downto 0);
    prod_tmp1 : std_ulogic_vector(src1_bits+src2_bits+1 downto 0);
    prod_tmp2 : std_ulogic_vector(src1_bits+src2_bits downto 0);
    acc_tmp : std_ulogic_vector(src1_bits+src2_bits downto 0);
    result_tmp : std_ulogic_vector(src1_bits+src2_bits downto 0);
    result_msb_carryin : std_ulogic;
    result_msb : std_ulogic;
    carryout : std_ulogic;
    result : std_ulogic_vector(src1_bits+src2_bits-1 downto 0);
    overflow : std_ulogic;
  end record;
  signal c : comb_type;

  type stage_type is record
    overflow : std_ulogic;
    result : std_ulogic_vector(src1_bits+src2_bits-1 downto 0);
  end record;
  constant stage_x : stage_type := (
    overflow => 'X',
    result => (others => 'X')
    );

  type pipe_type is array(latency-1 downto 0) of stage_type;
  type reg_type is record
    status : std_ulogic_vector(latency-1 downto 0);
    pipe : pipe_type;
  end record;
  constant reg_x : reg_type := (
    status => (others => 'X'),
    pipe => (others => stage_x)
    );
  signal r, r_next : reg_type;
  
begin

  c.src1_tmp <= (src1(src1_bits-1) and not unsgnd) & src1;
  c.src2_tmp <= (src2(src2_bits-1) and not unsgnd) & src2;
  
  c.prod_tmp1 <= std_ulogic_vector(signed(c.src1_tmp) * signed(c.src2_tmp));
  c.prod_tmp2 <= (('0' & c.prod_tmp1(src1_bits+src2_bits-2 downto 0) & '0') xor
                  (src1_bits+src2_bits downto 0 => sub));
  
  c.acc_tmp <= '0' & acc(src1_bits+src2_bits-2 downto 0) & '1';
  c.result_tmp <= std_ulogic_vector(signed(c.acc_tmp) +
                                    signed(c.prod_tmp2));

  c.result_msb_carryin <= c.result_tmp(src1_bits+src2_bits);

  c.result_msb <= (acc(src1_bits+src2_bits-1) xor
                   c.prod_tmp1(src1_bits+src2_bits-1) xor
                   c.result_msb_carryin
                   );
  c.carryout <= (((sub xor acc(src1_bits+src2_bits-1)) and (c.prod_tmp1(src1_bits+src2_bits-1) or c.result_msb_carryin)) or
                 (c.prod_tmp1(src1_bits+src2_bits-1) and c.result_msb_carryin));
  
  c.overflow <= c.carryout xor (not unsgnd and c.result_msb_carryin);
  c.result   <= c.result_msb & c.result_tmp(src1_bits+src2_bits-1 downto 1);
  
  status_latency_gt_1 : if latency > 1 generate
    r_next.status(latency-1) <= (r.status(latency-1) or r.status(latency-2)) and not en;
    status_latency_gt_2 : if latency > 2 generate
      status_loop : for n in latency-2 downto 1 generate
        r_next.status(n) <= r.status(n-1) and not en;
      end generate;
    end generate;
    r_next.status(0) <= en;
  end generate;
  status_latency_eq_1 : if latency = 1 generate
    r_next.status(0) <= r.status(0) or en;
  end generate;

  with en select
    r_next.pipe(0) <= r.pipe(0) when '0',
                      (overflow => c.overflow,
                       result   => c.result
                       ) when '1',
                      stage_x when others;
  pipe_loop : for n in latency-1 downto 1 generate
    with en select
      r_next.pipe(n) <= r.pipe(n-1) when '0',
                        stage_x     when others;
  end generate;

  valid <= r.status(latency-1);
  result <= r.pipe(latency-1).result;
  overflow <= r.pipe(latency-1).overflow;
  
  seq : process(clk) is
  begin

    if rising_edge(clk) then
      r <= r_next;
    end if;
    
  end process;
  
end;
