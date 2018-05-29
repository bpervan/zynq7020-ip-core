-------------------------------------------------------------------------------
--  addr_gen - entity/architecture pair
-------------------------------------------------------------------------------
--
-- ************************************************************************
-- ** DISCLAIMER OF LIABILITY                                            **
-- **                                                                    **
-- ** This file contains proprietary and confidential information of     **
-- ** Xilinx, Inc. ("Xilinx"), that is distributed under a license       **
-- ** from Xilinx, and may be used, copied and/or disclosed only         **
-- ** pursuant to the terms of a valid license agreement with Xilinx.    **
-- **                                                                    **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION              **
-- ** ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         **
-- ** EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT                **
-- ** LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,          **
-- ** MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx      **
-- ** does not warrant that functions included in the Materials will     **
-- ** meet the requirements of Licensee, or that the operation of the    **
-- ** Materials will be uninterrupted or error-free, or that defects     **
-- ** in the Materials will be corrected. Furthermore, Xilinx does       **
-- ** not warrant or make any representations regarding use, or the      **
-- ** results of the use, of the Materials in terms of correctness,      **
-- ** accuracy, reliability or otherwise.                                **
-- **                                                                    **
-- ** Xilinx products are not designed or intended to be fail-safe,      **
-- ** or for use in any application requiring fail-safe performance,     **
-- ** such as life-support or safety devices or systems, Class III       **
-- ** medical devices, nuclear facilities, applications related to       **
-- ** the deployment of airbags, or any other applications that could    **
-- ** lead to death, personal injury or severe property or               **
-- ** environmental damage (individually and collectively, "critical     **
-- ** applications"). Customer assumes the sole risk and liability       **
-- ** of any use of Xilinx products in critical applications,            **
-- ** subject only to applicable laws and regulations governing          **
-- ** limitations on product liability.                                  **
-- **                                                                    **
-- ** Copyright 2010 Xilinx, Inc.                                        **
-- ** All rights reserved.                                               **
-- **                                                                    **
-- ** This disclaimer and copyright notice must be retained as part      **
-- ** of this file at all times.                                         **
-- ************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        addr_gen.vhd
-- Version:         v1.00.a
-- Description:     This file includes the logic for address generataion on
--                  IP interface based upon the AXI transactions.
-------------------------------------------------------------------------------
-- Structure:
--           -- axi_slave_burst.vhd  (wrapper for top level)
--               -- control_state_machine.vhd
--               -- read_data_path.vhd
--               -- address_decode.vhd
--               -- addr_gen.vhd
-------------------------------------------------------------------------------
-- Author:      SK
--
-- History:
--  SK 07/23/09      -- First version
-- ~~~~~~
--  -- Created the first version v1.00.a
-- ~~~~~~
-- SK    10/06/09
-- ^^^^^^
-- added input port "axi_cycle_cmb"
-- added "axi_cycle_cmb" signal in sensitivity list of INT_COUNTER_P
-- ~~~~~~
-- NSK    10/08/09
-- ^^^^^^
-- Replaced "INT_COUNTER_P" logic in C_S_AXI_DATA_WIDTH=32 with INT_COUNTER_P32
-- and C_S_AXI_DATA_WIDTH=64 with INT_COUNTER_P64.
-- ~~~~~~
-- SK    10/09/09
-- ^^^^^^
-- Updated "RNW_reg" by "RNW_cmb"
-- ~~~~~~
-- NSK  10/10/09
-- ^^^^^^
-- 1. Updated "INT_COUNTER_P32" logic
-- 2. Updated "wr_stb_align_addr(0)", "wr_stb_align_addr(1)" and
--    "wr_stb_align_addr(2)" logic. This logic generation is shifted to
--    "WR_STRB_GEN_DATA_WDTH_32" and "WR_STRB_GEN_DATA_WDTH_64", in place of
--    common place location.
-- ~~~~~~
-- SK  10/10/09
-- ^^^^^^
-- 1. Added "addr_change" signal which is OR of "Ip2Bus_RdAck", "Ip2Bus_WrAck",
--    "Addr_Timeout" and "Data_Timeout".
--    Reason - The address should be changed only in above conditions and NOT on
--             "Ip2Bus_Addr_ack" as this will cause problem in real time
--             application.
-- ~~~~~~
-- SK    10/10/09
-- ^^^^^^
-- 1. Updated address generation logic for 64-bit.
-- 2. Updated the wr_stb_align_addr(0) logic in WR_STRB_GEN_DATA_WDTH_32,
--    in place of (S_AXI_WSTRB(1) or (S_AXI_WSTRB(3))),
--    replaced    (S_AXI_WSTRB(1) or (not((S_AXI_WSTRB(2) and (S_AXI_WSTRB(3))))));
-- ~~~~~~
-- SK    10/29/09
-- ^^^^^^
-- 1. Code clean for internal review
-- 2. Added "IP2Bus_RdAck", "Data_Timeout", "Rdce_ored","Addr_reload_int" in
--    port list.
-- 3. Added logic for "Bus2IP_Addr_bkp", "rdce_falling_edge", "addr_reload"
--    for address back to avoide mis-match between the no. of address ACK
--    and Data ACK. The address will be reloded if the no. of data ack
--    dont match the no. of address ack's.
-- 4. "INT_COUNTER_P32_BKP_P" is added in "BUS2IP_ADDR_GEN_DATA_WDTH_32" and
--    added "addr_reload" condition in "INT_COUNTER_P32" to reload the lower
--    address bits.
-- 5. Added "addr_reload" condition in each Bus2IP_Addr bits in
--    "BUS2IP_ADDR_GEN_DATA_WDTH_32" and ""BUS2IP_ADDR_GEN_DATA_WDTH_64".
-- 6. Added "INT_COUNTER_P64_BKP_P" in "BUS2IP_ADDR_GEN_DATA_WDTH_64" and
--    added "addr_reload" condition in "INT_COUNTER_P32" to reload the lower
--    address bits.
-- ~~~~~~
--    SK   11/10/09
-- ^^^^^^
-- 1. Updated logic for (not(S_AXI_WSTRB(2)) and (S_AXI_WSTRB(3))) in
--    "WR_STRB_GEN_DATA_WDTH_32" generate statement. Bracket was making the
--    the complete NOT of (S_AXI_WSTRB(2)) and (S_AXI_WSTRB(3))
-- ~~~~~~
--    SK   11/11/09
-- ^^^^^^
-- 1. Updated "WR_STRB_GEN_DATA_WDTH_64" for lower bit address generation.
-- ~~~~~~
--    SK   11/13/09
-- ^^^^^^
-- 1. Added "Take_addr_back_up" in port list as well as in "addr_reload" condition
--    to generate address reload signal at proper time.
-- ~~~~~~
--    SK   11/16/09
-- ^^^^^^
-- 1. Updated logic for generating the addresses on word/double word boundary
--    "ADDR_BITS_LOWER_BITS_REG_P" logic is updated to assign lower bits to '0'
-- 2. Code coverage - Removed "and (Rdce_ored='0'))then" condition from
--    a.INT_COUNTER_P32, ADDR_BITS_2_REG_P, ADDR_BITS_3_REG_P,ADDR_BITS_4_REG_P
--      ADDR_BITS_5_REG_P, ADDR_BITS_11_6_REG_P. This condition was combined
--      with (addr_reload='1')-- 32 bit address logic
--    b.INT_COUNTER_P64, ADDR_BITS_3_REG_P, ADDR_BITS_4_REG_P,ADDR_BITS_5_REG_P
--      ADDR_BITS_6_REG_P, ADDR_BITS_11_7_REG_P. This condition was combined
--      with (addr_reload='1')-- 64 bit address logic
-- ~~~~~~
--    SK   11/22/09
-- ^^^^^^
-- 1. Added "or RNW_reg" in "address_Carry" logic for
--   "BUS2IP_ADDR_GEN_DATA_WDTH_32" and "BUS2IP_ADDR_GEN_DATA_WDTH_64" generate
--   statements. This is to avoide the repetative read on the same addresses.
-- ~~~~~~
--    SK   11/23/09
-- ^^^^^^
-- 1. Reverted back the changes made on 22 nov for address_Carry logic.
-- 2. Updated address carry logic in 64 bit address geenration logic.
--    Changed - (Derived_Size(1) and internal_count(2) and internal_count(1))or
--    To      - (Derived_Size(0) and internal_count(2) and internal_count(1))or
-- ~~~~~~
--    SK   12/03/09
-- ^^^^^^
-- 1. Cleaned for SPYGLASS results.
-- 2. Removed reset condition from "BUS2IP_ADDR_11_2_BKP_P", "ONE_HOT_RDCE_P" &
--    "INT_COUNTER_P32", "INT_COUNTER_P32_BKP_P", "INT_COUNTER_P64_BKP_P", &
--    "INT_COUNTER_P64".
-- ~~~~~~
--    SK   12/09/09
-- ^^^^^^
-- 1. Added "ORed_CE" in port list as input port.
-- 2. Added ORed_CE protection for address back up in "BUS2IP_ADDR_11_2_BKP_P".
-- 3. Added ORed_CE protection for address back up in -
--    a. int_addr_enable_4kb, int_addr_enable_11_2, int_addr_enable_lw_bits.
-- 4. Replaced in 'Rdce_ored' with 'ORed_CE' in "ONE_HOT_RDCE_P".
-- 5. Renamed "rdce_falling_edge" to "CE_falling_edge".
-- 5. Replaced 'Rdce_ored' in 'CE_falling_edge' with 'ORed_CE'.
-- 6. Replaced "Rdce_ored" with "ORed_CE" in "ADDR_RELOAD_FLAG_P".
-- 7. Anded 'ORed_CE='1'' in elsif condition in "INT_COUNTER_P32".
-- 8. Anded 'ORed_CE='1'' in elsif condition in "INT_COUNTER_P64".
-- ~~~~~~
--    SK   12/21/09
-- ^^^^^^
-- 1. Added record_first_address in the signal declaration list.
-- 2. Added "ADDR_BKP_P" process & related logic in
--    "BUS2IP_ADDR_GEN_DATA_WDTH_32" generate statement.
-- 3. Updated "addr_reload" conditions in "INT_COUNTER_P32","ADDR_BITS_2_REG_P"
--    "ADDR_BITS_3_REG_P", "ADDR_BITS_4_REG_P","ADDR_BITS_5_REG_P" and in
--    "ADDR_BITS_11_6_REG_P".
-- 4. Added "ADDR_BKP_P" process & related logic in
--    "BUS2IP_ADDR_GEN_DATA_WDTH_64" generate statement.
-- ~~~~~~~
--   SK       01/24/10
-- ^^^^^^^
-- 1. Updated "proc_common_pkg.log2" with "proc_common_pkg.clog2".
--    Updated the instances of log2 to clog2.
-- ~~~~~~~
--   SK       03/21/10
-- ^^^^^^^
-- 1. Updated logic for address generation in 32/64 bit for narrow transfers.
-- 2. Add 1-for byte address, 2-for hw address, 4-for word accesses and
--        8-for double word accesses in ADDR_BKP_P process
-- 3. code clean up
-- 4. Changed Reset polarity to ACTIVE LOW. Defined local constant fot this.
-- ~~~~~~~
--  SK      07/29/10
-- ^^^^^^^
-- 1. Code clean for final publish.
-- ~~~~~~~

-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x"
--      reset signals:                          "rst", "rst_n"
--      generics:                               "C_*"
--      user defined types:                     "*_TYPE"
--      state machine next state:               "*_ns"
--      state machine current state:            "*_cs"
--      combinatorial signals:                  "*_cmb"
--      pipelined or register delay signals:    "*_d#"
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce"
--      internal version of output port         "*_i"
--      device pins:                            "*_pin"
--      ports:                                  - Names begin with Uppercase
--      processes:                              "*_PROCESS"
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_arith.conv_std_logic_vector;
use ieee.numeric_std.all;
use ieee.std_logic_misc.or_reduce;
use ieee.std_logic_misc.and_reduce;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.clog2;
-------------------------------------------------------------------------------

entity addr_gen is
    generic(
    C_S_AXI_ADDR_WIDTH     : integer range 32 to 32 := 32;
    C_S_AXI_DATA_WIDTH     : integer range 32 to 64 := 32;
    C_RDATA_FIFO_DEPTH     : integer := 0 -- 0 or 32
    );
    port(
    Bus2IP_Clk       : in std_logic;
    Bus2IP_Resetn    : in std_logic;

    S_AXI_WSTRB      : in std_logic_vector(((C_S_AXI_DATA_WIDTH/8)-1)downto 0);
    -- combo I/P signals
    Store_addr_info  : in std_logic;
    RNW_cmb          : in std_logic;

    axi_cycle_cmb    : in std_logic;
    Next_addr_strobe : in std_logic;
    Rdce_ored        : in std_logic;
    --Take_addr_back_up: in std_logic;
    Addr_int         : in std_logic_vector((C_S_AXI_ADDR_WIDTH-1)downto 0);
    ORed_CE          : in  std_logic;
    -- registered signals
    Derived_Burst    : in std_logic_vector(1 downto 0);
    Derived_Size     : in std_logic_vector(1 downto 0);
    Derived_Len      : in std_logic_vector(3 downto 0);
    Ip2Bus_Addr_ack  : in std_logic;
    IP2Bus_WrAck     : in std_logic;
    IP2Bus_RdAck     : in std_logic;
    Addr_Timeout     : in std_logic;
    Data_Timeout     : in std_logic;
    -- combo O/P signals

    -- registered O/P signals
    Bus2IP_Addr      : out std_logic_vector((C_S_AXI_ADDR_WIDTH-1)downto 0);

    stop_addr_incr : in std_logic

    );
end entity addr_gen;
-----------------------

------------------------------------
architecture imp of addr_gen is
------------------------------------
-- constant declaration
 -- Reset Active State
   constant ACTIVE_LOW_RESET : std_logic := '0';
------------------------------------
-- signal declaration
 signal wr_stb_align_addr : std_logic_vector
                 (((clog2(C_S_AXI_DATA_WIDTH/8))-1) downto 0):=(others => '0');
 signal internal_addr_bits: std_logic_vector
                 (((clog2(C_S_AXI_DATA_WIDTH/8))-1) downto 0):=(others => '0');

 signal addr_sel_0 : std_logic:= '0';
 signal addr_sel_1 : std_logic:= '0';
 signal addr_sel_2 : std_logic:= '0';
 signal addr_sel_3 : std_logic:= '0';

 signal address_Carry         : std_logic:= '0';
 signal or_reduced_wstb_3_0_n : std_logic;

 signal Bus2IP_Addr_i   : std_logic_vector(31 downto 0);
 signal Bus2IP_Addr_bkp : std_logic_vector(11 downto 0):=(others=> '0');

 signal int_addr_enable_11_2    : std_logic:= '0';
 signal int_addr_enable_lw_bits : std_logic:= '0';

 signal addr_reload      : std_logic:='0';

 signal addr_reload_flag : std_logic;
 signal CE_falling_edge  : std_logic:='0';
 signal CE_ored_d1       : std_logic:='0';

 signal record_first_address : std_logic_vector(11 downto 0):=(others=> '0');

------------------------------------
begin
-----
 Bus2IP_Addr              <= Bus2IP_Addr_i;


  -------------------
  -- BUS2IP_ADDR_BKP_P : Back up the bus2ip_address
  -------------------
  BUS2IP_ADDR_11_2_BKP_P : process(Bus2IP_Clk) is
  begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if ((Ip2Bus_Addr_ack='1')and(Rdce_ored = '1')) then
               Bus2IP_Addr_bkp(11 downto 0) <= Bus2IP_Addr_i(11 downto 0);
        end if;
     end if;
  end process BUS2IP_ADDR_11_2_BKP_P;
 --------------------------------------

 int_addr_enable_11_2     <= (Store_addr_info   or
                              (
                               (Ip2Bus_Addr_ack or
                                Addr_Timeout) and
                                (ORed_CE and (not stop_addr_incr))
                               )
                              );


 ----------- Below are the select line for MUX operation
 addr_sel_0 <= (Derived_Len(0) and Derived_Burst(1))or Derived_Burst(0);
 addr_sel_1 <= (Derived_Len(1) and Derived_Burst(1))or Derived_Burst(0);
 addr_sel_2 <= (Derived_Len(2) and Derived_Burst(1))or Derived_Burst(0);
 addr_sel_3 <= (Derived_Len(3) and Derived_Burst(1))or Derived_Burst(0);
 -----------

 ----------- all addresses are word/dword aligned addresses, only the BE decide
 --          which byte lane to be accessed
 Bus2IP_Addr_i(((clog2(C_S_AXI_DATA_WIDTH/8))-1) downto 0) <= (others => '0');
 --------------------------------------

 -- ADDR_BITS_31_12_REG_P: Address registering for upper order address bits
 ---------------------
 ADDR_BITS_31_12_REG_P:process(Bus2IP_Clk)
 ---------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if((Bus2IP_Resetn = ACTIVE_LOW_RESET)) then 
           Bus2IP_Addr_i(31 downto 12) <= (others => '0');
        elsif(Store_addr_info = '1')then
           Bus2IP_Addr_i(31 downto 12) <= Addr_int(31 downto 12);
        end if;
     end if;
 end process ADDR_BITS_31_12_REG_P;
 ----------------------------------
------------------------------------------------------------------------------

--BUS2IP_ADDR_GEN_DATA_WDTH_32:Address geenration for logic for 32 bit data bus
-- ============================
BUS2IP_ADDR_GEN_DATA_WDTH_32: if C_S_AXI_DATA_WIDTH = 32 generate
----------------------------
 -- address(2) calculation
 signal calc_addr_2: std_logic_vector(1 downto 0);
 signal addr_2_int : std_logic;
 signal addr_2_cmb : std_logic;
 -- address(3) calculation
 signal calc_addr_3: std_logic_vector(1 downto 0);
 signal addr_3_int : std_logic;
 signal addr_3_cmb : std_logic;
 -- address(4) calculation
 signal calc_addr_4: std_logic_vector(1 downto 0);
 signal addr_4_int : std_logic;
 signal addr_4_cmb : std_logic;
 -- address(5) calculation
 signal calc_addr_5: std_logic_vector(1 downto 0);
 signal addr_5_int : std_logic;
 signal addr_5_cmb : std_logic;
 -- address(11:6) calculation
 signal calc_addr_11_6: std_logic_vector(6 downto 0);
 signal addr_11_6_int : std_logic_vector(5 downto 0);
 signal addr_11_6_cmb : std_logic_vector(5 downto 0);
 -- address(6) calculation
 signal calc_addr_6: std_logic_vector(1 downto 0);
 signal addr_6_int : std_logic_vector(1 downto 0);
 signal addr_6_cmb : std_logic_vector(1 downto 0);

 signal internal_count : std_logic_vector(2 downto 0)    :=(others => '0');
 signal internal_count_bkp : std_logic_vector(2 downto 0):=(others => '0');
 -----
 begin
 -----

 -- INT_COUNTER_P32_BKP_P : Back up the lower counter bits
 -------------------
 INT_COUNTER_P32_BKP_P : process(Bus2IP_Clk) is
 begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
       if((IP2Bus_RdAck='1') and (Data_Timeout='0'))then
              internal_count_bkp  <= internal_count;
       end if;
    end if;
 end process INT_COUNTER_P32_BKP_P;
 --------------------------------------

 -------------------
 -- INT_COUNTER_P32: to store the the internal address lower bits
 -------------------
 INT_COUNTER_P32: process(Bus2IP_Clk) is
 begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Store_addr_info='1') then
                internal_count <= '0' & Addr_int(1 downto 0);
        elsif(
               ((Ip2Bus_Addr_ack='1') or (Addr_Timeout='1'))
                                      and (ORed_CE='1')
              )then
                internal_count <= internal_count + Derived_Size + '1';
        end if;
    end if;
 end process INT_COUNTER_P32;

