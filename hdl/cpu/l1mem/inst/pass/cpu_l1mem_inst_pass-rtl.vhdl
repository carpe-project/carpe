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
use ieee.numeric_std.all;

library util;
use util.logic_pkg.all;
use util.types_pkg.all;

library sys;
use sys.sys_pkg.all;
use sys.sys_config_pkg.all;

use work.cpu_types_pkg.all;
use work.cpu_l1mem_inst_types_pkg.all;
use work.cpu_mmu_inst_types_pkg.all;

architecture rtl of cpu_l1mem_inst_pass is

  type state_index_type is (
    state_index_idle,
    state_index_mmu_access,
    state_index_bus_access
    );
  type state_type is array (state_index_type range state_index_type'high downto state_index_type'low) of std_ulogic;
  constant state_idle       : state_type := "001";
  constant state_mmu_access : state_type := "010";
  constant state_bus_access : state_type := "100";

  type paddr_sel_index_type is (
    paddr_sel_index_reg,
    paddr_sel_index_pipe,
    paddr_sel_index_mmu
    );
  type paddr_sel_type is array (paddr_sel_index_type range paddr_sel_index_type'high downto paddr_sel_index_type'low) of std_ulogic;
  constant paddr_sel_reg    : paddr_sel_type := "001";
  constant paddr_sel_incoming   : paddr_sel_type := "010";
  constant paddr_sel_mmu    : paddr_sel_type := "100";

  type comb_type is record
    state_next : state_type;

    mmu_request : std_ulogic;

    bus_request : std_ulogic;
    bus_requested_next : std_ulogic;
    
    incoming_request : std_ulogic;
    use_incoming_request : std_ulogic;

    be : std_ulogic;
    mmuen : std_ulogic;
    cacheen : std_ulogic;
    priv : std_ulogic;
    
    incoming_paddr : cpu_ipaddr_type;
    mmu_paddr  : cpu_ipaddr_type;
    bus_paddr_sel : paddr_sel_type;
    bus_paddr : cpu_ipaddr_type;
    
    paddr_next : cpu_ipaddr_type;
    
  end record;

  type reg_type is record
    state         : state_type;
    bus_requested : std_ulogic;
    mmuen           : std_ulogic;
    cacheen           : std_ulogic;
    priv : std_ulogic;
    paddr : cpu_ipaddr_type;
  end record;
  constant reg_x : reg_type := (
    state => (others => 'X'),
    bus_requested => 'X',
    mmuen   => 'X',
    cacheen   => 'X',
    priv => 'X',
    paddr => (others => 'X')
    );
  constant reg_init : reg_type := (
    state => state_idle,
    bus_requested => 'X',
    mmuen   => 'X',
    cacheen   => 'X',
    priv => 'X',
    paddr => (others => 'X')
    );

  signal c : comb_type;
  signal r, r_next : reg_type;

