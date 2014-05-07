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
use util.numeric_pkg.all;
use util.types_pkg.all;

package uart_pkg is

  constant uart_rsel_bits : integer := 4;
  subtype uart_rsel_type is std_ulogic_vector(uart_rsel_bits-1 downto 0);
  constant uart_rsel_rx  : uart_rsel_type := "0000"; -- 0x0: In:  Receive buffer (DLAB=0)
  constant uart_rsel_tx  : uart_rsel_type := "0000"; -- 0x0: Out: Transmit buffer (DLAB=0)
  constant uart_rsel_dll : uart_rsel_type := "0000"; -- 0x0: Out: Divisor Latch Low (DLAB=1)
  constant uart_rsel_dlm : uart_rsel_type := "0001"; -- 0x1: Out: Divisor Latch High (DLAB=1)
  constant uart_rsel_ier : uart_rsel_type := "0001"; -- 0x1: Out: Interrupt Enable Register
  constant uart_rsel_iir : uart_rsel_type := "0010"; -- 0x2: In:  Interrupt ID Register
  constant uart_rsel_fcr : uart_rsel_type := "0010"; -- 0x2: Out: FIFO Control Register
  constant uart_rsel_efr : uart_rsel_type := "0010"; -- 0x2: I/O: Extended Features Register
  constant uart_rsel_lcr : uart_rsel_type := "0011"; -- 0x3: Out: Line Control Register
  constant uart_rsel_mcr : uart_rsel_type := "0100"; -- 0x4: Out: Modem Control Register
  constant uart_rsel_lsr : uart_rsel_type := "0101"; -- 0x5: In:  Line Status Register
  constant uart_rsel_msr : uart_rsel_type := "0110"; -- 0x6: In:  Modem Status Register
  constant uart_rsel_scr : uart_rsel_type := "0111"; -- 0x7: I/O: Scratch Register

  -- Line Status Register
  constant uart_lsr_temt : byte_type := "01000000"; -- 0x40: transmitter empty
  constant uart_lsr_thre : byte_type := "00100000"; -- 0x20: transmit-hold-register empty
  constant uart_lsr_bi   : byte_type := "00010000"; -- 0x10: break interrupt indicator
  constant uart_lsr_fe   : byte_type := "00001000"; -- 0x08: frame error indicator
  constant uart_lsr_pe   : byte_type := "00000100"; -- 0x04: parity error indicator
  constant uart_lsr_oe   : byte_type := "00000010"; -- 0x02: overrun error indicator
  constant uart_lsr_dr   : byte_type := "00000001"; -- 0x01: receiver data ready

  -- Line Control Register
  constant uart_lcr_dlab   : byte_type := "10000000"; -- 0x80: divisor latch access bit */
  constant uart_lcr_sbc    : byte_type := "01000000"; -- 0x40: set break control */
  constant uart_lcr_spar   : byte_type := "00100000"; -- 0x20: stick parity (?) */
  constant uart_lcr_epar   : byte_type := "00010000"; -- 0x10: even parity select */
  constant uart_lcr_parity : byte_type := "00001000"; -- 0x08: parity enable */
  constant uart_lcr_stop   : byte_type := "00000100"; -- 0x04: stop bits: 0=1 stop bit, 1= 2 stop bits */
  constant uart_lcr_wlen5  : byte_type := "00000000"; -- 0x00: wordlength: 5 bits */
  constant uart_lcr_wlen6  : byte_type := "00000001"; -- 0x01: wordlength: 6 bits */
  constant uart_lcr_wlen7  : byte_type := "00000010"; -- 0x02: wordlength: 7 bits */
  constant uart_lcr_wlen8  : byte_type := "00000011"; -- 0x03: wordlength: 8 bits */
  
end package;
