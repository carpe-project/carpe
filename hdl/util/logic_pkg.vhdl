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

use work.numeric_pkg.all;

package logic_pkg is

  pure function reduce_or(v : std_ulogic_vector) return std_ulogic;
  pure function reduce_and(v : std_ulogic_vector) return std_ulogic;
  pure function reduce_xor(v : std_ulogic_vector) return std_ulogic;

  pure function all_ones(v : std_ulogic_vector) return std_ulogic;
  pure function all_zeros(v : std_ulogic_vector) return std_ulogic;
  
  pure function any_ones(v : std_ulogic_vector) return std_ulogic;
  pure function any_zeros(v : std_ulogic_vector) return std_ulogic;

  pure function logic_eq(v1 : std_ulogic_vector; v2 : std_ulogic_vector) return std_ulogic;
  pure function logic_ne(v1 : std_ulogic_vector; v2 : std_ulogic_vector) return std_ulogic;

  pure function logic_if(p : std_ulogic; c : std_ulogic; a : std_ulogic) return std_ulogic;
  pure function logic_if(p : std_ulogic; c : std_ulogic_vector; a : std_ulogic_vector) return std_ulogic_vector;

  pure function reverse(v : std_ulogic_vector) return std_ulogic_vector;

  pure function prioritize(v : std_ulogic_vector) return std_ulogic_vector;
  pure function prioritize_least(v : std_ulogic_vector) return std_ulogic_vector;
  pure function prioritize_none(v : std_ulogic_vector) return std_ulogic_vector;

  pure function is_1hot(v : std_ulogic_vector) return std_ulogic;

  pure function lfsr_taps(n : natural) return std_ulogic_vector;

end package;

