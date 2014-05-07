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

library util;
use util.names_pkg.all;

use work.options_pkg.all;

package monitor_pkg is

  signal monitor_enable : boolean;

  type monitor_event_code_type is (
    monitor_event_code_error,
    monitor_event_code_cycle,
    monitor_event_code_reset,
    monitor_event_code_exit,
    monitor_event_code_watch
    );

  subtype monitor_event_source_id_type is natural;

  impure function monitor_event_source(instance : string;
                                       code : monitor_event_code_type;
                                       name : string) return monitor_event_source_id_type;

  procedure monitor_event(source : monitor_event_source_id_type;
                          data : std_ulogic_vector);
  
  impure function monitor_has_event return boolean;
  impure function monitor_event_timestamp return time;
  impure function monitor_event_instance return string;
  impure function monitor_event_code return monitor_event_code_type;
  impure function monitor_event_name return string;
  impure function monitor_event_data return std_ulogic_vector;
  procedure monitor_event_finish;

  procedure monitor_finish;
  
end package;

package body monitor_pkg is

  type monitor_type is protected

    impure function event_source(instance : in string;
                                 code : in monitor_event_code_type;
                                 name : in string) return monitor_event_source_id_type;
    impure function event_source_instance(source : in monitor_event_source_id_type) return string;
    impure function event_source_code(source : in monitor_event_source_id_type) return monitor_event_code_type;
    impure function event_source_name(source : in monitor_event_source_id_type) return string;

    impure function has_event return boolean;
  
    procedure push_event(timestamp : in time;
                         source : in monitor_event_source_id_type;
                         data : in std_ulogic_vector);
    procedure pop_event;

    impure function head_timestamp return time;
    impure function head_source return monitor_event_source_id_type;
    impure function head_instance return string;
    impure function head_code return monitor_event_code_type;
    impure function head_name return string;
    impure function head_data return std_ulogic_vector;

    procedure finish;
    
  end protected;

  type monitor_event_queue_type is protected

    impure function empty return boolean;
    impure function head_timestamp return time;
    impure function head_source return monitor_event_source_id_type;
    impure function head_data return std_ulogic_vector;
    procedure push(timestamp : in time;
                   source : in monitor_event_source_id_type;
                   data : in std_ulogic_vector);
    procedure pop;
    procedure free;
    
  end protected;

  type monitor_event_queue_type is protected body

    constant initial_entry_queue_capacity : natural := 64;
    constant initial_data_queue_capacity : natural := 2048;

    type monitor_event_queue_entry_type is record
      timestamp : time;
      source : monitor_event_source_id_type;
      data_length : natural;
    end record;
    type monitor_event_queue_entry_array_type is array (natural range <>) of monitor_event_queue_entry_type;
    type monitor_event_queue_entry_array_ptr_type is access monitor_event_queue_entry_array_type;
    
    type std_ulogic_vector_ptr_type is access std_ulogic_vector;

    variable entry_queue_size : natural := 0;
    variable entry_queue : monitor_event_queue_entry_array_ptr_type := null;
    variable entry_queue_head_index : natural := 0;
    variable entry_queue_tail_index : natural := 0;
    variable data_queue_size : natural := 0;
    variable data_queue : std_ulogic_vector_ptr_type := null;
    variable data_queue_head_index : natural := 0;
    variable data_queue_tail_index : natural := 0;

    procedure check is
    begin
      if data_queue_size /= 0 or entry_queue_size /= 0 then
        assert (data_queue /= null and data_queue.all'length >= data_queue_size and
                0 <= data_queue_head_index and data_queue_head_index < data_queue.all'length and
                0 <= data_queue_tail_index and data_queue_tail_index < data_queue.all'length and
                ((data_queue_size = 0) or
                 (data_queue_head_index = data_queue_tail_index and data_queue_size = data_queue.all'length) or
                 (data_queue_head_index < data_queue_tail_index and data_queue_size = data_queue_tail_index - data_queue_head_index) or
                 (data_queue_tail_index < data_queue_head_index and data_queue_size = data_queue.all'length - data_queue_head_index + data_queue_tail_index)
                 )
                )
          report "inconsistent queue data"
          severity failure;
        assert (entry_queue /= null and entry_queue.all'length >= entry_queue_size and
                0 <= entry_queue_head_index and entry_queue_head_index < entry_queue.all'length and
                0 <= entry_queue_tail_index and entry_queue_tail_index < entry_queue.all'length and
                ((entry_queue_head_index = entry_queue_tail_index and entry_queue_size = entry_queue.all'length) or
                 (entry_queue_head_index < entry_queue_tail_index and entry_queue_size = entry_queue_tail_index - entry_queue_head_index) or
                 (entry_queue_tail_index < entry_queue_head_index and entry_queue_size = entry_queue.all'length - entry_queue_head_index + entry_queue_tail_index)
                 )
                )
        report "inconsistent queue entry_queue"
        severity failure;
      end if;
    end;      

    impure function empty return boolean is
    begin
      return entry_queue_size = 0;
    end function;

    procedure grow(new_data_length : natural) is
      
      constant new_entry_queue_size : natural := entry_queue_size + 1;
      variable entry_queue_capacity : natural;
      variable new_entry_queue_capacity : natural;
      variable new_entry_queue : monitor_event_queue_entry_array_ptr_type := null;
      
      constant new_data_queue_size : natural := data_queue_size + new_data_length;
      variable data_queue_capacity : natural;
      variable new_data_queue_capacity : natural;
      variable new_data_queue : std_ulogic_vector_ptr_type := null;
      
    begin

      if entry_queue = null then
        
        --report "allocating vector queue";
        
        assert entry_queue_size = 0
          report "inconsistent queue"
          severity failure;
        
        new_entry_queue_capacity := initial_entry_queue_capacity;
        --report "new entry_queue capacity: " & integer'image(new_entry_queue_capacity);
        entry_queue := new monitor_event_queue_entry_array_type(0 to new_entry_queue_capacity-1);
        entry_queue.all := (
          others => (
            timestamp => time'high,
            source => monitor_event_source_id_type'high,
            data_length => natural'high
            )
          );
        entry_queue_head_index := 0;
        entry_queue_tail_index := 0;
        
        assert data_queue = null and data_queue_size = 0
          report "inconsistent queue"
          severity failure;
        
        new_data_queue_capacity := initial_data_queue_capacity;
        while new_data_queue_capacity < new_data_length loop
          new_data_queue_capacity := new_data_queue_capacity * 2;
        end loop;
        --report "new data_queue capacity: " & integer'image(new_data_queue_capacity);
        data_queue := new std_ulogic_vector(new_data_queue_capacity-1 downto 0);
        data_queue_head_index := 0;
        data_queue_tail_index := 0;
        
        return;

      end if;

      entry_queue_capacity := entry_queue.all'length;
      if entry_queue_capacity < new_entry_queue_size then

        --report "growing vector entry_queue";
        
        new_entry_queue_capacity := entry_queue_capacity;
        while new_entry_queue_capacity < new_entry_queue_size loop
          new_entry_queue_capacity := 2 * new_entry_queue_capacity;
        end loop;
        
        new_entry_queue := new monitor_event_queue_entry_array_type'(
          0 to new_entry_queue_capacity-1 => (
            timestamp => time'high,
            source => monitor_event_source_id_type'high,
            data_length => natural'high
            )
          );
        if entry_queue_size > 0 then
          if entry_queue_head_index < entry_queue_tail_index then
            new_entry_queue(0 to entry_queue_size-1) := entry_queue(entry_queue_head_index to entry_queue_tail_index-1);
          else
            new_entry_queue(0 to entry_queue_capacity-entry_queue_head_index-1) := entry_queue(entry_queue_head_index to entry_queue_capacity-1);
            new_entry_queue(entry_queue_capacity-entry_queue_head_index to entry_queue_size-1) := entry_queue(0 to entry_queue_tail_index-1);
          end if;
        end if;
        deallocate(entry_queue);
        entry_queue := new_entry_queue;
        entry_queue_head_index := 0;
        if entry_queue_size > 0 then
          entry_queue_tail_index := entry_queue_size;
        else
          entry_queue_tail_index := 0;
        end if;

      end if;
      
      data_queue_capacity := data_queue.all'length;
      if data_queue_capacity < new_data_queue_size then

        --report "growing data_queue";
        
        new_data_queue_capacity := data_queue_capacity;
        while new_data_queue_capacity < new_data_queue_size loop
          new_data_queue_capacity := 2 * new_data_queue_capacity;
        end loop;
        
        new_data_queue := new std_ulogic_vector'(new_data_queue_capacity-1 downto 0 => 'U');
        if data_queue_size > 0 then
          if data_queue_head_index < data_queue_tail_index then
            new_data_queue.all(data_queue_size-1 downto 0) := data_queue.all(data_queue_tail_index-1 downto data_queue_head_index);
          else
            new_data_queue.all(data_queue_capacity-data_queue_head_index-1 downto 0) := data_queue.all(data_queue_capacity-1 downto data_queue_head_index);
            new_data_queue.all(data_queue_capacity-data_queue_head_index+data_queue_tail_index-1 downto data_queue_capacity-data_queue_head_index) := data_queue.all(data_queue_tail_index-1 downto 0);
          end if;
        end if;
        deallocate(data_queue);
        data_queue := new_data_queue;
        data_queue_head_index := 0;
        data_queue_tail_index := data_queue_size;

      end if;

      check;

    end;
  
    impure function head_timestamp return time is
    begin
      assert entry_queue_size > 0
        report "tried to get head of empty queue"
        severity failure;
      return entry_queue(entry_queue_head_index).timestamp;
    end function;
  
    impure function head_source return monitor_event_source_id_type is
    begin
      assert entry_queue_size > 0
        report "tried to get head of empty queue"
        severity failure;
      return entry_queue(entry_queue_head_index).source;
    end function;
  
    impure function head_data return std_ulogic_vector is
      variable data_length : natural;
    begin
      assert entry_queue_size > 0
        report "tried to get head of empty queue"
        severity failure;
      data_length := entry_queue(entry_queue_head_index).data_length;
      if data_length = 0 then
        return "";
      end if;
      assert data_queue /= null
        report "inconsistent queue"
        severity failure;
      assert data_queue.all'length > 0
        report "inconsistent queue"
        severity failure;
      assert data_queue_size > 0
        report "inconsistent queue"
        severity failure;
      if data_queue_head_index < data_queue_tail_index then
        return data_queue.all(data_queue_head_index+data_length-1 downto data_queue_head_index);
      else
        return data_queue.all(data_length-(data_queue'length-data_queue_head_index)-1 downto 0) & data_queue.all(data_queue.all'length-1 downto data_queue_head_index);
      end if;
    end function;
  
    procedure push(timestamp : in time;
                   source : in monitor_event_source_id_type;
                   data : in std_ulogic_vector) is
    begin
      --report string'("push event time ") & time'image(timestamp) & " source " & monitor_event_source_id_type'image(source);
      
      check;
      grow(data'length);

      assert data_queue.all'length >= data'length
        report "inconsistent queue"
        severity failure;

      entry_queue(entry_queue_tail_index) := (
        timestamp => timestamp,
        source => source,
        data_length => data'length
        );
      if entry_queue_tail_index = entry_queue'right then
        entry_queue_tail_index := 0;
      else
        entry_queue_tail_index := entry_queue_tail_index + 1;
      end if;
      entry_queue_size := entry_queue_size + 1;

      if data'length = 0 then
        return;
      end if;

      for n in 0 to data'length-1 loop
        data_queue.all(data_queue_tail_index) := data(n);
        if data_queue_tail_index /= data_queue.all'length-1 then
          data_queue_tail_index := data_queue_tail_index + 1;
        else
          data_queue_tail_index := 0;
        end if;
      end loop;

      data_queue_size := data_queue_size + data'length;

      check;
    end procedure;
  
    procedure pop is
      variable data_length : natural;
    begin
      check;
      assert entry_queue_size > 0
        report "pop on empty queue"
        severity failure;

      --report string'("pop event time ") & time'image(head_timestamp) & " source " & monitor_event_source_id_type'image(head_source);
      
      data_length := entry_queue(entry_queue_head_index).data_length;

      assert (data_length <= data_queue_size and
              data_length <= data_queue.all'length)
        report "pop length mismatch"
        severity failure;

      if data_length > 0 then
        if data_queue_size > data_length then
          data_queue_size := data_queue_size-data_length;
          if data_queue_tail_index <= data_queue_head_index and data_queue'length - data_length < data_queue_head_index then
            data_queue_head_index := data_length - (data_queue'length - data_queue_head_index);
          else
            data_queue_head_index := data_queue_head_index + data_length;
          end if;
        else
          assert data_queue_size = data_length
            report "pop length mismatch";
          data_queue_size := 0;
          data_queue_head_index := 0;
          data_queue_tail_index := 0;
        end if;
      end if;
      
      if entry_queue_size > 1 then
        entry_queue_size := entry_queue_size - 1;
        if entry_queue_head_index = entry_queue'right then
          entry_queue_head_index := 0;
        else
          entry_queue_head_index := entry_queue_head_index + 1;
        end if;
      else
        entry_queue_size := 0;
        entry_queue_head_index := 0;
        entry_queue_tail_index := 0;
      end if;
      check;
    end procedure;
  
    procedure free is
    begin
      check;
      deallocate(data_queue);
      data_queue := null;
      data_queue_head_index := 0;
      data_queue_tail_index := 0;
      data_queue_size := 0;
      entry_queue := null;
      deallocate(entry_queue);
      entry_queue := null;
      entry_queue_head_index := 0;
      entry_queue_tail_index := 0;
      entry_queue_size := 0;
    end procedure;
  
  end protected body;

  constant initial_source_array_capacity : natural := 64;
  
  type monitor_type is protected body

    type monitor_event_source_type is record
      instance : line;
      code : monitor_event_code_type;
      name : line;
    end record;
    type monitor_event_source_array_type is array(natural range <>) of monitor_event_source_type;
    type monitor_event_source_array_ptr_type is access monitor_event_source_array_type;
  
    variable initialized : boolean := false;
    variable source_array : monitor_event_source_array_ptr_type := null;
    variable source_array_tail : natural := 0;

    variable event_queue : monitor_event_queue_type;
    
    impure function event_source(instance : string;
                                 code : monitor_event_code_type;
                                 name : string) return monitor_event_source_id_type is
      variable ret : natural;
    begin
      
      if source_array = null then
        assert source_array_tail = 0
          report "inconsistent source array"
          severity failure;
        source_array := new monitor_event_source_array_type'(
          0 to initial_source_array_capacity-1 => (
            instance => null,
            code => monitor_event_code_error,
            name => null)
          );
      else
        for n in 0 to source_array_tail-1 loop
          if source_array.all(n).instance.all = instance and
             source_array.all(n).code = code and
             source_array.all(n).name.all = name then
            return n;
          end if;
        end loop;
      end if;

      --report string'("new event source: instance ") & instance & string'(", code ") & monitor_event_code_type'image(code) & string'(", name ") & name;

      source_array.all(source_array_tail) := (
        instance => new string'(instance),
        code => code,
        name => new string'(name)
        );

      ret := source_array_tail;
      source_array_tail := source_array_tail + 1;

      return ret;
      
    end;

    impure function event_source_instance(source : in monitor_event_source_id_type) return string is
    begin
      assert source < source_array_tail
        report "invalid source: " & monitor_event_source_id_type'image(source)
        severity failure;
      return source_array.all(source).instance.all;
    end;
  
    impure function event_source_code(source : in monitor_event_source_id_type) return monitor_event_code_type is
    begin
      assert source < source_array_tail
        report "invalid source: " & monitor_event_source_id_type'image(source)
        severity failure;
      return source_array.all(source).code;
    end;
  
    impure function event_source_name(source : in monitor_event_source_id_type) return string is
    begin
      assert source < source_array_tail
        report "invalid source: " & monitor_event_source_id_type'image(source)
        severity failure;
      return source_array.all(source).name.all;
    end;
  
    impure function has_event return boolean is
    begin
      return not event_queue.empty;
    end;

    procedure push_event(timestamp : in time;
                         source : in monitor_event_source_id_type;
                         data : in std_ulogic_vector) is
    begin
      event_queue.push(timestamp, source, data);
    end;
  
    procedure pop_event is
    begin
      event_queue.pop;
    end;
  
    impure function head_timestamp return time is
    begin
      return event_queue.head_timestamp;
    end function;

    impure function head_source return monitor_event_source_id_type is
    begin
      return event_queue.head_source;
    end function;
  
    impure function head_instance return string is
    begin
      return source_array(head_source).instance.all;
    end function;
  
    impure function head_code return monitor_event_code_type is
    begin
      return source_array(head_source).code;
    end function;
  
    impure function head_name return string is
    begin
      return source_array(head_source).name.all;
    end function;
  
    impure function head_data return std_ulogic_vector is
    begin
      return event_queue.head_data;
    end function;

    procedure finish is
    begin
      event_queue.free;
    end;
    
  end protected body;

  shared variable the_monitor : monitor_type;

  impure function monitor_event_source(instance : string;
                                       code : monitor_event_code_type;
                                       name : string) return monitor_event_source_id_type is
  begin
    return the_monitor.event_source(instance, code, name);
  end;

  procedure monitor_event(source : monitor_event_source_id_type;
                          data : std_ulogic_vector) is
  begin
    the_monitor.push_event(now, source, data);
  end;
  
  impure function monitor_has_event return boolean is
  begin
    return the_monitor.has_event;
  end;
  
  impure function monitor_event_timestamp return time is
  begin
    return the_monitor.head_timestamp;
  end;
  
  impure function monitor_event_instance return string is
  begin
    return the_monitor.head_instance;
  end;

  impure function monitor_event_code return monitor_event_code_type is
  begin
    return the_monitor.head_code;
  end;

  impure function monitor_event_name return string is
  begin
    return the_monitor.head_name;
  end;

  impure function monitor_event_data return std_ulogic_vector is
  begin
    return the_monitor.head_data;
  end;

  procedure monitor_event_finish is
  begin
    the_monitor.pop_event;
  end;

  procedure monitor_finish is
  begin
    the_monitor.finish;
  end;
  
end package body;
