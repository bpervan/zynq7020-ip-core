-------------------------------------------------------------------------------
-- read_data_path - entity / architecture pair
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
-- Filename:        read_data_path.vhd
-- Version:         v1.00a
-- Description:     The AXI to PLBV46 Bridge module translates AXI
--                  transactions into PLBV46 transactions. It functions as a
--                  AXI slave on the AXI port and an PLBV46 master on
--                  the PLBV46 port.
--
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--           -- axi_slave_burst.vhd  (wrapper for top level)
--               -- control_state_machine.vhd
--               -- read_data_path.vhd
--               -- address_decode.vhd
--               -- addr_gen.vhd
--
-------------------------------------------------------------------------------
-- Author:      NSK
-- History:
--   NSK      08/20/2009           First version
-- ^^^^^^^
-- ~~~~~~~
--   SK      09/17/2009
-- ^^^^^^^
-- 1. added "Addr_Timeout" in port list, sensitivity list of RD_DATA_SM_P
--    and in IDLE state for rresp_cmb, rlast_cmb .
--    added wr_cycle_cmb to inform the code about the write access ccyel,
--    so the read signals will;not be generated
--
-- ~~~~~~~
--   NSK      10/05/2009
-- ^^^^^^^
-- 1. In type declaration of "STATE_TYPE" - Replaced "WAIT_LAST" by
--    "WAIT_DATA".
-- 2. Removed case "WAIT_LAST" from process "RD_DATA_SM_P"
-- 3. Added case for "WAIT_DATA" in process "RD_DATA_SM_P"
-- ~~~~~~~
--   SK      10/05/2009
-- ^^^^^^^
-- added "Addr_Timeout" in port list, sensitivity list of RD_DATA_SM_P
--                 and in IDLE state for rresp_cmb, rlast_cmb .
-- added wr_cycle_cmb to inform the code about the write access cycel,
-- so the read signals will;not be generated.
-- ~~~~~~~
--   SK      10/05/2009
-- ^^^^^^^
-- added "rd_data_fifo_error" in sensitivity list of RD_DATA_SM_P.
-- ~~~~~~~
--   NSK      10/11/2009
-- ^^^^^^^
-- 1. Added input port "S_AXI_ARLEN", "Store_addr_info".
-- 2. Removed input port "Last_rd_data" is renamed to "Last_rd_data_ipic"
-- 3. Added signal "last_rd_data" & "rd_data_count".
-- 4. Added process "RDDATA_CNT_P" and assignment for "last_data"
-- ~~~~~~~
--   SK      10/14/2009
-- ^^^^^^^
-- 1.Updated the IDLE state coding condition to come out of IDLE state based on
--    "wr_cycle_cmb","Data_Timeout","Addr_Timeout","IP2Bus_RdAck".
-- ~~~~~~~
--   NSK      10/15/2009
-- ^^^^^^^
-- 1.Updated logic for "RdFIFO_Space_two". fifo_full condition is considered
--    for generation of this signal.
-- ~~~~~~~
--   NSK      10/20/2009
-- ^^^^^^^
-- Error: - "rresp_cmb" goes "X"
-- Debug: - In "WAIT_DATA" state - since there is no previous data written in
-- the current FIFO location the "rd_data_fifo_error" goes "X"
-- Fix: - In process "RD_DATA_SM_P"; in state "WAIT_DATA"; in assignment of
-- "rresp_cmb" - replaced "rd_data_fifo_error" by "IP2Bus_Error".
-- ~~~~~~~
--   NSK      10/21/2009
-- ^^^^^^^
-- Error: - "rresp_cmb" goes "X"
-- Debug: - In "DATA" state - there is only one data left in the FIFO and
-- also "RREADY" is asserted from AXI. The FIFO will go empty in the next
-- cycle. Hence need to find the FIFO occupany of 1 and check with "RREADY".
-- Fix: -
-- 1. Added signal "last_fifo_data".
-- 2. Assigned "last_fifo_data" in "NO_RD_DATA_BUFFER_GEN" &
--    "RD_DATA_BUFFER_GEN"
-- 3. In process "RD_DATA_SM_P": -
--    A. Added "last_fifo_data" to sensitivitty.
--    B. In "DATA" state "rd_fifo_empty" replaced by "last_fifo_data"
-- ~~~~~~~
--   SK      10/21/2009
-- ^^^^^^^
-- 1. Added Rd_barrier in INPUT port list.
-- 2. Added Read Barrier transaction support.
--    Updated "IDLE" and "LAST" states in "RD_DATA_SM_P".
--    Rd_barrier signal is registered to rd_barrier_reg in "SYNCH_RST_REG_P".
--    Added "Rd_barrier" and "rd_barrier_reg" in the sensitivity list of
--    "RD_DATA_SM_P".
-- ~~~~~~~
--   SK      10/21/2009
-- ^^^^^^^
-- 1. Added "wr_cycle_reg" in "SYNCH_RST_REG_P" and registered
--    the "wr_cycle_cmb" signal.
-- 2. Added "(Addr_Timeout and (not wr_cycle_reg)" in "rd_fifo_wr_en".
-- 3. Logically ANDed "IP2Bus_Error" with "IP2Bus_RdAck" in "rresp_cmb" in
--    "WAIT_DATA", "DATA" states.
-- ~~~~~~~
--   NSK      10/26/2009
-- ^^^^^^^
-- 1. Replaced "or_reduce" with  "and_reduce" in "last_fifo_data" logic.
-- ~~~~~~~
--   NSK      10/27/2009
-- ^^^^^^^
-- 1. "rd_fifo_empty" logic is updated for fifo_empty condition under
--    "RD_DATA_BUFFER_GEN".
-- 2. "rd_fifo_rd_en" condition is updated with "fifo_empty" in  place of
--    "rd_fifo_empty" under "RD_DATA_BUFFER_GEN".
-- ~~~~~~~
--   NSK      10/29/2009
-- ^^^^^^^
-- 1. Code clean up before initernal review
-- ~~~~~~~
--   SK       11/16/2009
-- ^^^^^^^
-- 1. Added "Addr_Timeout" in "rresp_cmb" logic, to overcome missing error of
--    address timeout. Added -coverage_off/on to improve code coverage.
-- ~~~~~~~
--   SK       11/18/2009
-- ^^^^^^^
-- 1. Removed BARRIER support code from the core.
-- ~~~~~~~
--   SK       11/19/2009
-- ^^^^^^^
-- 1. Removed "Addr_Timeout" from the IDLE,DATA,WAIT_DATA states under
--    "rresp_cmb" condition.
-- ~~~~~~~
--   SK       11/20/2009
-- ^^^^^^^
-- 1. Cosmetic update.
-- ~~~~~~~
--   SK       12/06/09
-- ^^^^^^^
-- 1. Replaced logic for "last_fifo_data" with simple reduction logic.
-- ~~~~~~~
--   SK       12/17/09
-- ^^^^^^^
-- 1. Added AND condition of "Rdce_ored" in "rd_fifo_wr_en" for
--   "RD_DATA_BUFFER_GEN" in order to prevent the read-ack causing the IPIC data
--   in to FIFO when RDCe signal is deasserted.
-- ~~~~~~~
--   SK       01/24/10
-- ^^^^^^^
-- 1. Updated "proc_common_pkg.log2" with "proc_common_pkg.clog2".
--    Updated the instances of log2 to clog2.
-- ~~~~~~~
--  SK        05/11/10
-- ^^^^^^^
-- 1. Updated NO_RD_DATA_BUFFER_GEN for removing the extra conditon checks on
--    S_AXI_RDATA bus from bus2ip_data.
-- 2. Added constant ALL_1 : std_logic_vector(0 to COUNTER_WIDTH-1) 
--                         :=(others => '1') in RD_DATA_BUFFER_GEN.
-- 3. In "UPDN_COUNTER_I", replaced Load_In => (others => '1'), with 
--                                  Load_In =>  ALL_1,
-- 4. Added Addr_Timeout condiotion in "rresp_cmb" signal logic in IDLE, DATA,
--    WAIT_DATA
-- ~~~~~~~
--  SK      07/29/10
-- ^^^^^^^
-- 1. Code clean for final publish.
-- ~~~~~~~
---------------------------------------------------------------------------
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
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use IEEE.std_logic_arith.conv_std_logic_vector;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.clog2;
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.family_support.all;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.or_gate128;

