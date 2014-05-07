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

library util;
use util.types_pkg.all;
use util.numeric_pkg.all;

use work.sys_config_pkg.all;

package sys_pkg is

  constant sys_bus_bytes : natural := 2**sys_log2_bus_bytes;
  constant sys_bus_bits   : natural := sys_bus_bytes*byte_bits;

  constant sys_transfer_size_bits     : natural := bitsize(sys_log2_bus_bytes);
  constant sys_max_burst_cycles       : natural := 2**sys_log2_max_burst_cycles;
  constant sys_burst_cycles_bits      : natural := bitsize(sys_log2_max_burst_cycles);

  subtype sys_paddr_type         is std_ulogic_vector(sys_paddr_bits-1 downto 0);
  subtype sys_bus_bytes_type     is std_ulogic_vector2(sys_bus_bytes-1 downto 0, byte_bits-1 downto 0);
  subtype sys_bus_type           is std_ulogic_vector(sys_bus_bits-1 downto 0);
  subtype sys_transfer_size_type is std_ulogic_vector(sys_transfer_size_bits-1 downto 0);
  subtype sys_burst_cycles_type  is std_ulogic_vector(sys_burst_cycles_bits-1 downto 0);

  type sys_master_ctrl_out_type is record
    -- a request is being made
    request    : std_ulogic;
    -- big endian if true, otherwise little endian
    be         : std_ulogic;
    -- this request is a write
    write      : std_ulogic;
    -- this request is cacheable
    cacheable  : std_ulogic;
    -- this request is privileged
    priv       : std_ulogic;
    -- this request is for an instruction
    inst       : std_ulogic;
    -- this request is part of a burst, but not the last request
    burst      : std_ulogic;
    -- wrapping burst
    bwrap : std_ulogic;
    -- size of burst
    bcycles    : sys_burst_cycles_type;
  end record;
  
  type sys_master_dp_out_type is record
    size       : sys_transfer_size_type;
    paddr      : sys_paddr_type;
    data       : sys_bus_type;
  end record;
  
  type sys_slave_ctrl_out_type is record
    ready   : std_ulogic;
    error   : std_ulogic;
  end record;
  
  type sys_slave_dp_out_type is record
    data    : sys_bus_type;
  end record;

  type sys_master_ctrl_out_vector_type is array(natural range <>) of sys_master_ctrl_out_type;
  type sys_master_dp_out_vector_type is array(natural range <>) of sys_master_dp_out_type;
  type sys_slave_ctrl_out_vector_type is array(natural range <>) of sys_slave_ctrl_out_type;
  type sys_slave_dp_out_vector_type is array(natural range <>) of sys_slave_dp_out_type;

end package;