-------------------

 address_Carry <= Derived_Size(1) or
                 (Derived_Size(0) and internal_count(1))or
                 (internal_count(0) and internal_count(1));

 calc_addr_2 <= ('0' & Bus2IP_Addr_i(2)) + ('0' & address_Carry);

 addr_2_int  <= calc_addr_2(0) when (addr_sel_0='1') else Bus2IP_Addr_i(2);

 addr_2_cmb  <= Addr_int(2) when (Store_addr_info='1') else addr_2_int;

--  ADDR_BITS_2_REG_P: store the 2nd address bit
 ------------------
 ADDR_BITS_2_REG_P:process(Bus2IP_Clk)
 ------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if((Bus2IP_Resetn = ACTIVE_LOW_RESET)) then
           Bus2IP_Addr_i(2) <= '0';
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(2) <= addr_2_cmb;
        end if;
     end if;
 end process ADDR_BITS_2_REG_P;
 ------------------

 calc_addr_3 <= ('0' & Bus2IP_Addr_i(3)) + ('0' & calc_addr_2(1));

 addr_3_int  <= calc_addr_3(0) when (addr_sel_1='1') else Bus2IP_Addr_i(3);

 addr_3_cmb  <= Addr_int(3) when (Store_addr_info='1') else addr_3_int;