------------------------
-- Entity Section
------------------------
entity read_data_path is
    generic (
---- System Parameters
     C_FAMILY                   : string                 := "virtex6";
     C_RDATA_FIFO_DEPTH         : integer                := 0;-- 0 or 32
     C_INCLUDE_TIMEOUT_CNT      : integer range 0 to 1   := 1;
     C_TIMEOUT_CNTR_VAL         : integer                := 8;-- 8 or 16
---- AXI Parameters
     C_S_AXI_DATA_WIDTH         : integer range 32 to 64 := 32
     );
    port (
--  -- AXI Slave signals ------------------------------------------------------
       S_AXI_ACLK         : in  std_logic;
       S_AXI_ARESETN      : in  std_logic;

       S_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
       S_AXI_RDATA        : out std_logic_vector
                                ((C_S_AXI_DATA_WIDTH-1) downto 0);
       S_AXI_RRESP        : out std_logic_vector(1 downto 0);
       S_AXI_RLAST        : out std_logic;
       S_AXI_RVALID       : out std_logic;
       S_AXI_RREADY       : in  std_logic;
      -- Controls to the IP/IPIF modules
       Store_addr_info    : in  std_logic;

       IP2Bus_Data        : in  std_logic_vector
                                ((C_S_AXI_DATA_WIDTH-1) downto 0 );
       IP2Bus_RdAck       : in  std_logic;
       IP2Bus_AddrAck     : in  std_logic;
       IP2Bus_Error       : in  std_logic;

       Rd_Single          : in  std_logic;
       Last_rd_data_ipic  : in  std_logic;
       Data_Timeout       : in  std_logic;
       Addr_Timeout       : in  std_logic;
       wr_cycle_cmb       : in  std_logic;

       Rd_data_sm_ps_IDLE : out std_logic;
       RdFIFO_Space_two   : out std_logic;
       Rdce_ored          : in std_logic ;
       LAST_data_from_FIFO: out std_logic;
       No_addr_space      : out std_logic;
       last_data_for_rd_tr : out std_logic;

       load_addr_fifo : in std_logic
        );

