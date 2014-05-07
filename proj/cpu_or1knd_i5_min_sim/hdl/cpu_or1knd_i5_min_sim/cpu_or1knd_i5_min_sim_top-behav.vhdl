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

-- CARPE OR1KND in-order 5-stage minimal simulator


use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library util;
use util.types_pkg.all;
use util.io_pkg.all;
use util.numeric_pkg.all;
use util.logic_pkg.all;
use util.names_pkg.all;

library isa;
use isa.or1k_pkg.all;

library sys;
use sys.sys_config_pkg.all;
use sys.sys_pkg.all;

library cpu_or1knd_i5;
use cpu_or1knd_i5.cpu_or1knd_i5_config_pkg.all;
use cpu_or1knd_i5.cpu_or1knd_i5_pkg.all;

library sim;
use sim.options_pkg.all;
use sim.monitor_pkg.all;

library tech;

use work.cpu_or1knd_i5_min_sim_config_pkg.all;

architecture behav of cpu_or1knd_i5_min_sim_top is
  
  type request_type is record
    valid : std_ulogic;
    size : sys_transfer_size_type;
    be : std_ulogic;
    write : std_ulogic;
    cacheable : std_ulogic;
    priv : std_ulogic;
    inst : std_ulogic;
    burst : std_ulogic;
    bwrap : std_ulogic;
    bcycles : sys_burst_cycles_type;
    paddr : sys_paddr_type;
    data : sys_bus_type;
    eta : std_ulogic_vector(cpu_or1knd_i5_min_sim_mem_latency-1 downto 0);
    burst_status : std_ulogic_vector(sys_max_burst_cycles-1 downto 0);
  end record;
  constant request_init : request_type := (
    valid => '0',
    size => (others => 'X'),
    be => 'X',
    write => 'X',
    cacheable => 'X',
    priv => 'X',
    inst => 'X',
    burst => 'X',
    bwrap => 'X',
    bcycles => (others => 'X'),
    paddr => (others => 'X'),
    data => (others => 'X'),
    eta => (others => 'X'),
    burst_status => (others => 'X')
    );

  type comb_type is record
    sys_master_ctrl_out : sys_master_ctrl_out_type;
    sys_master_dp_out   : sys_master_dp_out_type;
    sys_slave_ctrl_out  : sys_slave_ctrl_out_type;
    sys_slave_dp_out    : sys_slave_dp_out_type;
    
    a_new_request_bcycles_dec  : std_ulogic_vector(sys_max_burst_cycles-1 downto 0);
    a_new_request_burst_status : std_ulogic_vector(sys_max_burst_cycles-1 downto 0);
    a_mem_en : std_ulogic;
    a_burst : std_ulogic;
    a_request : request_type;
    a_request_fast : std_ulogic;
    b_request_complete : std_ulogic;
    b_mem_dout : sys_bus_type;
  end record;
  signal c : comb_type;

  type register_type is record
    b_request : request_type;
    b_burst : std_ulogic;
  end record;
  constant r_init : register_type := (
    b_request => request_init,
    b_burst => '0'
    );
  signal r, r_next : register_type;

  signal clk           : std_ulogic := '0';
  signal rstn          : std_ulogic := '1';

  procedure process_monitor_events(file monitor_output_file : text;
                                   variable monitor_exit : out boolean) is
    variable l : line;
  begin

    while monitor_has_event loop

      case monitor_event_code is
        when monitor_event_code_error =>
        when monitor_event_code_cycle =>
        when monitor_event_code_reset =>
        when monitor_event_code_exit =>
          monitor_exit := true;
        when monitor_event_code_watch =>
      end case;
      
      write(l,
            string'("""") &
            time'image(monitor_event_timestamp) &
            string'(""" """) &
            monitor_event_instance &
            string'(""" ")
            );
      case monitor_event_code is
        when monitor_event_code_error =>
          write(l, string'("error"));
        when monitor_event_code_cycle =>
          write(l, string'("cycle"));
        when monitor_event_code_reset =>
          write(l, string'("reset"));
        when monitor_event_code_exit =>
          write(l, string'("exit"));
        when monitor_event_code_watch =>
          write(l, string'("watch"));
      end case;
      write(l,
            string'(" """) &
            monitor_event_name &
            string'(""" """)
            );
      write(l,
            monitor_event_data);
      write(l,
            string'("""")
            );

      writeline(monitor_output_file, l);
      deallocate(l);

      monitor_event_finish;
      
    end loop;

  end;

begin

  c.b_request_complete <= (
    not r.b_request.valid or
    r.b_request.eta(cpu_or1knd_i5_min_sim_mem_latency-1)
    );

  c.a_request.valid <= (
    (r.b_request.valid and not c.b_request_complete) or
    c.sys_master_ctrl_out.request
    );

  with c.b_request_complete select
    c.a_request.size      <= c.sys_master_dp_out.size        when '1',
                             r.b_request.size                        when '0',
                             (others => 'X')                         when others;
  with c.b_request_complete select
    c.a_request.be        <= c.sys_master_ctrl_out.be        when '1',
                             r.b_request.be                          when '0',
                             'X'                                     when others;
  with c.b_request_complete select
    c.a_request.write     <= c.sys_master_ctrl_out.write     when '1',
                             r.b_request.write                       when '0',
                             'X'                                     when others;
  with c.b_request_complete select
    c.a_request.cacheable <= c.sys_master_ctrl_out.cacheable when '1',
                             r.b_request.cacheable                   when '0',
                             'X'                                     when others;
  with c.b_request_complete select
    c.a_request.priv      <= c.sys_master_ctrl_out.priv      when '1',
                             r.b_request.priv                        when '0',
                             'X'                                     when others;
  with c.b_request_complete select
    c.a_request.inst      <= c.sys_master_ctrl_out.inst      when '1',
                             r.b_request.inst                        when '0',
                             'X'                                     when others;
  with c.b_request_complete select
    c.a_request.burst     <= c.sys_master_ctrl_out.burst     when '1',
                             r.b_request.burst                       when '0',
                             'X'                                     when others;
  with c.b_request_complete select
    c.a_request.bwrap     <= c.sys_master_ctrl_out.bwrap     when '1',
                             r.b_request.bwrap                       when '0',
                             'X'                                     when others;
  with c.b_request_complete select
    c.a_request.bcycles   <= c.sys_master_ctrl_out.bcycles   when '1',
                             r.b_request.bcycles                     when '0',
                             (others => 'X')                         when others;
  with c.b_request_complete select
    c.a_request.paddr     <= c.sys_master_dp_out.paddr       when '1',
                             r.b_request.paddr                       when '0',
                             (others => 'X')                         when others;
  with c.b_request_complete select
    c.a_request.data      <= c.sys_master_dp_out.data        when '1',
                             r.b_request.data                        when '0',
                             (others => 'X')                         when others;

  a_request_eta_gen_gt_1 : if cpu_or1knd_i5_min_sim_mem_latency > 1 generate
    c.a_request_fast <= logic_if(c.a_request.write, c.a_request.burst, r.b_burst);
    with c.b_request_complete select
      c.a_request.eta       <=
        (cpu_or1knd_i5_min_sim_mem_latency-1 => c.a_request_fast,
         0                                   => not c.a_request_fast,
         others                              => '0'
         ) when '1',
        (r.b_request.eta(cpu_or1knd_i5_min_sim_mem_latency-2 downto 0) & '0') when '0',
        (others => 'X')                                                       when others;
  end generate;
  a_request_eta_gen_eq_1 : if cpu_or1knd_i5_min_sim_mem_latency <= 1 generate
    c.a_request.eta(0) <= '1';
  end generate;

  c.a_burst <= logic_if(c.b_request_complete and c.a_request.valid,
                        c.a_request.burst,
                        r.b_burst);
  
  a_new_request_bcycles_decoder : entity tech.decoder(rtl)
    generic map (
      output_bits => sys_max_burst_cycles
      )
    port map (
      datain  => c.sys_master_ctrl_out.bcycles,
      dataout => c.a_new_request_bcycles_dec
      );

  with r.b_request.burst select
    c.a_new_request_burst_status <= ('X' & r.b_request.burst_status(sys_max_burst_cycles-1 downto 1)) when '1',
                                    c.a_new_request_bcycles_dec when '0',
                                    (others => 'X') when others;
  with c.b_request_complete select
    c.a_request.burst_status <= c.a_new_request_burst_status when '1',
                                r.b_request.burst_status     when '0',
                                (others => 'X')              when others;

  c.a_mem_en <= c.a_request.valid and c.a_request.eta(cpu_or1knd_i5_min_sim_mem_latency-1);

  c.sys_slave_ctrl_out <= (
    ready => c.b_request_complete,
    error => '0'
    );
  c.sys_slave_dp_out <= (
    data => c.b_mem_dout
    );
  
  r_next.b_request <= c.a_request;
  r_next.b_burst <= c.a_burst;

  core : entity cpu_or1knd_i5.cpu_or1knd_i5_core(rtl)
    port map (
      clk                           => clk,
      rstn                          => rstn,
      sys_master_ctrl_out   => c.sys_master_ctrl_out,
      sys_master_dp_out     => c.sys_master_dp_out,
      sys_slave_ctrl_out    => c.sys_slave_ctrl_out,
      sys_slave_dp_out      => c.sys_slave_dp_out
      );

  a_mem_en_watch : block
    signal watch_data : std_ulogic_vector(0 downto 0);
  begin
    watch_data <= (0 => c.a_mem_en);
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_min_sim_top'path_name),
        name => "a_mem_en",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;

  a_mem_write_watch : block
    signal watch_data : std_ulogic_vector(0 downto 0);
  begin
    watch_data <= (0 => c.a_request.write);
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_min_sim_top'path_name),
        name => "a_mem_write",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;

  a_mem_be_watch : block
    signal watch_data : std_ulogic_vector(0 downto 0);
  begin
    watch_data <= (0 => c.a_request.be);
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_min_sim_top'path_name),
        name => "a_mem_be",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;
  
  a_mem_size_watch : block
    signal watch_data : std_ulogic_vector(c.a_request.size'length-1 downto 0);
  begin
    watch_data <= c.a_request.size;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_min_sim_top'path_name),
        name => "a_mem_size",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;
  
  a_mem_paddr_watch : block
    signal watch_data : std_ulogic_vector(c.a_request.paddr'length-1 downto 0);
  begin
    watch_data <= c.a_request.paddr;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_min_sim_top'path_name),
        name => "a_mem_paddr",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;
  
  a_mem_din_watch : block
    signal watch_data : std_ulogic_vector(c.a_request.data'length-1 downto 0);
  begin
    watch_data <= c.a_request.data;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_min_sim_top'path_name),
        name => "a_mem_din",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;
  
  mem : entity sim.mem_1rw(behav)
    generic map (
      addr_bits => sys_paddr_bits,
      log2_bus_bytes => sys_log2_bus_bytes
      )
    port map (
      clk  => clk,
      rstn => rstn,
      en   => c.a_mem_en,
      we   => c.a_request.write,
      be   => c.a_request.be,
      size => c.a_request.size,
      addr => c.a_request.paddr,
      din  => c.a_request.data,
      dout => c.b_mem_dout
      );

  b_mem_dout_watch : block
    signal watch_data : std_ulogic_vector(c.a_request.data'length-1 downto 0);
  begin
    watch_data <= c.a_request.data;
    inst : entity sim.monitor_sync_watch(behav)
      generic map (
        instance => entity_path_name(cpu_or1knd_i5_min_sim_top'path_name),
        name => "b_mem_dout",
        data_bits => watch_data'length
        )
      port map (
        clk  => clk,
        data => watch_data
        );
  end block;
  
  
  seq : process (clk) is
  begin
    
    if rising_edge(clk) then

      if rstn = '0' then
        r <= r_init;
      else
        r <= r_next;
      end if;
      
    end if;
    
  end process;

  run : process is
    variable monitor_output_filename : line;
    file monitor_output : text;
    variable monitor_exit : boolean;
    variable cycle_source : monitor_event_source_id_type;
    variable reset_source : monitor_event_source_id_type;
  begin

    report "options_filename: " & options_filename;
    options_read(options_filename);
    options_ready <= true;

    wait for 0 ns;

    if option(entity_path_name(cpu_or1knd_i5_min_sim_top'path_name) & ":monitor_enable") = "true" then
      
      report "enabling monitor for " & cpu_or1knd_i5_min_sim_top'path_name;
      monitor_output_filename := new string'(option(entity_path_name(cpu_or1knd_i5_min_sim_top'path_name) & ":monitor_output_filename"));
      assert monitor_output_filename.all /= ""
        report entity_path_name(cpu_or1knd_i5_min_sim_top'path_name) & ":monitor_output_filename is not set"
        severity failure;
      file_open(monitor_output, monitor_output_filename.all, write_mode);
      deallocate(monitor_output_filename);
      monitor_enable <= true;
      cycle_source := monitor_event_source(entity_path_name(cpu_or1knd_i5_min_sim_top'path_name), monitor_event_code_cycle, "");
      reset_source := monitor_event_source(entity_path_name(cpu_or1knd_i5_min_sim_top'path_name), monitor_event_code_reset, "");
      
    end if;
    
    clk <= '0';
    rstn <= '0';
    
    wait for 1000 ps;

    clk <= '1';

    wait for 250 ps;
    
    rstn <= '1';

    wait for 250 ps;
    
    clk <= '0';

    wait for 500 ps;

    if monitor_enable then
      monitor_event(reset_source, "");
    end if;
    
    while not monitor_exit loop
      
      clk <= not clk;
      wait for 500 ps;
      
      if monitor_enable and clk = '0' then
        monitor_event(cycle_source, "");
        process_monitor_events(monitor_output, monitor_exit);
      end if;
      
    end loop;

    monitor_finish;

    wait;

  end process;

  
end;