--  ADDR_BITS_3_REG_P: store the third address bit
 ------------------
 ADDR_BITS_3_REG_P:process(Bus2IP_Clk)
 ------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if((Bus2IP_Resetn = ACTIVE_LOW_RESET)) then
           Bus2IP_Addr_i(3) <= '0';
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(3) <= addr_3_cmb;
        end if;
     end if;
 end process ADDR_BITS_3_REG_P;
 ------------------

 calc_addr_4 <= ('0' & Bus2IP_Addr_i(4)) + ('0' & calc_addr_3(1));

 addr_4_int  <= calc_addr_4(0) when (addr_sel_2='1') else Bus2IP_Addr_i(4);

 addr_4_cmb  <= Addr_int(4) when (Store_addr_info='1') else addr_4_int;

--  ADDR_BITS_4_REG_P: store the 4th address bit
 ------------------
 ADDR_BITS_4_REG_P:process(Bus2IP_Clk)
 ------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if((Bus2IP_Resetn = ACTIVE_LOW_RESET)) then
           Bus2IP_Addr_i(4) <= '0';
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(4) <= addr_4_cmb;
        end if;
     end if;
 end process ADDR_BITS_4_REG_P;
 ------------------

 calc_addr_5 <= ('0' & Bus2IP_Addr_i(5)) + ('0' & calc_addr_4(1));

 addr_5_int <= calc_addr_5(0) when (addr_sel_3='1') else Bus2IP_Addr_i(5);

 addr_5_cmb <= Addr_int(5) when (Store_addr_info='1') else addr_5_int;

