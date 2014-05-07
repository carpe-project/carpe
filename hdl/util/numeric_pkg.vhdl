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

package numeric_pkg is

  pure function log2(n : natural) return natural;
  pure function log2ceil(n : natural) return natural;
  pure function is_pow2(n : natural) return boolean;
  pure function integer_minimum(x1, x2 : integer) return integer;
  pure function integer_maximum(x1, x2 : integer) return integer;
  pure function factorial(n : natural) return natural;
  pure function bitsize(n : natural) return natural;

end package;

package body numeric_pkg is

  pure function log2(n : natural) return natural is
    variable m, r : natural;
  begin
    m := n;
    r := 0;
    while m > 1 loop
      r := r + 1;
      m := m / 2;
    end loop;
    return r;
  end function;

  pure function log2ceil(n : natural) return natural is
    variable m, r : natural;
  begin
    m := 1;
    r := 0;
    while m < n loop
      r := r + 1;
      m := m * 2;
    end loop;
    return r;
  end function;

  pure function is_pow2(n : natural) return boolean is
    variable m : natural;
  begin
    if (n < 1) then
      return false;
    else
      m := 1;
      while (m < n) loop
        m := m * 2;
      end loop;
      return m = n;
    end if;
  end function;

  pure function integer_minimum(x1, x2 : integer) return integer is
  begin
    if x1 < x2 then
      return x1;
    else
      return x2;
    end if;
  end function;

  pure function integer_maximum(x1, x2 : integer) return integer is
  begin
    if x1 > x2 then
      return x1;
    else
      return x2;
    end if;
  end function;

  pure function factorial(n : natural) return natural is
    variable ret : natural;
    variable m : natural;
  begin
    m := n;
    ret := 1;
    while m > 0 loop
      ret := ret * n;
      m := m - 1;
    end loop;
    return ret;
  end function;

  pure function bitsize(n : natural) return natural is
  begin
    if n = 0 then
      return 0;
    else
      return log2(n) + 1;
    end if;
  end function;

end package body;