end entity read_data_path;
-------------------------------------------------------------------------------

------------------------
-- Architecture Section
------------------------
architecture imp of read_data_path is
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
-- Reset Active State
   constant ACTIVE_LOW_RESET : std_logic := '0';
-----------------------------------
-- Type Declaration
---------------------------
   type STATE_TYPE is ( IDLE, LAST, DATA, WAIT_DATA );
--
--  Signal Declaration
---------------------------
    signal rd_data_ps         : STATE_TYPE;
    signal rd_data_ns         : STATE_TYPE;
--
    signal rd_data_fifo_error : std_logic;
    signal rd_fifo_empty      : std_logic;

    signal rvalid_cmb         : std_logic;
    signal rvalid_reg         : std_logic;

    signal rlast_cmb          : std_logic;
    signal rlast_reg          : std_logic;

    signal rresp_cmb          : std_logic;
    signal rresp_reg          : std_logic;

    signal rd_data_sm_ns_IDLE : std_logic;
    signal rd_fifo_out        : std_logic_vector(C_S_AXI_DATA_WIDTH downto 0);
    signal last_rd_data       : std_logic;
    signal rd_data_count      : std_logic_vector(7 downto 0);
    signal rd_fifo_full       : std_logic;
    signal last_fifo_data     : std_logic;

    signal wr_cycle_reg       : std_logic;
    signal active_high_rst    : std_logic;

    signal rvalid_cmb_dup     : std_logic;

    attribute max_fanout                     : string;
    attribute max_fanout   of rvalid_cmb     : signal is "30";
    attribute max_fanout   of rvalid_cmb_dup : signal is "30";


    attribute equivalent_register_removal                   : string;
    attribute equivalent_register_removal of rvalid_cmb_dup : signal is "no";
    
    signal last_rd_data_d1  : std_logic; 
    signal rd_data_sm_ps_LAST  : std_logic;
    signal RdFIFO_Space_two_int  : std_logic;

    signal addr_cnt_rst_cmb    : std_logic;
    signal addr_cnt_rst_reg    : std_logic; 
    signal reset_addr_fifo     : std_logic; 
    signal addr_fifo_local_rst : std_logic;
    signal rd_data_sm_ps_rest  : std_logic;