--  ADDR_BITS_5_REG_P:store the 5th address bit
 ------------------
 ADDR_BITS_5_REG_P:process(Bus2IP_Clk)
 ------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if((Bus2IP_Resetn = ACTIVE_LOW_RESET)) then
           Bus2IP_Addr_i(5) <= '0';
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(5) <= addr_5_cmb;
        end if;
     end if;
 end process ADDR_BITS_5_REG_P;
 ------------------

 calc_addr_11_6 <= ('0'& Bus2IP_Addr_i(11 downto 6)) +
                                                   ("000000" & calc_addr_5(1));

 addr_11_6_int  <= calc_addr_11_6(5 downto 0) when (Derived_Burst(0)='1')
                   else
                   Bus2IP_Addr_i(11 downto 6);

 addr_11_6_cmb  <= Addr_int(11 downto 6) when(Store_addr_info='1')
                   else
                   addr_11_6_int(5 downto 0);

--  ADDR_BITS_11_6_REG_P: store the 11 to 6 address bits
 --------------------
 ADDR_BITS_11_6_REG_P:process(Bus2IP_Clk)
 --------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if((Bus2IP_Resetn = ACTIVE_LOW_RESET)) then
           Bus2IP_Addr_i(11 downto 6) <= (others => '0');
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(11 downto 6) <= addr_11_6_cmb(5 downto 0);
        end if;
     end if;
 end process ADDR_BITS_11_6_REG_P;
 ---------------------------------

