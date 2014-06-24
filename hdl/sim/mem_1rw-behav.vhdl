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


use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library util;
use util.names_pkg.all;
use util.numeric_pkg.all;
use util.io_pkg.all;

use work.options_pkg.all;

architecture behav of mem_1rw is

  constant addr_lo_bits : integer := addr_bits / 2;
  constant addr_hi_bits : integer := addr_bits - addr_lo_bits;
  
  subtype addr_type is std_ulogic_vector(addr_bits-1 downto 0);
  subtype addr_hi_type is std_ulogic_vector(addr_hi_bits-1 downto 0);
  subtype addr_lo_type is std_ulogic_vector(addr_lo_bits-1 downto 0);

  constant byte_bits : integer := 2**log2_byte_bits;
  constant bus_bytes : integer := 2**log2_bus_bytes;
  constant bus_bits  : integer := 2**(log2_byte_bits+log2_bus_bytes);
  constant size_bits : integer := bitsize(log2_bus_bytes);

  subtype byte_type is std_ulogic_vector(byte_bits-1 downto 0);
  subtype bus_type is std_ulogic_vector(bus_bits-1 downto 0);
  subtype size_type is std_ulogic_vector(size_bits-1 downto 0);
  
  constant entry_size   : integer := 2**addr_lo_bits;
  constant num_entries  : integer := 2**addr_hi_bits;
  type entry_type is array (0 to entry_size-1) of std_ulogic_vector(byte_bits-1 downto 0);
  type entry_ptr is access entry_type;
  type entry_array_type is array (0 to num_entries-1) of entry_ptr;

  subtype mask_type is std_ulogic_vector(2**log2_bus_bytes-1 downto 0);

  procedure check_addr(v_addr : in addr_type) is
    variable templine : line;
  begin
    
    if is_x(v_addr) then
      write(templine, string'("invalid address: "));
      write(templine, v_addr);
      assert not is_x(v_addr) report templine.all severity warning;
      deallocate(templine);
    end if;
    
  end procedure check_addr;

  procedure check_size(v_size : in size_type) is
    variable templine : line;
  begin
    
    if is_x(v_size) or to_integer(unsigned(v_size)) > log2_bus_bytes then
      write(templine, string'("invalid size: "));
      write(templine, v_size);
      assert not is_x(v_size) report templine.all severity warning;
      deallocate(templine);
    end if;
    
  end procedure check_size;

  procedure check_be(v_be : in std_ulogic) is
    variable templine : line;
  begin
    
    if is_x(v_be) then
      write(templine, string'("invalid endianness flag: "));
      write(templine, v_be);
      assert not is_x(v_be) report templine.all severity warning;
      deallocate(templine);
    end if;
    
  end procedure check_be;

  procedure check_align(v_addr : in addr_type; v_size : in size_type) is
    variable templine : line;
    variable v_mask : addr_type;
    variable v_size_n : integer;
  begin

    v_mask := (others => '0');
    v_size_n := to_integer(unsigned(v_size));
    if v_size_n > 0 then
      for n in v_size_n-1 downto 0 loop
        v_mask(n) := '1';
      end loop;
    end if;
    
    if (v_addr and v_mask) /= (addr_bits-1 downto 0 => '0') then
      write(templine, string'("invalid alignment: addr "));
      write(templine, v_addr);
      write(templine, string'(", size "));
      write(templine, v_size);
      assert (v_addr and v_mask) /= (addr_bits-1 downto 0 => '0') report templine.all severity warning;
      deallocate(templine);
    end if;
    
  end procedure check_align;

  procedure split_addr(v_addr : in addr_type;
                       v_addr_hi : out addr_hi_type;
                       v_addr_lo : out addr_lo_type) is
  begin
    v_addr_hi := v_addr(addr_bits-1 downto addr_lo_bits);
    v_addr_lo := v_addr(addr_lo_bits-1 downto 0);
  end procedure split_addr;
  
  type memory_type is protected
    procedure clear;
    procedure init_addr(v_addr : in addr_type);
    procedure read_byte(v_addr : in addr_type;
                        v_byte : out byte_type);
    procedure write_byte(v_addr : in addr_type;
                         v_byte : in byte_type);
  end protected;
  
  type memory_type is protected body
    variable entries : entry_array_type;
    
    procedure clear is
    begin

      for n in 0 to num_entries-1 loop

        if entries(n) /= null then
          deallocate(entries(n));
          entries(n) := null;
        end if;
        
      end loop;

    end procedure clear;

    procedure init_addr(v_addr : in addr_type) is
      variable v_addr_hi : addr_hi_type;
      variable v_addr_lo : addr_lo_type;
    begin

      split_addr(v_addr, v_addr_hi, v_addr_lo);

      if entries(to_integer(unsigned(v_addr_hi))) = null then
        
        entries(to_integer(unsigned(v_addr_hi))) := new entry_type'(others => (others => '0'));
        
      end if;
      
    end procedure init_addr;
  
    procedure read_byte(v_addr : in addr_type;
                        v_byte : out byte_type) is
      variable v_addr_hi : addr_hi_type;
      variable v_addr_lo : addr_lo_type;
    begin

      check_addr(v_addr);
      init_addr(v_addr);

      if not is_x(v_addr) then
        split_addr(v_addr, v_addr_hi, v_addr_lo);
        v_byte := entries(to_integer(unsigned(v_addr_hi)))(to_integer(unsigned(v_addr_lo)));
      else
        v_byte := (others => 'X');
      end if;
      
    end procedure read_byte;
    
    procedure write_byte(v_addr : in addr_type;
                         v_byte : in byte_type) is
      variable v_addr_hi : addr_hi_type;
      variable v_addr_lo : addr_lo_type;
      variable v_templine : line;
    begin
      
      check_addr(v_addr);
      init_addr(v_addr);
      
      if not is_x(v_addr) then
        --if is_x(v_byte) then
        --  write(v_templine, string'("warning: writing uninitialized data to address "));
        --  write(v_templine, v_addr);
        --  write(v_templine, string'(" (data: "));
        --  write(v_templine, v_byte);
        --  write(v_templine, string'(")"));
        --  report v_templine.all severity warning;
        --  deallocate(v_templine);
        --end if;

        split_addr(v_addr, v_addr_hi, v_addr_lo);
        entries(to_integer(unsigned(v_addr_hi)))(to_integer(unsigned(v_addr_lo))) := v_byte;
      end if;
      
    end procedure write_byte;
    
  end protected body;
  
  shared variable memory : memory_type;

  procedure read_bus(v_addr : in addr_type;
                     v_size : in size_type;
                     v_be   : in std_ulogic;
                     v_bus  : out bus_type) is
    variable v_byte_addr : addr_type;
    variable v_byte : std_ulogic_vector(byte_bits-1 downto 0);
    variable v_bus_tmp : bus_type;
    variable v_size_n : integer;
    variable v_bus_off : integer;
  begin
    
    check_addr(v_addr);
    check_size(v_size);
    check_be(v_be);
    check_align(v_addr, v_size);

    v_bus_tmp := (others => 'X');
    
    v_size_n := 2**to_integer(unsigned(v_size));

    v_bus_off := 0;
    while v_bus_off <= v_size_n-1 loop
      
      v_byte_addr := std_ulogic_vector(unsigned(v_addr) + to_unsigned(v_bus_off, addr_bits));
      
      memory.read_byte(v_byte_addr, v_byte);
      
      if v_be = '1' then
        v_bus_tmp(v_size_n*byte_bits-byte_bits*v_bus_off-1 downto v_size_n*byte_bits-byte_bits*(v_bus_off+1)) := v_byte;
      else
        v_bus_tmp(byte_bits*(v_bus_off+1)-1 downto byte_bits*v_bus_off) := v_byte;
      end if;

      v_bus_off := v_bus_off + 1;
      
    end loop;
    
    v_bus := v_bus_tmp;
    
  end procedure read_bus;

  procedure write_bus(v_addr : in addr_type;
                      v_size  : in size_type;
                      v_be    : std_ulogic;
                      v_bus  : in bus_type) is
    variable v_byte_addr : addr_type;
    variable v_byte : std_ulogic_vector(byte_bits-1 downto 0);
    variable v_size_n : integer;
    variable v_bus_off : integer;
  begin
    
    check_addr(v_addr);
    check_size(v_size);
    check_be(v_be);
    check_align(v_addr, v_size);

    v_size_n := 2**to_integer(unsigned(v_size));

    v_bus_off := 0;
    while v_bus_off <= v_size_n-1 loop
      
      v_byte_addr := std_ulogic_vector(unsigned(v_addr) + to_unsigned(v_bus_off, addr_bits));
      
      if v_be = '1' then
        v_byte := v_bus(v_size_n*byte_bits-byte_bits*v_bus_off-1 downto v_size_n*byte_bits-byte_bits*(v_bus_off+1));
      else
        v_byte := v_bus(byte_bits*(v_bus_off+1)-1 downto byte_bits*v_bus_off);
      end if;

      memory.write_byte(v_byte_addr, v_byte);

      v_bus_off := v_bus_off + 1;
      
    end loop;
    
  end procedure write_bus;

  procedure read_srec is

    variable filename : line;
    file srecfile : text;
    variable c : character;
    variable srecline : line;
    variable srectype : character;
    variable srecdatalenv : std_ulogic_vector(byte_bits-1 downto 0);
    variable srecdatalen : integer;
    variable srecaddrtmp : std_ulogic_vector(31 downto 0);
    variable srecaddr : addr_type;
    variable srecbyte : byte_type;
    variable templine : line;
    
  begin

    filename := new string'(option(entity_path_name(mem_1rw'path_name) & ":srec_file"));
    assert filename.all /= ""
      report "option " & entity_path_name(mem_1rw'path_name) & ":srec_file not set"
      severity failure;
    file_open(srecfile, filename.all, read_mode);
    deallocate(filename);
    
    while not endfile(srecfile) loop

      readline(srecfile, srecline);
      
      --report "read line: " & srecline.all;
      
      read(srecline, c);

      if c /= 'S' and c /= 's' then
        next;
      end if;
      
      read(srecline, srectype);
      case srectype is
        when '1'|'2'|'3' =>
          null;
        when others =>
          next;
      end case;
      
      hread(srecline, srecdatalenv);
      srecdatalen := to_integer(unsigned(srecdatalenv));

      srecaddrtmp := (others => '0');
      case srectype is
        when '1' =>
          hread(srecline, srecaddrtmp(15 downto 0));
          srecdatalen := srecdatalen - 2;
        when '2' =>
          hread(srecline, srecaddrtmp(23 downto 0));
          srecdatalen := srecdatalen - 3;
        when '3' =>
          hread(srecline, srecaddrtmp(31 downto 0));
          srecdatalen := srecdatalen - 4;
        when others =>
          next;
      end case;
      
      if addr_bits = 32 then
        srecaddr := srecaddrtmp;
      elsif addr_bits > 32 then
        srecaddr(addr_bits-1 downto 32) := (others => '0');
        srecaddr(31 downto 0) := srecaddrtmp;
      else
        srecaddr(addr_bits-1 downto 0) := srecaddrtmp(addr_bits-1 downto 0);
      end if;
      
      -- ignore checksum byte
      srecdatalen := srecdatalen - 1;

      for n in 0 to srecdatalen-1 loop

        hread(srecline, srecbyte);

        memory.write_byte(srecaddr, srecbyte);
        
        srecaddr := std_ulogic_vector(unsigned(srecaddr) + to_unsigned(1, 32));
        
      end loop;
      
    end loop;
    --report "done.";

    file_close(srecfile);

  end procedure read_srec;

begin

  seq : process(clk)
    
    variable v_dout : bus_type;
    
    variable templine : line;

  begin

    if rising_edge(clk) then

      case rstn is

        when '0' =>

          memory.clear;
          read_srec;
        
        when '1' =>

          case en is
            
            when '1' =>

              case we is
                
                when '1' =>
                  write_bus(addr, size, be, din);
                  
                when '0' =>
                  read_bus(addr, size, be, v_dout);
                  dout <= v_dout;
                  
                when others =>
                  assert not is_x(we)
                    report "we is metavalue"
                    severity warning;
                  
              end case;
              
            when '0' =>

            when others =>
              assert not is_x(en)
                report "en is metavalue"
                severity warning;
              
          end case;

        when others =>
          assert not is_x(rstn)
            report "rstn is metavalue"
            severity warning;
        
      end case;

    end if;

  end process;

end;
