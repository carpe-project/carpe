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


architecture rtl of syncram_banked_1rw_inferred is

  constant banks : natural := 2**log2_banks;
  type bank_data_type is array(banks-1 downto 0) of std_ulogic_vector(word_bits-1 downto 0);

  type comb_type is record
    bank_en : std_ulogic_vector(banks-1 downto 0);
    bank_rdata, bank_wdata : bank_data_type;
  end record;
  signal c : comb_type;
  
begin

  bank_loop : for n in 0 to banks-1 generate

    c.bank_en(n) <= en and banken(n);

    word_bit_loop : for m in word_bits-1 downto 0 generate
      c.bank_wdata(n)(m) <= wdata(n, m);
      rdata(n, m) <= c.bank_rdata(n)(m);
    end generate;
    
    syncram : entity work.syncram_1rw(rtl)
      generic map (
        addr_bits => addr_bits,
        data_bits => word_bits
        )
      port map (
        clk => clk,
        en  => c.bank_en(n),
        we  => we,
        addr => addr,
        wdata => c.bank_wdata(n),
        rdata => c.bank_rdata(n)
        );
    
  end generate;

end;
