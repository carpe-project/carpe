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


library sim;
use sim.options_pkg.all;
use sim.monitor_pkg.all;

architecture behav of monitor_sync_watch is
begin

  process is
    variable old_data : std_ulogic_vector(data_bits-1 downto 0);

    variable source : monitor_event_source_id_type;
  begin

    wait until options_ready and monitor_enable;
    
    if option(instance & ":" & name & ":monitor") = "true" then

      source := monitor_event_source(instance, monitor_event_code_watch, name);
      
      if option("verbose") = "true" then
        report "monitor " & instance & " " & name & " enabled";
      end if;
      monitor_event(source, data);
      
      loop
        wait until rising_edge(clk);
        if old_data /= data then
          monitor_event(source, data);
          old_data := data;
        end if;
      end loop;

    else

      if option("verbose") = "true" then
        report "monitor " & instance & " " & name & " disabled";
      end if;

      wait;

    end if;
      
  end process;

end;
