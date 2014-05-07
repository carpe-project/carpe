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

package options_pkg is

  procedure options_add(key : in string; value : in string);
  procedure options_read(filename : in string);

  signal options_ready : boolean := false;
  impure function option(key : in string) return string;
  
end package;

package body options_pkg is

  type option_type;
  type option_ptr_type is access option_type;

  type option_type is record
    key : line;
    value : line;
    next_option : option_ptr_type;
  end record;

  type options_type is protected
    procedure add(key : in string; value : in string);
    procedure read(filename : in string);
    impure function get(key : in string) return string;
  end protected;

  type options_type is protected body
    variable options : option_ptr_type := null;

    procedure add(key : in string; value : in string) is
    begin
      
      assert not options_ready
        report "options_add called when options are ready"
        severity failure;

      --report "option: " & key & "=" & value;
      
      options := new option_type'(
        key => new string'(key),
        value => new string'(value),
        next_option => options
        );
    end;
    
    procedure read(filename : in string) is
      variable l : line;
      variable eqpos : natural;
      file options_file : text;
    begin

      assert not options_ready
        report "options_read called when options are ready"
        severity failure;

      --report "reading options file " & filename;

      file_open(options_file, filename, read_mode);
      
      while not endfile(options_file) loop

        readline(options_file, l);
        if l.all = "=" then
          deallocate(l);
          exit;
        end if;

        eqpos := 0;
        for n in l.all'left to l.all'right loop
          if l.all(n) = '=' then
            eqpos := n;
            exit;
          end if;
        end loop;

        assert (eqpos > l.all'left and eqpos < l.all'right)
          report "invalid option: " & l.all
          severity failure;

        add(l.all(l.all'left to eqpos-1), l.all(eqpos+1 to l.all'right));

        deallocate(l);
        l := null;

      end loop;

      file_close(options_file);

    end procedure;

    impure function get(key : in string) return string is
      variable option : option_ptr_type;
    begin

      assert options_ready
        report "option " & key & " requested before options are ready"
        severity failure;

      option := options;
      
      while option /= null loop
        
        if option.all.key.all = key then
          return option.all.value.all;
        end if;
        
        option := option.all.next_option;
        
      end loop;
      
      return "";
      
    end;
  
  end protected body;

  shared variable the_options : options_type;

  procedure options_add(key : in string; value : in string) is
  begin
    the_options.add(key, value);
  end procedure;
  
  procedure options_read(filename : in string) is
  begin
    the_options.read(filename);
  end procedure;
  
  impure function option(key : in string) return string is
  begin
    return the_options.get(key);
  end function;
  
end package body;