------------------------------------------
end generate BUS2IP_ADDR_GEN_DATA_WDTH_32;
------------------------------------------

-- BUS2IP_ADDR_GEN_DATA_WDTH_64: below address logic is used for 64 bit dbus
-- ============================
BUS2IP_ADDR_GEN_DATA_WDTH_64: if C_S_AXI_DATA_WIDTH = 64 generate
 -- address(3) calculation
 signal calc_addr_3: std_logic_vector(1 downto 0);
 signal addr_3_int : std_logic;
 signal addr_3_cmb : std_logic;
 -- address(4) calculation
 signal calc_addr_4: std_logic_vector(1 downto 0);
 signal addr_4_int : std_logic;
 signal addr_4_cmb : std_logic;
 -- address(5) calculation
 signal calc_addr_5: std_logic_vector(1 downto 0);
 signal addr_5_int : std_logic;
 signal addr_5_cmb : std_logic;
 -- address(6) calculation
 signal calc_addr_6: std_logic_vector(1 downto 0);
 signal addr_6_int : std_logic;
 signal addr_6_cmb : std_logic;
 -- address(7) calculation
 signal calc_addr_7: std_logic_vector(1 downto 0);
 signal addr_7_int : std_logic;
 signal addr_7_cmb : std_logic;
 -- address(11:7) calculation
 signal calc_addr_11_7: std_logic_vector(5 downto 0);
 signal addr_11_7_int : std_logic_vector(4 downto 0);
 signal addr_11_7_cmb : std_logic_vector(4 downto 0);

 signal internal_count : std_logic_vector(3 downto 0):=(others => '0');
 signal internal_count_bkp : std_logic_vector(3 downto 0):=(others => '0');
 -----
 begin
 -----
 -------------------
  -- INT_COUNTER_P64_BKP_P : Back up the lower counter bits
  -------------------
  INT_COUNTER_P64_BKP_P : process(Bus2IP_Clk) is
  begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if((IP2Bus_RdAck='1') and (Data_Timeout='0'))then
               internal_count_bkp  <= internal_count;
        end if;
     end if;
  end process INT_COUNTER_P64_BKP_P;
 --------------------------------------

 --------------------
 --  INT_COUNTER_P64: to store the internal address bits
 --------------------
 INT_COUNTER_P64: process(Bus2IP_Clk)
 begin
    if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if (Store_addr_info = '1') then
                internal_count <= '0' & Addr_int(2 downto 0);
        elsif(
              ((Ip2Bus_Addr_ack = '1') or (Addr_Timeout = '1'))
                                      and (ORed_CE='1')
              )then
            if(Derived_Size(1) = '1') then
                internal_count <= internal_count + "100";
            else
                internal_count <= internal_count + Derived_Size + '1';
            end if;
        end if;
    end if;
 end process INT_COUNTER_P64;
 ----------------------------

 address_Carry<=(Derived_Size(1) and Derived_Size(0))   or -- for double word
                (Derived_Size(1) and internal_count(2)) or -- for word
                (Derived_Size(0) and internal_count(2) and internal_count(1))or -- for half word
                (internal_count(2) and internal_count(1) and
                                       internal_count(0)); -- for byte

 calc_addr_3 <= ('0' & Bus2IP_Addr_i(3)) + ('0' & address_Carry);

 addr_3_int  <= calc_addr_3(0) when (addr_sel_0='1') else Bus2IP_Addr_i(3);

 addr_3_cmb  <= Addr_int(3) when (Store_addr_info='1') else addr_3_int;