--
-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin
    -- ACTIVE_HIGH_RESET_P: Convert active low to active high reset for
    --                      proc common library components
    -------------
    ACTIVE_HIGH_RESET_P: process (S_AXI_ACLK) is
    --------------------
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            active_high_rst <= not(S_AXI_ARESETN);
        end if;
    end process ACTIVE_HIGH_RESET_P;
    ---------------------------------------------------------------------------

------------------------
-- NO_RD_DATA_BUFFER_GEN: when read FIFO is not used, below logic is geenrated
------------------------
    NO_RD_DATA_BUFFER_GEN : if (C_RDATA_FIFO_DEPTH = 0) generate
------------------------
-- RDDATA_P:Register the ip2bus_data before sending it to the AXI read channel
------------------------
     RDDATA_P: process (S_AXI_ACLK) is
     begin
         if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
             if ((S_AXI_ARESETN=ACTIVE_LOW_RESET) ) then 
                 S_AXI_RDATA <= (others => '0');
             elsif ((IP2Bus_RdAck='1')) then-- and

                 S_AXI_RDATA <= IP2Bus_Data;
             end if;
         end if;
     end process RDDATA_P;

     rd_data_fifo_error <= (IP2Bus_Error and IP2Bus_RdAck) or Data_Timeout 
                                                           or Addr_Timeout;
     rd_fifo_empty      <= '1';
     RdFIFO_Space_two   <= '0';
     last_fifo_data     <= '1';

    end generate NO_RD_DATA_BUFFER_GEN;

