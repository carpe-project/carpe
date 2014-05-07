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

use std.textio.all;

use work.types_pkg.all;

package io_pkg is

  procedure write (l: inout line;
                   value: in std_ulogic_vector;
                   justified: in side := right;
                   field: in width := 0);
  procedure write (l: inout line;
                   value: in std_ulogic;
                   justified: in side := right;
                   field: in width := 0);
  procedure write (l: inout line;
                   value: in std_logic_vector;
                   justified: in side := right;
                   field: in width := 0);

  procedure hread(l:inout line; value:out bit_vector);
  procedure hread(l:inout line; value:out std_ulogic_vector);
  procedure hread(l:inout line; value:out std_logic_vector);
  procedure hwrite(l:inout line; value:in bit_vector; justified:in side := right; field:in width := 0);
  procedure hwrite(l:inout line; value:in std_ulogic_vector; justified:in side := right; field:in width := 0);
  procedure hwrite(l:inout line; value:in std_logic_vector; justified:in side := right; field:in width := 0);
  
end package;

package body io_pkg is

  procedure write (l: inout line;
                   value: in std_ulogic;
                   justified: in side := right;
                   field: in width := 0) is
    variable str : string(1 to 1);
  begin
    str(1) := std_ulogic_to_character(value);
    write (l, str, justified, field);
  end procedure;
  
  procedure write (l: inout line;
                   value: in std_ulogic_vector;
                   justified: in side := right;
                   field: in width := 0) is
    constant length : natural := value'length;
    alias n_value : std_ulogic_vector (1 to value'length) is value;
    variable str : string (1 to length);
  begin
    for i in str'range loop
      str (i) := std_ulogic_to_character (n_value (i));
    end loop;
    write (l, str, justified, field);
  end procedure;

  procedure write (l: inout line;
                   value: in std_logic_vector;
                   justified: in side := right;
                   field: in width := 0) is
    constant length : natural := value'length;
    alias n_value : std_logic_vector (1 to value'length) is value;
    variable str : string (1 to length);
  begin
    for i in str'range loop
      str (i) := std_logic_to_character (n_value (i));
    end loop;
    write (l, str, justified, field);
  end procedure; 

  -- applies to char2quadbits and hread
  -- Copyright (c) 1990, 1991, 1992 by Synopsys, Inc.  All rights reserved.
  -- 
  -- This source file may be used and distributed without restriction 
  -- provided that this copyright statement is not removed from the file 
  -- and that any derivative work contains this copyright notice.
  procedure char2quadbits(c: character; 
                          result: out bit_vector(3 downto 0);
                          good: out boolean;
                          issue_error: in boolean) is
  begin
    case c is
      when '0' => result :=  x"0"; good := true;
      when '1' => result :=  x"1"; good := true;
      when '2' => result :=  x"2"; good := true;
      when '3' => result :=  x"3"; good := true;
      when '4' => result :=  x"4"; good := true;
      when '5' => result :=  x"5"; good := true;
      when '6' => result :=  x"6"; good := true;
      when '7' => result :=  x"7"; good := true;
      when '8' => result :=  x"8"; good := true;
      when '9' => result :=  x"9"; good := true;
      when 'A' => result :=  x"A"; good := true;
      when 'B' => result :=  x"B"; good := true;
      when 'C' => result :=  x"C"; good := true;
      when 'D' => result :=  x"D"; good := true;
      when 'E' => result :=  x"E"; good := true;
      when 'F' => result :=  x"F"; good := true;
                  
      when 'a' => result :=  x"A"; good := true;
      when 'b' => result :=  x"B"; good := true;
      when 'c' => result :=  x"C"; good := true;
      when 'd' => result :=  x"D"; good := true;
      when 'e' => result :=  x"E"; good := true;
      when 'f' => result :=  x"F"; good := true;
      when others =>
        if issue_error then 
          assert false report
            "hread error: read a '" & c &
            "', expected a hex character (0-f).";
        end if;
        good := false;
    end case;
  end;
  
  procedure hread(l:inout line; value:out bit_vector) is
    variable ok: boolean;
    variable c:  character;
    constant ne: integer := value'length/4;
    variable bv: bit_vector(0 to value'length-1);
    variable s:  string(1 to ne-1);
  begin
    if value'length mod 4 /= 0 then
      assert false report 
        "hread error: trying to read vector " &
        "with an odd (non multiple of 4) length";
      return;
    end if;

    loop                                    -- skip white space
      read(l,c);
      exit when ((c /= ' ') and (c /= cr) and (c /= ht));
    end loop;

    char2quadbits(c, bv(0 to 3), ok, true);
    if not ok then 
      return;
    end if;

    read(l, s, ok);
    if not ok then
      assert false 
        report "hread error: failed to read the string";
      return;
    end if;

    for i in 1 to ne-1 loop
      char2quadbits(s(i), bv(4*i to 4*i+3), ok, true);
      if not ok then
        return;
      end if;
    end loop;
    value := bv;
  end hread; 
  
  procedure hread(l:inout line; value:out std_ulogic_vector) is
    variable tmp: bit_vector(value'length-1 downto 0);
  begin
    hread(l, tmp);
    value := to_x01(tmp);
  end hread;

  procedure hread(l:inout line; value:out std_logic_vector) is
    variable tmp: bit_vector(value'length-1 downto 0);
  begin
    hread(l, tmp);
    value := to_x01(tmp);
  end hread;

  procedure hwrite(l:inout line; value:in bit_vector; justified:in side := right; field:in width := 0) is
    variable quad: bit_vector(0 to 3);
    constant ne:   integer := value'length/4;
    variable bv:   bit_vector(0 to value'length-1) := value;
    variable s:    string(1 to ne);
  begin
    if value'length mod 4 /= 0 then
      assert false report 
        "hwrite error: trying to read vector " &
        "with an odd (non multiple of 4) length";
      return;
    end if;

    for i in 0 to ne-1 loop
      quad := bv(4*i to 4*i+3);
      case quad is
        when x"0" => s(i+1) := '0';
        when x"1" => s(i+1) := '1';
        when x"2" => s(i+1) := '2';
        when x"3" => s(i+1) := '3';
        when x"4" => s(i+1) := '4';
        when x"5" => s(i+1) := '5';
        when x"6" => s(i+1) := '6';
        when x"7" => s(i+1) := '7';
        when x"8" => s(i+1) := '8';
        when x"9" => s(i+1) := '9';
        when x"a" => s(i+1) := 'a';
        when x"b" => s(i+1) := 'b';
        when x"c" => s(i+1) := 'c';
        when x"d" => s(i+1) := 'd';
        when x"e" => s(i+1) := 'e';
        when x"f" => s(i+1) := 'f';
      end case;
    end loop;
    write(l, s, justified, field);
  end hwrite; 

  procedure hwrite(l:inout line; value:in std_ulogic_vector;
  justified:in side := right; field:in width := 0) is
  begin
    hwrite(l, to_bitvector(value),justified, field);
  end hwrite;

  procedure hwrite(l:inout line; value:in std_logic_vector;
  justified:in side := right; field:in width := 0) is
  begin
    hwrite(l, to_bitvector(value), justified, field);
  end hwrite;

end package body;
