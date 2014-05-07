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

-- DEBUG
--use std.textio.all;
--library util;
--use util.io_pkg.all;
-- END DEBUG

library util;
use util.numeric_pkg.all;
use util.types_pkg.all;

use work.uart_pkg.all;

architecture behav of uart is

  type uartfile is file of character;
  file ifile : uartfile;
  file ofile : uartfile;

  type register_type is record
    dataout : std_ulogic_vector2(data_bytes-1 downto 0, byte_bits-1 downto 0);
  end record;

  signal r : register_type;
  
begin
  
  dataout <= r.dataout;
  
  seq : process (clk) is

    variable v_byte_address : std_ulogic_vector(uart_rsel_bits-1 downto 0);
    variable v_status : file_open_status;

    variable v_r_next : register_type;
    variable v_char : character;

    -- DEBUG
    --variable tmpline : line;
    -- END DEBUG
    
  begin

    if rising_edge(clk) then

      if rstn = '0' then

        file_close (ifile);
        file_close (ofile);

        file_open (v_status, ifile, ifilename, read_mode);
        if (v_status /= open_ok) then
          report "could not open UART input file " & ifilename severity error;
        end if;
        file_open (v_status, ofile, ofilename, write_mode);
        if (v_status /= open_ok) then
          report "could not open UART output file " & ofilename severity error;
        end if;

        r <= (
          dataout => (others => (others => 'X'))
          );
        
      else

        v_r_next := r;
    
        if enable = '1' then

          if wenable = '1' then
            
            v_r_next.dataout := (others => (others => 'X'));
            
            for n in 0 to data_bytes-1 loop

              v_byte_address := address & std_ulogic_vector(to_unsigned(n, log2(data_bytes)));

              if wmask(n) = '1' then

                case v_byte_address is
                  when uart_rsel_tx => -- uart_rsel_dll
                    v_char := character'val(to_integer(unsigned(std_ulogic_vector2_row(datain, n))));
                    write(ofile, v_char);
                  when uart_rsel_dlm => -- uart_rsel_ier
                  when uart_rsel_fcr => -- uart_rsel_efr
                  when uart_rsel_lcr =>
                  when uart_rsel_mcr =>
                  when uart_rsel_scr =>
                  when others =>
                end case;
                
              end if;
              
            end loop;

          else

            -- DEBUG
            --write(tmpline, string'("reading address "));
            --write(tmpline, address);
            --write(tmpline, string'(" wmask "));
            --write(tmpline, wmask);
            --report tmpline.all;
            --deallocate(tmpline);
            -- END DEBUG

            for n in 0 to data_bytes-1 loop
              
              v_byte_address := address & std_ulogic_vector(to_unsigned(n, log2(data_bytes)));

              -- DEBUG
              --write(tmpline, string'("checking byte address  "));
              --write(tmpline, v_byte_address);
              --report tmpline.all;
              --deallocate(tmpline);
              -- END DEBUG
              
              if wmask(n) = '1' then
                
                set_std_ulogic_vector2_row(v_r_next.dataout, n, (byte_bits-1 downto 0 => 'X'));
                case v_byte_address is
                  when uart_rsel_rx =>
                  when uart_rsel_iir => -- uart_rsel_efr
                  when uart_rsel_lsr =>
                    set_std_ulogic_vector2_row(v_r_next.dataout, n, uart_lsr_temt or uart_lsr_thre);
                    -- DEBUG
                    --write(tmpline, string'("outputting  "));
                    --write(tmpline, std_ulogic_vector2_row(v_r_next.dataout, n));
                    --report tmpline.all;
                    --deallocate(tmpline);
                    -- END DEBUG
                  when uart_rsel_msr =>
                  when uart_rsel_scr =>
                  when others =>
                end case;

              else

                set_std_ulogic_vector2_row(v_r_next.dataout, n, (byte_bits-1 downto 0 => 'X'));
                
              end if;
              
            end loop;
            
          end if;

        end if;
        
        r <= v_r_next;
        
      end if;

    end if;
    
  end process;
  
end;