------------------------
-- RD_DATA_BUFFER_GEN :Below logic is used if the FIFO is configured in design.
------------------------
    RD_DATA_BUFFER_GEN : if (C_RDATA_FIFO_DEPTH > 0) generate

    constant ZEROES : std_logic_vector(0 to clog2(C_RDATA_FIFO_DEPTH)-1)
                  := (others => '0');



    constant RD_DATA_FIFO_DWIDTH : integer := (C_S_AXI_DATA_WIDTH+1);
    constant COUNTER_WIDTH       : integer := clog2(C_RDATA_FIFO_DEPTH);

    constant ALL_1          : std_logic_vector(0 to COUNTER_WIDTH-1) 
                            := (others => '1');
    
    constant ALL_2          : std_logic_vector(0 to COUNTER_WIDTH-1) 
                            := (others => '1');

    signal error_in         : std_logic;
    signal updn_cnt_en      : std_logic;
    signal cnt              : std_logic_vector((COUNTER_WIDTH-1) downto 0);
    signal rd_fifo_data_in  : std_logic_vector
                               (C_S_AXI_DATA_WIDTH downto 0);
    signal rd_fifo_data_out : std_logic_vector
                               (C_S_AXI_DATA_WIDTH downto 0);
    signal rd_fifo_wr_en    : std_logic;
    signal rd_fifo_rd_en    : std_logic;
    signal fifo_empty       : std_logic;


    signal fifo_location    : std_logic_vector((COUNTER_WIDTH-1) downto 0);

    signal cnt1_down : std_logic;
    signal cnt1_updn : std_logic;
    
    -----
    begin
    -----
        error_in        <= (IP2Bus_Error and IP2Bus_RdAck) or Data_Timeout 
                                                           or Addr_Timeout;
        updn_cnt_en     <= rd_fifo_rd_en xor rd_fifo_wr_en;
        rd_fifo_data_in <= (IP2Bus_Data & error_in);
        rd_fifo_wr_en   <= Data_Timeout or
                           (IP2Bus_RdAck) or
                           (Addr_Timeout and (not wr_cycle_reg));
        rd_fifo_rd_en   <= (not fifo_empty) and S_AXI_RREADY;

        rd_fifo_empty   <= fifo_empty or (rvalid_reg   and
                                          S_AXI_RREADY and
                                          last_fifo_data);
        ------------------------
        -- UPDN_COUNTER_I : The below counter used to keep track of FIFO rd/wr
        --                  The counter is loaded with the max. value at reset
        -------------------
        UPDN_COUNTER_I : entity proc_common_v3_00_a.counter_f
          generic map(
            C_NUM_BITS    =>  COUNTER_WIDTH,
            C_FAMILY      =>  "nofamily"
              )
          port map(
            Clk           =>  S_AXI_ACLK,      -- in
            Rst           =>  '0',             -- in
            Load_In       =>  ALL_1,           -- in 
            Count_Enable  =>  updn_cnt_en,     -- in
            ----------------
            Count_Load    =>  active_high_rst, -- in 
            ----------------
            Count_Down    =>  rd_fifo_wr_en,   -- in
            Count_Out     =>  cnt,             -- out std_logic_vector
            Carry_Out     =>  open             -- out
            );

        ------------------------
       RdFIFO_Space_two_int <= or_reduce(cnt(COUNTER_WIDTH-1 downto 1))
                                      and (not rd_fifo_full);
       RdFIFO_Space_two <= RdFIFO_Space_two_int;
       
       last_fifo_data   <= (and_reduce(cnt(COUNTER_WIDTH-1 downto 1))) and
                                                              (not cnt(0));

       LAST_data_from_FIFO  <= not(or_reduce(cnt(COUNTER_WIDTH-1 downto 1)))
                                      and (cnt(0));
        ------------------------
        -- RDATA_FIFO_I : read buffer
        -----------------
        RDATA_FIFO_I : entity proc_common_v3_00_a.srl_fifo_rbu_f
        generic map (
                     C_DWIDTH => RD_DATA_FIFO_DWIDTH,
                     C_DEPTH  => C_RDATA_FIFO_DEPTH,
                     C_FAMILY => C_FAMILY
                    )
        port map (
                     Clk           => S_AXI_ACLK,       -- in
                     --------------
                     Reset         => active_high_rst,  -- in
                     --------------
                     FIFO_Write    => rd_fifo_wr_en,    -- in 
                     Data_In       => rd_fifo_data_in,  -- in std_logic_vector
                     FIFO_Read     => rd_fifo_rd_en,    -- in 
                     Data_Out      => rd_fifo_out,      -- out std_logic_vector
                     FIFO_Full     => rd_fifo_full,     -- out
                     FIFO_Empty    => fifo_empty,       -- out
                     Addr          => open,             -- out std_logic_vector
                     Num_To_Reread => ZEROES,           -- in  std_logic_vector
                     Underflow     => open,             -- out
                     Overflow      => open              -- out
                 );

        ------------------------
        rd_data_fifo_error <= rd_fifo_out(0);
        S_AXI_RDATA        <= rd_fifo_out(RD_DATA_FIFO_DWIDTH-1 downto 1);


        addr_fifo_local_rst <= reset_addr_fifo or active_high_rst;

        cnt1_down <= (IP2Bus_AddrAck or Addr_Timeout)and 
	              Rdce_ored                      and 
		     (not(wr_cycle_cmb));
        cnt1_updn <= (cnt1_down xor ((not fifo_empty) and S_AXI_RREADY 
	              and 
		     (not (and_reduce(fifo_location)))and (not(wr_cycle_cmb))));

        UPDN_COUNTER_II : entity proc_common_v3_00_a.counter_f
          generic map(
            C_NUM_BITS    =>  COUNTER_WIDTH,
            C_FAMILY      =>  "nofamily"
              )
          port map(
            Clk           =>  S_AXI_ACLK,      -- in
            Rst           =>  addr_fifo_local_rst,             -- in
            Load_In       =>  ALL_1,           
            Count_Enable  =>  cnt1_updn,     -- in
            Count_Down    =>  cnt1_down,     -- in
            ----------------
            Count_Load    =>  load_addr_fifo, -- in -- S_AXI_ARESET,
            ----------------
            Count_Out     =>  fifo_location,  -- out std_logic_vector
            Carry_Out     =>  open            -- out
            );

    -- NO_ADDR_SPACE_P: this process will generate the no address space signal
    --                  based upon the space available in data FIFO.
    NO_ADDR_SPACE_P: process(S_AXI_ACLK) is
    begin
        if S_AXI_ACLK'event and S_AXI_ACLK='1' then
          if (S_AXI_ARESETN=ACTIVE_LOW_RESET) then
             No_addr_space <= '0';  
          elsif
           ((fifo_location(4) and not(and_reduce(fifo_location(3 downto 0)))) or 
            addr_fifo_local_rst )= '1' then

            No_addr_space <= '0';
          elsif((not fifo_location(4))   and 
              (not rd_data_sm_ps_rest) and 
              (not fifo_location(3) and not fifo_location(2) and 
	       not fifo_location(0) and fifo_location(1))
              )='1' or rd_fifo_full = '1' or 
	      RdFIFO_Space_two_int = '0' 
              then
            No_addr_space <= '1';
          end if;
        end if;    
      end process NO_ADDR_SPACE_P;

    end generate RD_DATA_BUFFER_GEN;