--  ADDR_BITS_3_REG_P: store the 3rd address bit
 ------------------
 ADDR_BITS_3_REG_P:process(Bus2IP_Clk)
 ------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if(((Bus2IP_Resetn = ACTIVE_LOW_RESET))) then
           Bus2IP_Addr_i(3) <= '0';
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(3) <= addr_3_cmb;
        end if;
     end if;
 end process ADDR_BITS_3_REG_P;
 ------------------
 calc_addr_4 <= ('0' & Bus2IP_Addr_i(4)) + ('0' & calc_addr_3(1));

 addr_4_int  <= calc_addr_4(0) when (addr_sel_1='1') else Bus2IP_Addr_i(4);

 addr_4_cmb  <= Addr_int(4) when (Store_addr_info='1') else addr_4_int;

--  ADDR_BITS_4_REG_P: store teh 4th address bit
 ------------------
 ADDR_BITS_4_REG_P:process(Bus2IP_Clk)
 ------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if(((Bus2IP_Resetn = ACTIVE_LOW_RESET)) ) then
           Bus2IP_Addr_i(4) <= '0';
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(4) <= addr_4_cmb;
        end if;
     end if;
 end process ADDR_BITS_4_REG_P;
 ------------------

 calc_addr_5 <= ('0' & Bus2IP_Addr_i(5)) + ('0' & calc_addr_4(1));

 addr_5_int  <= calc_addr_5(0) when (addr_sel_2='1') else Bus2IP_Addr_i(5);

 addr_5_cmb  <= Addr_int(5) when (Store_addr_info='1') else addr_5_int;