package body logic_pkg is

  pure function reduce_or(v : std_ulogic_vector) return std_ulogic is
  begin
    for i in v'range loop
      case v(i) is
        when '1' =>
          return '1';
        when '0' =>
          null;
        when others =>
          return 'X';
      end case;
    end loop;
    return '0';
  end function;

  pure function reduce_and(v : std_ulogic_vector) return std_ulogic is
    variable ret : std_ulogic;
  begin
    for i in v'range loop
      case v(i) is
        when '0' =>
          return '0';
        when '1' =>
          null;
        when others =>
          return 'X';
      end case;
    end loop;
    return '1';
  end function;

  pure function reduce_xor(v : std_ulogic_vector) return std_ulogic is
    variable ret : std_ulogic;
  begin
    ret := '0';
    for i in v'range loop
      ret := ret xor v(i);
    end loop;
  end function;

  pure function all_ones(v : std_ulogic_vector) return std_ulogic is
  begin
    return reduce_and(v);
  end function;
  
  pure function all_zeros(v : std_ulogic_vector) return std_ulogic is
  begin
    return not reduce_or(v);
  end function;

  pure function any_ones(v : std_ulogic_vector) return std_ulogic is
  begin
    return reduce_or(v);
  end function;

  pure function any_zeros(v : std_ulogic_vector) return std_ulogic is
  begin
    return not reduce_and(v);
  end function;

  pure function logic_eq(v1 : std_ulogic_vector; v2 : std_ulogic_vector) return std_ulogic is
  begin
    -- pragma translate_off
    if is_x(v1) or is_x(v2) then
      return 'X';
    else
    -- pragma translate_on
      if v1 = v2 then
        return '1';
      else
        return '0';
      end if;
    -- pragma translate_off
    end if;
    -- pragma translate_on
  end function;

  pure function logic_ne(v1 : std_ulogic_vector; v2 : std_ulogic_vector) return std_ulogic is
  begin
    -- pragma translate_off
    if is_x(v1) or is_x(v2) then
      return 'X';
    else
    -- pragma translate_on
      if v1 /= v2 then
        return '1';
      else
        return '0';
      end if;
    -- pragma translate_off
    end if;
    -- pragma translate_on
  end function;

  pure function logic_if(p : std_ulogic; c : std_ulogic; a : std_ulogic) return std_ulogic is
    variable ret : std_ulogic;
  begin
    case p is
      when '1'    => ret := c;
      when '0'    => ret := a;
      when others => ret := 'X';
    end case;
    return ret;
  end function;

  pure function logic_if(p : std_ulogic; c : std_ulogic_vector; a : std_ulogic_vector) return std_ulogic_vector is
    variable ret : std_ulogic_vector(c'range);
  begin
    case p is
      when '1'    => ret := c;
      when '0'    => ret := a;
      when others => ret := (others => 'X');
    end case;
    return ret;
  end function;

  pure function reverse(v : std_ulogic_vector) return std_ulogic_vector is
    variable ret : std_ulogic_vector(v'range);
  begin
    for n in v'range loop
      ret(v'high - n + v'low) := ret(n);
    end loop;
    return ret;
  end function;

  -- prioritize (from highest index to lowest index) a bit vector.
  -- the result is a 1-hot vector
  -- clears all bits except the highest '1' on the input vector
  -- e.g. "0110010" => "0100000"
  --      "101" => "100"
  --      "000" => "XXX"
  pure function prioritize(v : std_ulogic_vector) return std_ulogic_vector is
    variable ret : std_ulogic_vector(v'range);
  begin
    ret := (others => '0');
    for i in v'high downto v'low loop
      case v(i) is
        when '1' =>
          ret(i) := '1';
          return ret;
        when '0' =>
          null;
        when others =>
          return (v'range => 'X');
      end case;
    end loop;
    return (v'range => 'X');
  end function;

  -- like prioritize, but chooses least significant set bit
  pure function prioritize_least(v : std_ulogic_vector) return std_ulogic_vector is
    variable ret : std_ulogic_vector(v'range);
  begin
    ret := (others => '0');
    for i in v'low to v'high loop
      case v(i) is
        when '1' =>
          ret(i) := '1';
          return ret;
        when '0' =>
          null;
        when others =>
          return (v'range => 'X');
      end case;
    end loop;
    return (v'range => 'X');
  end function;

  -- like prioritize, but allows no bits set
  pure function prioritize_none(v : std_ulogic_vector) return std_ulogic_vector is
    variable ret : std_ulogic_vector(v'range);
  begin
    ret := (others => '0');
    for i in v'low to v'high loop
      case v(i) is
        when '1' =>
          ret(i) := '1';
          exit;
        when '0' =>
          null;
        when others =>
          return (v'range => 'X');
      end case;
    end loop;
    return ret;
  end function;
  
  pure function is_1hot(v : std_ulogic_vector) return std_ulogic is
    variable ret : std_ulogic;
  begin
    ret := '1';
    if v'length > 1 then
      for n in v'low to v'high-1 loop
        for m in n+1 to v'high loop
          ret := ret and not (v(n) and v(m));
        end loop;
      end loop;
    end if;
    return ret;
  end;

  -- return a set of taps for an LFSR that generates the maximal length sequence on the given number of bits
  pure function lfsr_taps(n : natural) return std_ulogic_vector is
  begin
    case n is
      when 1  => return "1";
      when 2  => return "11";
      when 3  => return "110";
      when 4  => return "1100";
      when 5  => return "10100";
      when 6  => return "110000";
      when 7  => return "1100000";
      when 8  => return "11100001";
      when 9  => return "100010000";
      when 10 => return "1001000000";
      when 11 => return "10100000000";
      when 12 => return "111000001000";
      when 13 => return "1110010000000";
      when 14 => return "11100000000010";
      when 15 => return "110000000000000";
      when 16 => return "1101000000001000";
      when 17 => return "10010000000000000";
      when 18 => return "100000010000000000";
      when 19 => return "1110010000000000000";
      when 20 => return "10010000000000000000";
      when 21 => return "101000000000000000000";
      when 22 => return "1100000000000000000000";
      when 23 => return "10000100000000000000000";
      when 24 => return "111000010000000000000000";
      when 25 => return "1001000000000000000000000";
      when 26 => return "11100010000000000000000000";
      when 27 => return "111001000000000000000000000";
      when 28 => return "1001000000000000000000000000";
      when 29 => return "10100000000000000000000000000";
      when 30 => return "111000000000000000000001000000";
      when 31 => return "1001000000000000000000000000000";
      when 32 => return "11100000000000000000001000000000";
      when others => return (n-1 downto 0 => 'X');
    end case;
  end function;
  
end package body;