begin

  c.incoming_request <= cpu_l1mem_inst_pass_ctrl_in.request(cpu_l1mem_inst_request_code_index_fetch);

  with r.state select
    c.state_next <= (state_index_idle       => not c.incoming_request,
                     state_index_mmu_access => (c.incoming_request and
                                                cpu_l1mem_inst_pass_ctrl_in.mmuen
                                                ),
                     state_index_bus_access => (c.incoming_request and
                                                not cpu_l1mem_inst_pass_ctrl_in.mmuen
                                                )
                     ) when state_idle,
                    (state_index_idle       => (cpu_mmu_inst_ctrl_out.ready and
                                                not cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_valid) and
                                                not c.incoming_request
                                                ),
                     state_index_mmu_access => (not cpu_mmu_inst_ctrl_out.ready or
                                                (not cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_valid) and
                                                 c.incoming_request)
                                                ),
                     state_index_bus_access => cpu_mmu_inst_ctrl_out.ready
                     ) when state_mmu_access,
                    (state_index_idle       => (r.bus_requested and
                                                sys_slave_ctrl_out.ready and
                                                not c.incoming_request
                                                ),
                     state_index_mmu_access => (r.bus_requested and
                                                sys_slave_ctrl_out.ready and
                                                c.incoming_request and
                                                cpu_l1mem_inst_pass_ctrl_in.mmuen
                                                ),
                     state_index_bus_access => ((sys_slave_ctrl_out.ready and
                                                 c.incoming_request and
                                                 not cpu_l1mem_inst_pass_ctrl_in.mmuen
                                                 ) or
                                                not r.bus_requested or
                                                not sys_slave_ctrl_out.ready
                                                )
                     ) when state_bus_access,
                    (others => 'X') when others;

  c.mmu_request <= r.state(state_index_idle) and c.incoming_request;

  with r.state select
    c.bus_request <= (c.incoming_request and
                      not cpu_l1mem_inst_pass_ctrl_in.mmuen)   when state_idle,
                     cpu_mmu_inst_ctrl_out.ready         when state_mmu_access,
                     (not r.bus_requested or
                      (c.incoming_request and
                       not cpu_l1mem_inst_pass_ctrl_in.mmuen)) when state_bus_access,
                     'X'                                       when others;
  c.use_incoming_request <= (r.state(state_index_idle) or
                             (r.state(state_index_bus_access) and sys_slave_ctrl_out.ready));
  with r.state select
    c.bus_requested_next <= not cpu_l1mem_inst_pass_ctrl_in.mmuen and sys_slave_ctrl_out.ready when state_idle,
                            cpu_mmu_inst_ctrl_out.ready and sys_slave_ctrl_out.ready     when state_mmu_access,
                            r.bus_requested or sys_slave_ctrl_out.ready                        when state_bus_access,
                            'X'                                                              when others;

  be_0 : if cpu_inst_endianness = little_endian generate
    c.be <= '0';
  end generate;
  be_1 : if cpu_inst_endianness = big_endian generate
    c.be <= '1';
  end generate;
  
  with c.use_incoming_request select
    c.mmuen <= cpu_l1mem_inst_pass_ctrl_in.mmuen when '1',
               r.mmuen                           when '0',
               'X'                               when others;
  with c.use_incoming_request select
    c.cacheen <= cpu_l1mem_inst_pass_ctrl_in.cacheen when '1',
                 r.cacheen                           when '0',
                 'X'                                 when others;
  with c.use_incoming_request select
    c.priv <= cpu_l1mem_inst_pass_ctrl_in.priv when '1',
              r.priv                           when '0',
              'X'                              when others;

  incoming_paddr_vaddr_bigger : if cpu_ivaddr_bits >= cpu_ipaddr_bits generate
    c.incoming_paddr <= cpu_l1mem_inst_pass_dp_in.vaddr(cpu_ipaddr_bits-1 downto 0);
  end generate;
  incoming_paddr_vaddr_smaller : if cpu_ivaddr_bits < cpu_ipaddr_bits generate
    c.incoming_paddr(cpu_ipaddr_bits-1 downto cpu_ivaddr_bits) <= (others => '0');
    c.incoming_paddr(cpu_ivaddr_bits-1 downto 0) <= cpu_l1mem_inst_pass_dp_in.vaddr;
  end generate;
  mmu_paddr_gen_0 : if cpu_ppn_bits = 0 generate
    c.mmu_paddr  <= r.paddr;
  end generate;
  mmu_paddr_gen_n : if cpu_ppn_bits > 0 generate
    c.mmu_paddr <= cpu_mmu_inst_dp_out.ppn & r.paddr(cpu_ipoffset_bits-1 downto 0);
  end generate;
  
  with r.state select
    c.bus_paddr_sel <= paddr_sel_incoming when state_idle,
                       paddr_sel_mmu      when state_mmu_access,
                       (paddr_sel_index_reg  => not r.bus_requested or not sys_slave_ctrl_out.ready,
                        paddr_sel_index_pipe => r.bus_requested and sys_slave_ctrl_out.ready,
                        paddr_sel_index_mmu  => '0'
                        )                 when state_bus_access,
                       (others => 'X')    when others;
  
  with c.bus_paddr_sel select
    c.bus_paddr <= r.paddr          when paddr_sel_reg,
                   c.incoming_paddr when paddr_sel_incoming,
                   c.mmu_paddr      when paddr_sel_mmu,
                   (others => 'X')  when others;
  c.paddr_next <= c.bus_paddr;
  
  cpu_l1mem_inst_pass_ctrl_out <= (
    ready => (sys_slave_ctrl_out.ready and
              not r.state(state_index_mmu_access)),
    result => (
      cpu_l1mem_inst_result_code_index_valid => (
        not ((r.state(state_index_mmu_access) and
              r.mmuen and
              cpu_mmu_inst_ctrl_out.ready and
              not cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_valid)) or
             (r.state(state_index_bus_access) and
              sys_slave_ctrl_out.ready and
              sys_slave_ctrl_out.error)
             )
        ),
      cpu_l1mem_inst_result_code_index_error => (
        (r.state(state_index_mmu_access) and
         r.mmuen and
         cpu_mmu_inst_ctrl_out.ready and
         not cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_error)) or
        (r.state(state_index_bus_access) and
         sys_slave_ctrl_out.ready and
         sys_slave_ctrl_out.error)
        ),
      cpu_l1mem_inst_result_code_index_tlbmiss => (
        (r.state(state_index_mmu_access) and
         r.mmuen and
         cpu_mmu_inst_ctrl_out.ready and
         not cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_tlbmiss))
        ),
      cpu_l1mem_inst_result_code_index_pf => (
        (r.state(state_index_mmu_access) and
         r.mmuen and
         cpu_mmu_inst_ctrl_out.ready and
         not cpu_mmu_inst_ctrl_out.result(cpu_mmu_inst_result_code_index_pf))
        )
      )
    );
  
  cpu_l1mem_inst_pass_dp_out <= (
    paddr => r.paddr,
    data => sys_slave_dp_out.data(cpu_inst_bits-1 downto 0)
    );

  cpu_mmu_inst_ctrl_in <= (
    request => c.mmu_request,
    mmuen => c.mmuen
    );

  sys_master_ctrl_out <= (
    request   => c.bus_request,
    be        => c.be,
    write     => '0',
    cacheable => c.cacheen,
    priv      => c.priv, -- TODO
    inst      => '1',
    burst     => '0',
    bwrap      => 'X',
    bcycles   => (others => 'X')
    );

  sys_master_dp_out <= (
    size  => std_ulogic_vector(to_unsigned(cpu_log2_inst_bytes, sys_transfer_size_bits)),
    paddr => (sys_paddr_bits-1 downto cpu_paddr_bits => '0') & c.bus_paddr & (cpu_log2_inst_bytes-1 downto 0 => '0'),
    data  => (others => 'X')
    );
  
  r_next <= (
    state => c.state_next,
    bus_requested => c.bus_requested_next,
    mmuen => c.mmuen,
    cacheen => c.cacheen,
    priv => c.priv,
    paddr => c.paddr_next
    );
  
  seq : process (clk) is
  begin
    if rising_edge(clk) then
      case rstn is
        when '1' =>
          r <= r_next;
        when '0' =>
          r <= reg_init;
        when others =>
          r <= reg_x;
      end case;
    end if;
  end process;
  
end;
