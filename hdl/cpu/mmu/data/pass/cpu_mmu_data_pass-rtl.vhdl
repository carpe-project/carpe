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


use work.cpu_types_pkg.all;
use work.cpu_mmu_data_types_pkg.all;

architecture rtl of cpu_mmu_data_pass is

  type reg_type is record
    mmuen : std_ulogic;
    vpn : cpu_vpn_type;
  end record;
  signal r, r_next : reg_type;

  type comb_type is record
    ppn : cpu_ppn_type;
  end record;
  signal c : comb_type;
  
begin

  ppn_large_vpn_gen : if cpu_ppn_bits > 0 and cpu_ppn_bits <= cpu_vpn_bits generate
    bit_loop : for n in cpu_ppn_bits-1 downto 0 generate
      c.ppn(n) <= r.vpn(n);
    end generate;
  end generate;
  ppn_small_vpn_gen : if cpu_ppn_bits > 0 and cpu_ppn_bits > cpu_vpn_bits generate
    c.ppn(cpu_ppn_bits-1 downto cpu_vpn_bits) <= (others => '0');
    c.ppn(cpu_vpn_bits-1 downto 0) <= r.vpn;
  end generate;

  r_next <= (
    mmuen => cpu_mmu_data_pass_ctrl_in.mmuen,
    vpn => cpu_mmu_data_pass_dp_in.vpn
    );

  seq : process (clk) is
  begin
    if rising_edge(clk) then
      case rstn is
        when '0' =>
          r <= (
            mmuen => '0',
            vpn => (others => 'X')
            );
        when '1' =>
          r <= r_next;
        when others =>
          r <= (
            mmuen => 'X',
            vpn => (others => 'X')
            );
      end case;
    end if;
  end process;

  --cpu_mmu_data_pass_ctrl_out <= (
  --  );
  
  cpu_mmu_data_pass_ctrl_out <= (
    ready => '1',
    result => (
      cpu_mmu_data_result_code_index_valid   => not r.mmuen,
      cpu_mmu_data_result_code_index_error   => '0',
      cpu_mmu_data_result_code_index_tlbmiss => r.mmuen,
      cpu_mmu_data_result_code_index_pf      => '0'
      )
    );
  cpu_mmu_data_pass_dp_out <= (
    ppn => c.ppn
    );

end;