--  ADDR_BITS_5_REG_P: store the 5th address bit
 ------------------
 ADDR_BITS_5_REG_P:process(Bus2IP_Clk)
 ------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if(((Bus2IP_Resetn = ACTIVE_LOW_RESET)) ) then 
           Bus2IP_Addr_i(5) <= '0';
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(5) <= addr_5_cmb;
        end if;
     end if;
 end process ADDR_BITS_5_REG_P;
 ------------------

 calc_addr_6 <= ('0' & Bus2IP_Addr_i(6)) + ('0' & calc_addr_5(1));

 addr_6_int <= calc_addr_6(0) when (addr_sel_3='1') else Bus2IP_Addr_i(6);

 addr_6_cmb <= Addr_int(6) when (Store_addr_info='1') else addr_6_int;

--  ADDR_BITS_6_REG_P: store the 6th address bit
 ------------------
 ADDR_BITS_6_REG_P:process(Bus2IP_Clk)
 ------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if(((Bus2IP_Resetn = ACTIVE_LOW_RESET)) ) then 
           Bus2IP_Addr_i(6) <= '0';
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(6) <= addr_6_cmb;
        end if;
     end if;
 end process ADDR_BITS_6_REG_P;
 ------------------

 calc_addr_11_7 <= ('0' & Bus2IP_Addr_i(11 downto 7))
                                                  + ("00000" & calc_addr_6(1));

 addr_11_7_int  <= calc_addr_11_7(4 downto 0) when (Derived_Burst(0)='1')
                   else
                   Bus2IP_Addr_i(11 downto 7);

 addr_11_7_cmb  <= Addr_int(11 downto 7) when(Store_addr_info='1')
                   else
                   addr_11_7_int(4 downto 0);

--  ADDR_BITS_11_7_REG_P: store the 11 to 7 address bits
 --------------------
 ADDR_BITS_11_7_REG_P:process(Bus2IP_Clk)
 --------------------
 begin
     if (Bus2IP_Clk'event and Bus2IP_Clk='1') then
        if(((Bus2IP_Resetn = ACTIVE_LOW_RESET)) ) then 
           Bus2IP_Addr_i(11 downto 7) <= (others => '0');
        elsif(int_addr_enable_11_2 = '1')then
           Bus2IP_Addr_i(11 downto 7) <= addr_11_7_cmb(4 downto 0);
        end if;
     end if;
 end process ADDR_BITS_11_7_REG_P;
 ---------------------------------
end generate BUS2IP_ADDR_GEN_DATA_WDTH_64;
-------------------------------------------------------------------------------

--
end architecture imp;