------------------------
-- RDDATA_CNT_P : read data counter from AXI side
------------------------
    RDDATA_CNT_P: process (S_AXI_ACLK) is
    begin
        if S_AXI_ACLK'event and S_AXI_ACLK='1' then
            if (S_AXI_ARESETN=ACTIVE_LOW_RESET) then
                rd_data_count <= (others => '0');
            elsif (Store_addr_info='1') then
                rd_data_count <= S_AXI_ARLEN;
            elsif ((rvalid_reg='1') and (S_AXI_RREADY='1')) then
                rd_data_count <= (rd_data_count - '1');
            end if;
        end if;
    end process RDDATA_CNT_P;

-------------
 

    last_rd_data <= not(or_reduce(rd_data_count(7 downto 1))) and
                    ((not rd_data_count(0)) or
                     (rvalid_reg and S_AXI_RREADY));
last_data_for_rd_tr <= last_rd_data;
   D1: process (S_AXI_ACLK) is
    --------------------
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            last_rd_data_d1 <= last_rd_data;
        end if;
    end process D1;
------------------------
-- Process for read data state machine
------------------------
    RD_DATA_SM_P: process ( rd_data_ps,
                            Rd_Single,
                            S_AXI_RREADY,

                            IP2Bus_RdAck,
                            IP2Bus_Error,

                            rvalid_reg,
                            rlast_reg,
                            rresp_reg,

                            Data_Timeout,
                            Addr_Timeout,
                            last_fifo_data,
                            last_rd_data,
                            rd_fifo_empty,
                            rd_data_fifo_error,

                            wr_cycle_cmb
                          ) is
    begin

        rvalid_cmb     <= rvalid_reg;
        rvalid_cmb_dup <= rvalid_reg;

        rlast_cmb    <= rlast_reg;
        rresp_cmb    <= rresp_reg;
        reset_addr_fifo <= '0';
       

        case rd_data_ps is

            when IDLE => if (wr_cycle_cmb='0')then
                           if ((Data_Timeout='1') or
                                  (Addr_Timeout='1') or
                                  (IP2Bus_RdAck='1')
                                  )then
                                if (Rd_Single='1') then
                                     rd_data_ns <= LAST;
                                else
                                     rd_data_ns <= DATA;
                                end if;
                                
                           else
                                rd_data_ns <= IDLE;
                           end if;
                         else
                                rd_data_ns <= IDLE;
                         end if;

                         ---- duplicated to reduce the fan out starts ---
                         rvalid_cmb_dup <= IP2Bus_RdAck  or
                                         ((Data_Timeout  or
                                          Addr_Timeout) and (not wr_cycle_cmb));
                         ----------------------- ends -- 
                         rvalid_cmb <= IP2Bus_RdAck    or
                                       ((Data_Timeout  or
                                         Addr_Timeout) and (not wr_cycle_cmb));

                         rlast_cmb  <= Rd_Single          and
                                       (not wr_cycle_cmb) and
                                       (IP2Bus_RdAck or
                                        Data_Timeout or
                                        Addr_Timeout);
                         rresp_cmb <= (Addr_Timeout or --Addr_Timeout added newly
                                       Data_Timeout or (IP2Bus_Error and
                                                        IP2Bus_RdAck))
                                       and (not wr_cycle_cmb);


            when LAST => if (S_AXI_RREADY='1') then
                             rd_data_ns <= IDLE;
                             reset_addr_fifo <= '1';
                         else
                           rd_data_ns <= LAST;
                         end if;

                         rvalid_cmb_dup <= not S_AXI_RREADY;
                         rvalid_cmb     <= not S_AXI_RREADY;

                         rlast_cmb  <= (not S_AXI_RREADY);

            when DATA => if (last_rd_data='1') then
                             if((IP2Bus_RdAck='1') or
                                (rd_fifo_empty='0')or
                                (Data_Timeout='1') or
                                (Addr_Timeout='1')
                                ) then
                                 rd_data_ns <= LAST;
                             else
                                 rd_data_ns <= WAIT_DATA;
                             end if;
                         elsif ((S_AXI_RREADY='0')   or
                                (IP2Bus_RdAck='1')   or
                                (last_fifo_data='0') or
                                (Data_Timeout='1')   or
                                (Addr_Timeout='1')
                               ) then
                             rd_data_ns <= DATA;
                         else
                             rd_data_ns <= WAIT_DATA;
                         end if;

                         if (S_AXI_RREADY='1') then
                             rresp_cmb <= Data_Timeout       or
                                          rd_data_fifo_error;
                         else
                             rresp_cmb <= rresp_reg;
                         end if;

                         --------- duplicate to reduce fan out starts -----
                         rvalid_cmb_dup <= (not S_AXI_RREADY)   or
                                           (not last_fifo_data) or
                                           IP2Bus_RdAck        or
                                           Data_Timeout        or
                                           Addr_Timeout;
                         -------------------------------------------- ends --
                         rvalid_cmb <= (not S_AXI_RREADY)   or
                                       (not last_fifo_data) or
                                        IP2Bus_RdAck        or
                                        Data_Timeout        or
                                        Addr_Timeout;

                         rlast_cmb  <= last_rd_data and
                                       (IP2Bus_RdAck         or
                                        Data_Timeout         or
                                        (not last_fifo_data) or
                                        Addr_Timeout);


            when WAIT_DATA => if ((IP2Bus_RdAck='0') and
                                  (Data_Timeout='0') and
                                  (Addr_Timeout='0')
                                  ) then
                                  rd_data_ns <= WAIT_DATA;
                              elsif(last_rd_data='1') then
                                  rd_data_ns <= LAST;
                              else
                                  rd_data_ns <= DATA;
                              end if;

                              rresp_cmb  <= Data_Timeout or
                                            Addr_Timeout or -- added newly
                                            (IP2Bus_Error and IP2Bus_RdAck);

                              --- duplicated to reduce the fan out starts ----
                              rvalid_cmb_dup <= IP2Bus_RdAck or
                                                Data_Timeout or
                                                Addr_Timeout;
                              ----------------------------------------- ends --- 
                              rvalid_cmb <= IP2Bus_RdAck or
                                            Data_Timeout or
                                            Addr_Timeout;

                              rlast_cmb  <= last_rd_data and
                                            (IP2Bus_RdAck or
                                             Data_Timeout or
                                             Addr_Timeout);
            --coverage off
            when others => rd_data_ns <= IDLE;
            --coverage on
        end case;
    end process RD_DATA_SM_P;


    rd_data_sm_ns_IDLE    <= '1' when (rd_data_ns=IDLE) else '0';

    rd_data_sm_ps_rest <= '1' when (rd_data_ps=IDLE) else '0';
------------------------
--  -- Register with synchronous reset
------------------------
    SYNCH_RST_REG_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
    
            S_AXI_RRESP(0) <= '0';
    
            if (S_AXI_ARESETN=ACTIVE_LOW_RESET)or(rd_data_sm_ns_IDLE='1') then
                rd_data_ps         <= IDLE;
                rd_data_sm_ps_IDLE <= '1';
                rresp_reg          <= '0';
                rvalid_reg         <= '0';
                rlast_reg          <= '0';
                wr_cycle_reg       <= '0';

            else
                rd_data_ps         <= rd_data_ns;
                Rd_data_sm_ps_IDLE <= rd_data_sm_ns_IDLE;
                rresp_reg          <= rresp_cmb;
                rvalid_reg         <= rvalid_cmb;
                rlast_reg          <= rlast_cmb;
                wr_cycle_reg       <= wr_cycle_cmb;

            end if;
        end if;
    end process SYNCH_RST_REG_P;


    S_AXI_RVALID   <= rvalid_reg;
    S_AXI_RLAST    <= rlast_reg;
    S_AXI_RRESP(1) <= rresp_reg;


end imp;
