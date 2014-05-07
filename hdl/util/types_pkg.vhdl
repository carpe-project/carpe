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

package types_pkg is

  type endianness_type is (
    little_endian,
    big_endian
    );

  subtype void_type is std_ulogic_vector(-1 downto 0);
  constant void : void_type := "";

  constant log2_byte_bits : natural := 3;
  constant byte_bits : natural := 2**log2_byte_bits;
  subtype byte_type is std_ulogic_vector(byte_bits-1 downto 0);

  type std_ulogic_vector2 is array(natural range <>, natural range <>) of std_ulogic;
  type std_logic_vector2 is array(natural range <>, natural range <>) of std_logic;
  type std_ulogic_vector3 is array(natural range <>, natural range <>, natural range <>) of std_ulogic;
  type std_logic_vector3 is array(natural range <>, natural range <>, natural range <>) of std_logic;

  pure function std_ulogic_vector2_slice1(v : std_ulogic_vector2; n : natural) return std_ulogic_vector;
  pure function std_ulogic_vector2_slice2(v : std_ulogic_vector2; n : natural) return std_ulogic_vector;

  pure function std_ulogic_to_character(value : in std_ulogic) return character;
  pure function std_logic_to_character(value : in std_logic) return character;
  pure function character_to_std_ulogic(value : in character) return std_ulogic;
  pure function character_to_std_logic(value : in character) return std_logic;

  pure function std_ulogic_vector_to_string(value : in std_ulogic_vector) return string;
  pure function std_logic_vector_to_string(value : in std_logic_vector) return string;
  pure function string_to_std_ulogic_vector(value : in string) return std_ulogic_vector;
  pure function string_to_std_logic_vector(value : in string) return std_ulogic_vector;

  pure function boolean_to_string(value : in boolean) return string;
  pure function string_to_boolean(value : in string) return boolean;

  pure function integer_to_string(value : in integer) return string;
  pure function string_to_integer(value : in string) return integer;
  
end package;

package body types_pkg is

  pure function std_ulogic_vector2_slice1(v : std_ulogic_vector2; n : natural) return std_ulogic_vector is
    variable ret : std_ulogic_vector(v'range(1));
  begin
    for m in v'range(1) loop
      ret(m) := v(m, n);
    end loop;
    return ret;
  end function;
  
  pure function std_ulogic_vector2_slice2(v : std_ulogic_vector2; n : natural) return std_ulogic_vector is
    variable ret : std_ulogic_vector(v'range(2));
  begin
    for m in v'range(2) loop
      ret(m) := v(n, m);
    end loop;
    return ret;
  end function;

  pure function std_ulogic_to_character(value : in std_ulogic) return character is
  begin
    case value is
      when 'U' =>
        return 'U';
      when 'X' =>
        return 'X';
      when '0' =>
        return '0';
      when '1' =>
        return '1';
      when 'Z' =>
        return 'Z';
      when 'W' =>
        return 'W';
      when 'L' =>
        return 'L';
      when 'H' =>
        return 'H';
      when '-' =>
        return '-';
    end case;
  end function;

  pure function std_logic_to_character(value : in std_logic) return character is
  begin
    case value is
      when 'U' =>
        return 'U';
      when 'X' =>
        return 'X';
      when '0' =>
        return '0';
      when '1' =>
        return '1';
      when 'Z' =>
        return 'Z';
      when 'W' =>
        return 'W';
      when 'L' =>
        return 'L';
      when 'H' =>
        return 'H';
      when '-' =>
        return '-';
    end case;
  end function;

  pure function character_to_std_ulogic(value : in character) return std_ulogic is
  begin
    case value is
      when 'U' =>
        return 'U';
      when 'X' =>
        return 'X';
      when '0' =>
        return '0';
      when '1' =>
        return '1';
      when 'Z' =>
        return 'Z';
      when 'W' =>
        return 'W';
      when 'L' =>
        return 'L';
      when 'H' =>
        return 'H';
      when '-' =>
        return '-';
      when others =>
        assert false
          report "invalid std_ulogic character: " & value
          severity failure;
    end case;
  end function;

  pure function character_to_std_logic(value : in character) return std_logic is
  begin
    case value is
      when 'U' =>
        return 'U';
      when 'X' =>
        return 'X';
      when '0' =>
        return '0';
      when '1' =>
        return '1';
      when 'Z' =>
        return 'Z';
      when 'W' =>
        return 'W';
      when 'L' =>
        return 'L';
      when 'H' =>
        return 'H';
      when '-' =>
        return '-';
      when others =>
        assert false
          report "invalid std_logic character: " & value
          severity failure;
    end case;
  end function;

  pure function std_ulogic_vector_to_string(value : in std_ulogic_vector) return string is
    variable ret : string(1 to value'length);
  begin
    if value'ascending then
      for n in value'range loop
        ret(n-value'left+ret'left) := std_ulogic_to_character(value(n));
      end loop;
    else
      for n in value'range loop
        ret(value'left-n+ret'left) := std_ulogic_to_character(value(n));
      end loop;
    end if;
    return ret;
  end function;
  
  pure function std_logic_vector_to_string(value : in std_logic_vector) return string is
    variable ret : string(1 to value'length);
  begin
    if value'ascending then
      for n in value'range loop
        ret(n-value'left+ret'left) := std_logic_to_character(value(n));
      end loop;
    else
      for n in value'range loop
        ret(value'left-n+ret'left) := std_logic_to_character(value(n));
      end loop;
    end if;
    return ret;
  end function;
  
  pure function string_to_std_ulogic_vector(value : in string) return std_ulogic_vector is
    variable ret : std_ulogic_vector(value'length-1 downto 0);
  begin
    if not value'ascending then
      for n in value'range loop
        ret(n-value'right+ret'right) := character_to_std_ulogic(value(n));
      end loop;
    else
      for n in value'range loop
        ret(value'right-n+ret'right) := character_to_std_ulogic(value(n));
      end loop;
    end if;
    return ret;
  end function;
  
  pure function string_to_std_logic_vector(value : in string) return std_ulogic_vector is
    variable ret : std_ulogic_vector(value'length-1 downto 0);
  begin
    if not value'ascending then
      for n in value'range loop
        ret(n-value'right+ret'right) := character_to_std_logic(value(n));
      end loop;
    else
      for n in value'range loop
        ret(value'right-n+ret'right) := character_to_std_logic(value(n));
      end loop;
    end if;
    return ret;
  end function;

  pure function boolean_to_string(value : in boolean) return string is
  begin
    if value then
      return "true";
    else
      return "false";
    end if;
  end function;
  
  pure function string_to_boolean(value : in string) return boolean is
  begin
    if value = "true" then
      return true;
    elsif value = "false" then
      return false;
    else
      assert false
        report "invalid boolean string: " & value
        severity failure;
    end if;
  end function;

  pure function integer_to_string(value : in integer) return string is
  begin
    return integer'image(value);
  end function;
  
  pure function string_to_integer(value : in string) return integer is
    variable ret : integer;
  begin
    ret := 0;
    for n in value'left to value'right loop
      ret := ret * 10;
      case value(n) is
        when '0' => ret := ret + 0;
        when '1' => ret := ret + 1;
        when '2' => ret := ret + 2;
        when '3' => ret := ret + 3;
        when '4' => ret := ret + 4;
        when '5' => ret := ret + 5;
        when '6' => ret := ret + 6;
        when '7' => ret := ret + 7;
        when '8' => ret := ret + 8;
        when '9' => ret := ret + 9;
        when others =>
          report "invalid integer string: " & value
          severity failure;
      end case;
    end loop;
    return ret;
  end function;
  
end package body;
