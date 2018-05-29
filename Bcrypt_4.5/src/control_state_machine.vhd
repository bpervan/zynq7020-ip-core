-------------------------------------------------------------------------------
-- control_state_machine - entity / architecture pair
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
-- ** Copyright 2009 Xilinx, Inc.                                        **
-- ** All rights reserved.                                               **
-- **                                                                    **
-- ** This disclaimer and copyright notice must be retained as part      **
-- ** of this file at all times.                                         **
-- ************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        control_state_machine.vhd
-- Version:         v1.00a
-- Description:     The control state machine governs all the logic for
--                  controlling the AXI and IPIC interface traffic.
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:
--           -- axi_slave_burst.vhd  (wrapper for top level)
--               -- control_state_machine.vhd
--               -- read_data_path.vhd
--               -- address_decode.vhd
--               -- address_gen.vhd
--
-------------------------------------------------------------------------------
-- Author:      NSK
-- History:
--   NSK      08/20/2009           First version
-- ^^^^^^^
-- ~~~~~~~
--   SK      09/24/2009
-- ^^^^^^^
-- 1. Added wr_cycle_cmb,axi_cycle_cmb new signals in the port list
-- 2. Corrected logic for read and write single access generation
-- 3. Corrected logic for BVALId signal generation
-- 4. Corrected logic for WAIT_WR_DATA state for proper generation of wready
--    signal
-- ~~~~~~~
--   NSK      10/02/2009
-- ^^^^^^^
-- 1. Added generate block for state machine
--    A. C_RDATA_FIFO_DEPTH > 0
--    B. C_RDATA_FIFO_DEPTH = 0
-- 2. Added signal "last_data_cmb" and "last_data_reg"
-- 3. Replaced last_data by last_data_reg
-- 4. Added output port "Last_data" and assigned "Last_data <= last_data_reg"
-- 5. Modified the process "LAST_DATA_P": -
--    A. Using signals "second_last_data AND ored_out"
--    B. Using signals "last_data_cmb"
-- ~~~~~~~
--   NSK      10/03/2009
-- ^^^^^^^
-- 1. Added signal "axi_last_rd_data", "rst_axi_last_rd_data"
-- 2. Added generate block "AXI_RD_DATA_COUNTER_GEN"
--    A. Added process "AXI_LAST_RD_DATA_P" in above generate block for
--       "axi_last_rd_data"
-- 3. In process "ADDR_SM_P" of generate block "ADDR_SM_NO_RD_DATA_BUFFER_GEN":
--    A. Assigned "rst_axi_last_rd_data"
--    B. In case "RD_WAIT_RREADY": -
--       a. Replaced "last_data_reg" by "axi_last_rd_data"
--       b. Added assignemnt for "Rst_Rd_CE"
--    C. Added "axi_last_rd_data" in sensitivity
--    D. In case "IDLE" modified the assignment for "bus2ip_burst_cmb" - all
--       reads are singles
-- ~~~~~~~
--   SK      10/07/2009
-- ^^^^^^^
-- 1. corrected RD_SINGLE logic in ADDR_SM_NO_RD_DATA_BUFFER_GEN, to add
--    Enable_RdCE, Rst_Rd_CE
-- 2. corrected WR_SINGLE logic to add Rst_CS.
-- ~~~~~~~
--   SK      10/08/2009
-- ^^^^^^^
-- 1. added "(addr_ns=IDLE)" in reset condition in "BUS2IP_BE_P" process to
-- 2. negate the Bus2IP_BE signals after the data ack.
-- 3. added "RNW" signal as combinational output for address decoder.
-- 4. added addr_timeout_int='1' in "AXI_LAST_RD_DATA_P". this was due to FIFO=0
--    state, the read_single state was hanging indefinitely.
--~~~~~
--   SK        10/08/2009
-- ^^^^^^^
-- Removed "AXI_LAST_RD_DATA_P". In place of generation of this logic "S_AXI_RLAST_int"
-- is used in "RD_WAIT_RREADY" state of "ADDR_SM_NO_RD_DATA_BUFFER_GEN" generate logic.
-- ~~~~~~~
-- SK        10/09/2009
-- ^^^^^^^
-- 1. added "(axi_cycle_cmb_int='0')" in "ADDR_CTRL_REG_P" process to make the
--    Bus2IP_Burst "0", when the SM goes to idle state.
-- 2. Output port "rd_single_cmb" changed to "rd_single_reg".
-- 3. In process "ADDR_CTRL_REG_P" added assignment for "rd_single_reg".
-- ~~~~~~~
-- NSK        10/11/2009
-- ^^^^^^^
-- 1. In "ADDR_SM_RD_DATA_BUFFER_GEN"; in process "ADDR_SM_P": -
--    A. In case "RD_LAST" - assignment for "Rst_Rd_CE" is changed to
--       Rst_Rd_CE <= last_data_reg and (IP2Bus_RdAck or data_timeout_int);
--    B. In case "RD_ADDR_LAST" - removed direct assignment for
--       "axi_cycle_cmb_int" in else part.
-- 2. Changed assignement for "rd_single_cmb_int" - directly reduced OR of
--    "S_AXI_ARLEN".
-- 3. Changed assignement for "rd_single_cmb" - directly assigned to
--    "rd_single_cmb_int".
-- 4. In process "ADDR_SM_P" - in IDLE assignment
--    store_addr_info_int <= Rd_data_sm_ps_IDLE;
-- ~~~~~~~
-- SK         10/12/2009
-- ^^^^^^^
-- 1. Removed "S_AXI_WID" port from the port list.
-- 2. Added "RW_FLAG_P" process
-- 3. Updated logic in "ADDR_SM_RD_DATA_BUFFER_GEN" and in
--    "ADDR_SM_NO_RD_DATA_BUFFER_GEN" for "rw_flag_reg".
-- 4. Updated logic in IDLE state for "arready_cmb","awready_cmb","wready_cmb"
--    "bvalid_cmb","rnw_cmb","bus2ip_rd_req_cmb","bus2ip_wr_req_cmb",
--    "bus2ip_burst_cmb","Enable_WrCE","Enable_RdCE" to accomodate "rw_flag_reg"
--    related logic.
-- 5. Points 2 to 4 are added for Round Robin logic.
-- ~~~~~~~
--   SK      10/14/2009
-- ^^^^^^^
-- 1. In "ADDR_SM_NO_RD_DATA_BUFFER_GEN" generate
--    statements, "addr_timeout_int and data_timeout_int" is added in RD_SINGLE,
--    WR_SINGLE, WR_BURST, WR_LAST states.
-- 2. in "BUS2IP_BE_P" updated the logic for (rnw_cmb='0' and (wready_cmb='1')
-- 3. Removed Rst_Wr_CE from WAIT_WR_DATA in "ADDR_SM_NO_RD_DATA_BUFFER_GEN"
-- ~~~~~~~
--   SK      10/14/2009
-- ^^^^^^^
-- 1. Enable_RdCE condition is added in "RD_ADDR_LAST" state
--    of ADDR_SM_RD_DATA_BUFFER_GEN.
-- ~~~~~~~
--   SK      10/21/2009
-- ^^^^^^^
-- 1. Added "Rd_barrier" signal in the port list to enable the read barrier
--    transfer response from read data path.
-- 2. Renamed locally declared "rd_barrier" signal to "rd_barrier_int".
-- ~~~~~~~
--   SK      10/21/2009
-- ^^^^^^^
-- 1. Updated wready_cmb  <= S_AXI_WVALID; to wready_cmb  <= not(S_AXI_WVALID)
--    in WR_LAST state of "ADDR_SM_NO_RD_DATA_BUFFER_GEN" generate.
-- ~~~~~~~
--  SK      10/26/2009
-- ^^^^^^^
-- 1. Added "Rst_CS" in "RD_LAST" state of "ADDR_SM_RD_DATA_BUFFER_GEN" state
--   machine.
-- ~~~~~~~
--  SK      10/29/2009
-- ^^^^^^^
-- 1. Added "Enable_RdCE" in "RD_LAST" of "ADDR_SM_RD_DATA_BUFFER_GEN" state.
-- 2. Added "Type_of_xfer" in port list and corresponding logic is added.
-- 3. Added "Addr_reload_int" in port list.
-- 4. Added Address counter logic for "Addr_reload_int" in "BURST_ADDR_CNT_P".
-- 5. Code cleaned for internal review.
-- ~~~~~~~
--  SK      11/02/2009
-- ^^^^^^^
-- 1. Added register to "Type_of_xfer" signal ("Type_of_xfer_reg")
-- ~~~~~~~
--  SK      11/05/2009
-- 1. Added "S_AXI_RID" and "S_AXI_BID" reset condition in "REG_P"
--    process.
-- ^^^^^^^
-- ~~~~~~~
--  SK      11/06/2009
-- 1. Removed S_AXI_RID" and "S_AXI_BID" reset condition in "REG_P"
-- ^^^^^^^
-- ~~~~~~~
--  SK      11/09/2009
-- ^^^^^^^
-- 1.Added "S_AXI_RID" and "S_AXI_BID" reset condition in "REG_RID_BID_P"
--   process.
-- ~~~~~~~
--  SK      11/11/09
-- ^^^^^^^
-- 1. Added "bus2ip_wr_req_cmb <= '0';" in "WR_SINGLE" of
--    "ADDR_SM_RD_DATA_BUFFER_GEN" generate statement to generate the write
--    request for singel clock wide pulse.
-- ~~~~~~~
--  SK      11/13/09
-- ^^^^^^^
-- 1. Added (addr_timeout_int='1')in "BURST_DATA_CNT_P" logic block to reduce
--   the burst data counter with resepct to address timeout.
-- ~~~~~~~
--  SK      11/14/09
-- ^^^^^^^
-- 1. Added the signal to differentiate the address and data counters to decide
--   address backing up.
-- 2. Added (Rd_data_sm_ps_IDLE='1') condition in RW_FLAG_P for proper generation
--   of round robin logic.
-- ~~~~~~~
--  SK      11/16/09
-- ^^^^^^^
-- 1. Added (addr_timeout_int='1') in "BURST_DATA_CNT_P" to advance data counter
--    for address time out.
-- ~~~~~~~
--  SK      11/16/09
-- ^^^^^^^
-- 1. Removed logic for BARRIER suppport from the core.
-- ~~~~~~~
--  SK      11/19/09
-- ^^^^^^^
-- 1. Removed "addr_timeout_int" logic from "BRESP_1_P" process.
--    Now address time out conditions will be considered as the OKAY response
--    conditions.
-- ~~~~~~~
--  SK      11/20/09
-- ^^^^^^^
-- 1. Removed "bvalid_cmb" from IDLE state.
-- ~~~~~~~
--  SK      11/23/09
-- ^^^^^^^
-- 1. Updated logic for Bus2IP_BurstLength signal.
--    this signal will have values of either read length or write length
--    in FIFO = 32 case. In FIFO = 0 case, only write will have the burst
--    information, read will indicate burst length as '0'.
-- 2. Shifted Bus2IP_Burst     <= bus2ip_burst_cmb; in "ADDR_CTRL_REG_P" from
--    "REG_P" process. This is just to nullify the unwanted assertion of signal
-- 3. Removed "last_addr" from sensitivity list of
--    "ADDR_SM_NO_RD_DATA_BUFFER_GEN". This signal was not read in the State
--    machine.
-- ~~~~~~~
--  SK      11/25/09
-- ^^^^^^^
-- 1. Updated logic for Type_of_xfer signal.
-- 2. "Enable_CS" is updated in IDLE state for 'ADDR_SM_RD_DATA_BUFFER_GEN'
--    and 'ADDR_SM_NO_RD_DATA_BUFFER_GEN' instance.
-- 3. Updated "PEND_DACK_CNT_P" condition and added RESET condition for
--    all signals for the process.
-- 4. Reduced "DPTO_LD_VALUE" value by 2 in place of 1 in "DPHASE_TOUT_GEN".
-- ~~~~~~~
--  NSK      11/25/09
-- ^^^^^^^
-- 1. Updated logic for address phase time out, data phase time out condition.
-- 2. Added signal ored_ce_d1.Removed from "DPHASE_TOUT_GEN".
-- 3. Added new process "ORED_CE_P" for registering of ORed_CE.Removed from
--    "DPHASE_TOUT_GEN". Added "pend_dack" in "DPTO_COUNTER_EN_P" elsif
--    condition.
-- 4. Moved "apto_cnt_en" in "APTO_CNT_EN_P" process.
-- 5. "REG_RID_BID_P" splited into two separate processes.
-- ~~~~~~~
--  SK      11/27/09
-- ^^^^^^^
-- 1. Added "ORed_CS" in port list.
-- 2. Updated logic for BURST_ADDR_CNT_P added ORed_CS='1' in counter
--    decrement condition.
-- 3. Updated logic for BURST_DATA_CNT_P added ORed_CE='1' in counter
--    decrement condition.
-- ~~~~~~~
--  SK      11/28/09
-- ^^^^^^^
-- 1. Removed extra "Rst_Rd_CE" from "RD_WAIT_READY". The Rd_CE is already
--    resetted in "RD_SINGLE". This reset was causing the Bus2IP_RdCE to
--    start on IPIC one after one cycle delay.
-- 2. Added "and not addr_timeout_int" condition in PEND_DACK_CNT_P.
-- ~~~~~~~
--  SK      11/29/09
-- ^^^^^^^
-- 1. In "ADDR_TOUT_GEN", added addr_timeout_int condition to load the
--    address counter in "apto_cnt_ld".
-- 2. In "APTO_CNT_EN_P", added "addr_timeout_int" condition to reset the
--    apto_cnt_en.
-- 3. Added "ORed_CS" and removed "ORed_CE" from the elsif condition.
-- 4. Reduced "APTO_LD_VALUE" counter load value by 2 in place of 1. This is
--    due to enableing is registered now. So to compensate the registered
--    enabling the counter value is reduced by 2.
-- 5. In "PEND_DACK_CNT_P" added "ORed_CE and IP2Bus_AddrAck and
--                                                   (not addr_timeout_int)"
--    condition in else condition.
-- ~~~~~~~
--  SK      11/30/09
-- ^^^^^^^
-- 1. Reverted point 3 from above comments (dated 11/29/09).
-- 2. Added logic for addr_timeout_i. Now the address_ack and address_timeout
--    if appeared at the same clock edge, then address ack will be considerered
--    valid address ack.
-- 3. Added reset condition for Bus2IP_Burst in "ADDR_CTRL_REG_P".
-- 4. Added condition "or(ORed_CE='1')" in elsif statement of "APTO_CNT_EN_P".
-- ~~~~~~~
--  SK      12/01/09
-- ^^^^^^^
-- 1. Added (addr_timeout_i='1' and ORed_CE = '0') to reset the address WDT
--    counter in IF statement in APTO_CNT_EN_P.
-- 2. Added (ORed_CE = '1' and addr_timeout_i='1') condition to enable the
--    address timeout counter in APTO_CNT_EN_P.
-- ~~~~~~~
--  SK      12/03/09
-- ^^^^^^^
-- 1. Updated code for SPYGLASS results. Below are the udpates,-
--    a. Removed "if (Rd_data_sm_ps_IDLE='0') then addr_ns <= IDLE;" condition
--       from "IDLE" state of "ADDR_SM_NO_RD_DATA_BUFFER_GEN".
--    b. Replaced -
--       "ored_ce" with "ORed_CE" where-ever it appears.
--       "Bus2ip_BE" with "Bus2IP_BE" where-ever it appears.
--       "Bus2ip_data" with "Bus2IP_Data" where-ever it appears.
--       "ADDR_sm_ps_IDLE" with addr_sm_ps_IDLE" where-ever it appears.
--       "bus2ip_wrreq_reg" with "Bus2IP_WrReq_reg" where-ever it appears.
--    c. Removed "dummy" signal from port list and sensitivity list.
--    d. Replaced "((rw_flag_reg='1') or (S_AXI_ARVALID='0')" condition in IDLE
--       state of "ADDR_SM_RD_DATA_BUFFER_GEN" and
--       "ADDR_SM_NO_RD_DATA_BUFFER_GEN" generates and replaced with only
--       "(rw_flag_reg='1')" condition during the "(S_AXI_AWVALID='1')" check.
--    e. Removed unused signal id_reg from signal declaration & ADDR_CTRL_REG_P
--    f. Removed Barrier related code as the Interconnect is not supporting
--       barrier transactions till EDK release 12.3.
--    g. Added byte enable logic for READ when C_ALIGN_BE_RDADDR  = 1 condition
--       in "ALIGN_BYTE_ENABLE_WITH_ADDR_GEN" and
--       in "UNALIGN_BYTE_ENABLE_WITH_ADDR_GEN".
--    h. Registered the bus2ip_burstlength signal and updated the logic when
--       FIFO = 0 and FIFO /= 0.
-- ~~~~~~~
--  SK      12/06/09
-- ^^^^^^^
--  1. Replaced logic for "second_last_addr" and "last_addr" with simple
--     reduce logic.
--  2. Replaced logic for "second_last_data" and "last_data_cmb" with simple
--     reduce logic.
--  3. Added signal wr_transaction and logic for WRITE operation from AXI.
--  4. Added "wr_transaction" in sensitivity list of ADDR_SM_RD_DATA_BUFFER_GEN
--     and ADDR_SM_NO_RD_DATA_BUFFER_GEN statements.
--  5. Replaced logic "elsif ((S_AXI_AWVALID='1') and" for write transfer in
--     IDLE state for the ADDR_SM_RD_DATA_BUFFER_GEN &
--     ADDR_SM_NO_RD_DATA_BUFFER_GEN generate statements.
--  6. Commented logic for "Derived_Len_int" in reset condition to optimize in
--     32 and 64 bit mode.
-- ~~~~~~~
--  SK      12/07/09
-- ^^^^^^^
--  1. Restored the logic in IDLE state for checkign the write transactions.
--     added (S_AXI_ARVALID='0') on ORed condition with rw_flag_reg for write
--     transactions.
-- ~~~~~~~
--  SK      12/07/09
-- ^^^^^^^
--  1. Updated condition for Rst_Rd_CE in "RD_ADDR_LAST" state of
--     "ADDR_SM_RD_DATA_BUFFER_GEN".
--  2. Updated C_S_AXI_ID_WIDTH range from 0 to 16.
-- ~~~~~~~
--  SK      12/15/09
-- ^^^^^^^
--  1. Updated "DPTO_LD_VALUE" from "TIMEOUT_CNT_VALUE-2,COUNTER_WIDTH" to
--     "TIMEOUT_CNT_VALUE-3,COUNTER_WIDTH".
--  2. Updated "RD_BURST" state for Enable_RdCE condition in
--     "ADDR_SM_RD_DATA_BUFFER_GEN".
-- ~~~~~~~
--  SK      12/17/09
-- ^^^^^^^
--  1. Updated the RD_ADDR_LAST condition in "ADDR_SM_RD_DATA_BUFFER_GEN" for
--     "Rst_Rd_CE" logic generation.
--  2. Added AND condition of last_addr=0 in elsif state of "BURST_ADDR_CNT_P".
-- ~~~~~~~
--  SK      12/21/09
-- ^^^^^^^
--  1. Removed "Bus2IP_Burst" logic from the state machine and replace in
--     separate logic instance based upon the FIFO availability.
--  2. Added "last_len_cmb" in signal declataion.
--  3. Added "BUS2IP_BURST_FIFO_0_GEN" generate statement for generating the
--     bus2ip_burst signal only for WRITE transaction. For read transactions
--     bus2ip_burst will be '0' as every transaction is single transaction.
--  4. Added "BUS2IP_BURST_FIFO_32_GEN" generate statement for generating the
--     bus2ip_burst signal for READ & WRITE transaction.
--  5. Updated address counter reload condition in "BURST_ADDR_CNT_P".
--     When address counter is reloaded, the data counter is loaded in address
--     counter.
-- ~~~~~~~
--  SK      12/21/09
-- ^^^^^^^
--  1. Added rnw_cmb = '0' in "RD_LAST" state while transitioning to IDLE in
--     "ADDR_SM_RD_DATA_BUFFER_GEN" generate statement.
-- ~~~~~~~
--  SK      01/01/10
-- ^^^^^^^
-- 1. Updated "proc_common_pkg.log2" with "proc_common_pkg.clog2".
--    Updated the instances of log2 to clog2.
-- ~~~~~~~
--  SK      01/01/10
-- ^^^^^^^
-- 1. Added "WR_DATA_WAIT" state in state declaration.
-- 2. Added "wr_addr_transaction" and "wr_single_reg" in signal declaration.
-- 3. Added logic for "wr_addr_transaction".
-- 4. Added "wr_addr_transaction" and "wr_single_reg" in sensitivity list for
--    FIFO=0 and FIFO/=0 state machines.
-- 4. Added "WR_DATA_WAIT" state in both state machines and added corresponding
--    signals like wready_cmb,bus2ip_wr_req_cmb,Enable_WrCE logic.
-- 5. Added registered signal "wr_single_reg" in "ADDR_CTRL_REG_P" to register
--    the write single information.
-- 6. Removed unused signal "S_AXI_AWLOCK" from port list.
-- ~~~~~~~
--  SK      05/11/10
-- ^^^^^^^
-- 1. added max_fanout attribute for IP2Bus_WrAck, IP2Bus_RdAck, S_AXI_ARVALID,
--    S_AXI_AWVALID, data_timeout_int, addr_timeout_int.
-- 2. Updated BRESP_1_P process to add the address_timeout_int condition while
--    generating the SLVERR i.e. BRESP(1) = 1 condition.
-- ~~~~~~~
--  SK      07/07/10
-- ^^^^^^^
-- 1. changed priority in BUS2IP_BURST_FIFO_0_REG_P
-- 2. Updated ADDR_SM_RD_DATA_BUFFER_GEN with below states
--    a. RD_BURST - added No_addr_space_c condition for set/reset the rdce
--    b. RD_ADDR_LAST - removed last_addr from condition check.
--                    - added No_addr_space_c in set/reset rdce conditions
-- 3. Added separate signals in BUS2IP_BURST_FIFO_0_GEN for len_cmb_int and
--    last_len_cmb_int to avoid the signal over-riding.
--    
-- ~~~~~~~
--  SK      07/29/10
-- ^^^^^^^
-- 1. Code clean for final publish.
-- ~~~~~~~
-----------------------------------------------------------------------------
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

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.clog2;
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.family_support.all;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.or_gate128;

-------------------------------------------------------------------------------
-- Definition of Generics:
--  -- System Parameter
--       C_FAMILY                    -- Target FPGA family used for WDT counter
--  -- Slave Parameter
--       C_RDATA_FIFO_DEPTH          -- Selects the read data FIFO depth
--       C_INCLUDE_TIMEOUT_CNT  -- Enable timout counter : 0 or 1
--       C_TIMEOUT_CNTR_VAL    -- Timeout count value ; 0 or 8 or 16
--       C_ALIGN_BE_RDADDR     -- Align the byte enables with respect to read
--                             -- address, range 0 to 1.
--                             -- default = 0 - no alignment, all BE - '1'
--                             -- if '1', then BE's are enabled with respect to
--                             -- current address and size of AXI transfer.
--  -- AXI Parameter
--       C_AXI_ADDR_WIDTH            -- AXI address bus width
--       C_AXI_DATA_WIDTH            -- AXI data bus width
--       C_AXI_ID_WIDTH              -- AXI Identification tag width
--  -- Other Parameters
--       C_MAX_BURST_LENGTH          -- Max. possible burst length
-------------------------------------------------------------------------------
-- Definition of Ports:
--==========================
-- AXI Global System Signals
--==========================
-- S_AXI_ACLK      -- AXI Global clock signal.
--                 -- All signals are sampled on the rising edge of the global
--                 -- clock.
-- S_AXI_ARESETN   -- Global reset signal. This signal is active low.

--======================================
-- AXI Write Address Channel Signals input from AXI Prefix "S_" with each
-- signal indicate that these are slave signal.
--======================================
-- S_AXI_AWID      -- Write address ID.
--                 -- This signal is the identification tag for the write
--                 -- address group of signals.
-- S_AXI_AWADDR    -- Write address.
--                 -- The write address bus gives the address of the first
--                 -- transfer in a write burst transaction. The associated
--                 -- control signals are used to determine the addresses of
--                 -- remaining transfers in the burst.
-- S_AXI_AWLEN     -- Burst length.
--                 -- The burst length gives the exact number of transfers in a
--                 -- burst. This information determines the number of data
--                 -- transfers associated with the address.
-- S_AXI_AWSIZE    -- Burst size.
--                 -- This signal indicates the size of "each transfer" in the
--                 -- "burst". Byte lane strobes indicate exactly which byte
--                 -- lanes to update.
-- S_AXI_AWBURST   -- Burst type.
--                 -- The burst type, coupled with the size information,
--                 -- details how the address for each transfer within the
--                 -- burst is calculated.
-- S_AXI_AWCACHE   -- Cache type.
--                 -- This signal indicates the bufferable, cacheable,
--                 -- write-through, write-back,and allocate attributes of the
--                 -- transaction.
-- S_AXI_AWPROT    -- Protection type.
--                 -- This signal indicates the normal, privileged, or secure
--                 -- protection level of the transaction and whether the
--                 -- transaction is a data access or an instruction access.
-- S_AXI_AWVALID   -- Write address valid.
--                 -- This signal indicates that valid write address & control
--                 -- information are available:
--                 -- 1 = address and control information available
--                 -- 0 = address and control information not available.
--                 -- The address and control information remain stable until
--                 -- the address acknowledge signal, AWREADY, goes HIGH.
-- S_AXI_AWREADY   -- Write address ready.
--                 -- This signal indicates that the slave is ready to accept
--                 -- an address and associated control signals:
--                 -- 1 = slave ready
--                 -- 0 = slave not ready
--===========================
-- Write data channel signals
--===========================
-- S_AXI_WDATA     -- Write data.
--                 -- The write data bus can be 8, 16, 32, 64, 128, 256, 512,
--                 -- or 1024 bits wide.
-- S_AXI_WSTRB     -- Write strobes.
--                 -- This signal indicates which byte lanes to update in
--                 -- memory. There is one write strobe for each eight bits
--                 -- of the write data bus. Therefore, WSTRB[n] corresponds
--                 -- to WDATA[(8 × n) + 7:(8 × n)]

-- S_AXI_WVALID    -- Write valid.
--                 -- This signal indicates that valid write data and strobes
--                 -- are available:
--                 -- 1 = write data and strobes available
--                 -- 0 = write data and strobes not available : in  std_logic;
-- S_AXI_WREADY    -- Write ready.
--                 -- This signal indicates that the slave can accept the write
--                 -- data:
--                 -- 1 = slave ready
--                 -- 0 = slave not ready.
--==================================
-- Write response channel signals
--==================================
-- output to the AXI
--=============================
-- S_AXI_BID       -- Response ID.
--                 -- The identification tag of the write response. The BID
--                 -- value must match the AWID value of the write transaction
--                 -- to which the slave is responding.
-- S_AXI_BRESP     -- Write response.
--                 -- This signal indicates the status of the write transaction.
--                 -- The allowable responses are OKAY, EXOKAY, SLVERR,
--                 -- and DECERR.
-- S_AXI_BVALID    -- Write response valid.
--                 -- This signal indicates that a valid write response is
--                 -- available:
--                 -- 1 = write response available
--                 -- 0 = write response not available.
-- Input from AXI
--=============================
-- S_AXI_BREADY    -- Response ready.
--                 -- This signal indicates that the master can accept the
--                 -- response information.
--                 -- 1 = master ready
--                 -- 0 = master not ready.
--=============================
-- Read address channel signals
--=============================
-- Input from AXI
--=============================
-- S_AXI_ARID      -- Read address ID.
--                 -- This signal is the identification tag for the read
--                 -- address group of signals.
-- S_AXI_ARADDR    -- Read address.
--                 -- The read address bus gives the initial address of a read
--                 -- burst transaction.Only the start address of the burst is
--                 -- provided and the control signals that are issued
--                 -- alongside the address detail how the address is
--                 -- calculated for the remaining transfers in
--                 -- the burst.
-- S_AXI_ARLEN     -- Burst length.
--                 -- The burst length gives the exact number of transfers in a
--                 -- burst. This information determines the number of data
--                 -- transfers associated with the address.
-- S_AXI_ARSIZE    -- Burst size.
--                 -- This signal indicates the size of each transfer in the
--                 -- burst.
-- S_AXI_ARBURST   -- Burst type.
--                 -- The burst type, coupled with the size information,details
--                 -- how the address for each transfer within the burst is
--                 -- calculated.
-- S_AXI_ARCACHE   -- Cache type.
--                 -- This signal provides additional information about the
--                 -- cacheable characteristics of the transfer.
-- S_AXI_ARPROT    -- Protection type. This signal provides protection unit
--                 -- information for the transaction.
-- S_AXI_ARVALID   -- Read address valid.
--                 -- This signal indicates, when HIGH, that the read address
--                 -- and control information is valid and will remain stable
--                 -- until the address acknowledge signal,ARREADY, is high.
--                 -- 1 = address and control information valid
--                 -- 0 = address and control information not valid.
-- S_AXI_ARREADY   -- Read address ready.
--                 -- This signal indicates that the slave is ready to accept
--                 -- an address and associated control signals:
--                 -- 1 = slave ready
--                 -- 0 = slave not ready.
--==============================
--Read data channel signals
--==============================
--Output to AXI
--==============================
-- S_AXI_RID       -- Read ID tag.
--                 -- This signal is the ID tag of the read data group of
--                 -- signals. The RID value is generated by the slave and must
--                 -- match the ARID value of the read transaction to which it
--                 -- is responding.
-- S_AXI_RDATA     -- Read data.
--                 -- The read data bus can be 8, 16, 32, 64, 128,
--                 -- 256, 512, or 1024 bits wide.
-- S_AXI_RRESP     -- Read response.
--                 -- This signal indicates the status of the read transfer.
--                 -- The allowable responses are OKAY, EXOKAY, SLVERR,
--                 -- and DECERR.
-- S_AXI_RLAST_int -- Read last. This signal indicates the last transfer in a
--                 -- read burst.
-- S_AXI_RVALID    -- Read valid.
--                 -- This signal indicates that the required read data is
--                 -- vailable and the read transfer can complete:
--                 -- 1 = read data available
--                 -- 0 = read data not available.
--==============================
--Input from AXI
--==============================
-- S_AXI_RREADY    -- Read ready.
--                 -- This signal indicates that the master can accept the read
--                 -- data and response information:
--                 -- 1= master ready
--                 -- 0 = master not ready.
--==========================
-- IPIC Signals
--==========================

-- IP2Bus_WrAck          -- Active high Write Data qualifier from the IP
-- IP2Bus_RdAck          -- Active high Read Data qualifier from the IP
-- IP2Bus_AddrAck        -- Active high Address qualifier from the IP
-- IP2Bus_Error          -- Error signal from the IP

-- Bus2IP_Data           -- Write data bus to the User IP
-- Bus2IP_RNW            -- Read or write indicator for the transaction
-- Bus2IP_BE             -- Byte enables for the data bus
-- Bus2IP_Burst          -- Burst information to the IP
-- Bus2IP_BurstLength    -- Burst length (beats) information to the IP
-- Bus2IP_WrReq          -- Write Request signal to the IP
-- Bus2IP_RdReq          -- Read Request signal to the IP

-- Data_Timeout          -- Data timeout counter expired information
-- Rd_data_sm_ps_IDLE    -- Read data state machine is in IDLE state
-- RdFIFO_Space_two      -- Read data FIFO space of two
-- Addr_int              -- Address selected from AXI read/write
-- ORed_CE               -- ORed all CEs
-- ORed_CS               -- ORed all CSs
-- Addr_reload_int       -- Reload the address counter
-- Addr_int              -- AXI address for internal usage
-- Derived_Len           -- New burst length converted to data width
-- Derived_Burst         -- New burst for internal address calculation
-- Derived_Size          -- New burst size for internal address calculation
-- Enable_CS             -- Enable Chip Select
-- Enable_WrCE           -- Enable Write Chip Enable
-- Enable_RdCE           -- Enable Read Chip Enable
-- Rst_CS                -- Disable Chip Select
-- Rst_Wr_CE             -- Disable Write Chip Enable
-- Rst_Rd_CE             -- Disable Read Chip Enable
-- RNW                   -- combinational signal RNW
-- Addr_Timeout          -- Address timeout counter expired
-- Store_addr_info       -- Store new address from AXI
-- rd_single_cmb         -- Current xfer is single read
-- wr_cycle_cmb          -- Current xfer is write
-- axi_cycle_cmb         -- Current xfer is read
-- Last_data             -- Last data of the xfer
-- ADDR_sm_ps_IDLE       -- Address state machine is in idle state
-- Next_addr_strobe      -- Generate next address strobe
-- Type_of_xfer          -- TO IPIC 0-Fixed Address transfer
--                       -- To IPIC 1-INCR/WRAP Address transfer
-- Take_addr_back_up     -- if the difference between the address and data ack
--                       -- then take address back up
-- LAST_data_from_FIFO   -- last data is present in FIFO.
------------------------
-- Entity Section
------------------------
entity control_state_machine is
    generic (
---- System Parameters
     C_FAMILY               : string                 := "virtex6";
     C_RDATA_FIFO_DEPTH     : integer                := 0; -- allowed 0 or 32
     C_INCLUDE_TIMEOUT_CNT  : integer range 0 to 1   := 1;
     C_TIMEOUT_CNTR_VAL     : integer                := 8; -- allowed 8 or 16
     C_ALIGN_BE_RDADDR      : integer range 0 to 1   := 0;
---- AXI Parameters
     C_S_AXI_ADDR_WIDTH     : integer range 32 to 32 := 32;
     C_S_AXI_DATA_WIDTH     : integer range 32 to 64 := 32;
     C_S_AXI_ID_WIDTH       : integer range 1 to 16   := 4;
---- Other Parameters
     C_MAX_BURST_LENGTH     : integer
     );
    port (
--  -- AXI Slave signals ------------------------------------------------------
--   -- AXI Global System Signals
       S_AXI_ACLK    : in  std_logic;
       S_AXI_ARESETN : in  std_logic;
--   -- AXI Write Address Channel Signals
       S_AXI_AWID    : in  std_logic_vector (C_S_AXI_ID_WIDTH-1 downto 0);
       S_AXI_AWADDR  : in  std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
       S_AXI_AWLEN   : in  std_logic_vector (7 downto 0);
       S_AXI_AWSIZE  : in  std_logic_vector (2 downto 0);
       S_AXI_AWBURST : in  std_logic_vector (1 downto 0);

       S_AXI_AWVALID : in  std_logic;
       S_AXI_AWREADY : out std_logic;
--   -- AXI Write Channel Signals
       S_AXI_WDATA   : in  std_logic_vector (C_S_AXI_DATA_WIDTH-1 downto 0);
       S_AXI_WSTRB   : in  std_logic_vector
                               (((C_S_AXI_DATA_WIDTH/8)-1) downto 0);

       S_AXI_WVALID  : in  std_logic;
       S_AXI_WREADY  : out std_logic;
--   -- AXI Write Response Channel Signals
       S_AXI_BID     : out std_logic_vector (C_S_AXI_ID_WIDTH-1 downto 0);
       S_AXI_BRESP   : out std_logic_vector (1 downto 0);
       S_AXI_BVALID  : out std_logic;
       S_AXI_BREADY  : in  std_logic;
--   -- AXI Read Address Channel Signals
       S_AXI_ARID    : in  std_logic_vector (C_S_AXI_ID_WIDTH-1 downto 0);
       S_AXI_ARADDR  : in  std_logic_vector (C_S_AXI_ADDR_WIDTH-1 downto 0);
       S_AXI_ARLEN   : in  std_logic_vector (7 downto 0);
       S_AXI_ARSIZE  : in  std_logic_vector (2 downto 0);
       S_AXI_ARBURST : in  std_logic_vector (1 downto 0);

       S_AXI_ARVALID : in  std_logic;
       S_AXI_ARREADY : out std_logic;
--   -- AXI Read Data Channel Signals
       S_AXI_RREADY  : in  std_logic;
       S_AXI_RLAST   : in std_logic;
       S_AXI_RID     : out std_logic_vector (C_S_AXI_ID_WIDTH-1 downto 0);
      -- Controls to the IP/IPIF modules

       IP2Bus_WrAck  : in  std_logic;
       IP2Bus_RdAck  : in  std_logic;
       IP2Bus_AddrAck: in  std_logic;
       IP2Bus_Error  : in  std_logic;

       Bus2IP_Data   : out std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
       Bus2IP_RNW    : out std_logic;
       Bus2IP_BE     : out std_logic_vector(((C_S_AXI_DATA_WIDTH/8)-1)downto 0);
       Bus2IP_Burst  : out std_logic;
       Bus2IP_BurstLength : out std_logic_vector
                                    (C_MAX_BURST_LENGTH-1 downto 0);
       Bus2IP_WrReq  : out std_logic;
       Bus2IP_RdReq  : out std_logic;
       Data_Timeout  : out std_logic;

       Rd_data_sm_ps_IDLE : in std_logic;
       RdFIFO_Space_two   : in  std_logic;
       ORed_CE            : in  std_logic;
       ORed_CS            : in  std_logic;
              Wrce_ored            : in  std_logic;
       -- Addr_reload_int    : in std_logic;

       Addr_int        : out std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);
       Derived_Len     : out std_logic_vector(3 downto 0);
       Derived_Burst   : out std_logic_vector(1 downto 0);
       Derived_Size    : out std_logic_vector(1 downto 0);

       Enable_CS       : out std_logic;
       Enable_WrCE     : out std_logic;
       Enable_RdCE     : out std_logic;
       Rst_CS          : out std_logic;
       Rst_Wr_CE       : out std_logic;
       Rst_Rd_CE       : out std_logic;
       RNW             : out std_logic;

       Addr_Timeout    : out std_logic;

       Store_addr_info : out std_logic;
       rd_single_reg   : out std_logic;
       wr_cycle_cmb    : out std_logic;
       axi_cycle_cmb   : out std_logic;
       Last_data       : out std_logic;

       ADDR_sm_ps_IDLE  : out std_logic;
       Next_addr_strobe : out std_logic;

       Type_of_xfer      : out std_logic;

       LAST_data_from_FIFO : in std_logic;


       No_addr_space      : in  std_logic;
       
       last_data_for_rd_tr : in std_logic;
      
       stop_addr_incr    : out std_logic;

       load_addr_fifo    : out std_logic;

       Rdce_ored         : in std_logic
       );


end entity control_state_machine;
-------------------------------------------------------------------------------
------------------------
-- Architecture Section
------------------------
architecture imp of control_state_machine is
-------------------------------------------------------------------------------
-- Constant Declarations
-----------------------------
-- Reset Active State
constant ACTIVE_LOW_RESET : std_logic := '0';
--------------
-- Type Declaration
-----------------------------
    type STATE_TYPE is (
                         IDLE,
                         RD_SINGLE,
                         RD_WAIT_RREADY,
                         RD_BURST,
                         RD_ADDR_LAST,
                         RD_LAST,
                         WR_SINGLE,
                         WR_DATA_WAIT,
                         WR_BURST,
                         WAIT_WR_DATA,
                         WR_LAST,
                         WR_RESP
                       );

-- Signal Declaration
-----------------------------
    signal addr_ps : STATE_TYPE;
    signal addr_ns : STATE_TYPE;

-- Signal Declaration
-----------------------------
    signal rd_single_cmb_int  : std_logic;
    signal wr_single_cmb  : std_logic;

    signal arready_cmb    : std_logic;
    signal awready_cmb    : std_logic;
    signal wready_cmb     : std_logic;

    signal rnw_cmb        : std_logic;
    signal size_cmb       : std_logic_vector (1 downto 0);
    signal len_cmb        : std_logic_vector (7 downto 0);
    signal rnw_reg        : std_logic;

    signal size_reg       : std_logic_vector (1 downto 0);
    signal burst_reg      : std_logic_vector (1 downto 0);
    signal len_reg        : std_logic_vector (7 downto 0);

    signal store_addr_info_int  : std_logic;
    signal addr_timeout_int : std_logic;

    signal bus2ip_rd_req_cmb  : std_logic;
    signal bus2ip_wr_req_cmb  : std_logic;
    signal second_last_addr   : std_logic;
    signal last_addr          : std_logic;
    signal second_last_data   : std_logic;
    signal last_data_cmb      : std_logic;
    signal last_data_reg      : std_logic;

    signal addr_sm_ns_IDLE         : std_logic;
    signal addr_sm_ns_WAIT_WR_DATA : std_logic;
    signal addr_sm_ps_IDLE_int     : std_logic;
    signal addr_sm_ps_WAIT_WR_DATA : std_logic;
    signal bus2ip_burst_cmb        : std_logic;

    signal burst_addr_cnt          : std_logic_vector(7 downto 0);
    signal burst_data_cnt          : std_logic_vector(7 downto 0);

    signal bvalid_cmb              : std_logic;
    signal bvalid_reg              : std_logic;

    signal ored_out                : std_logic;
    signal ha_addr_sum             : std_logic;
    signal ha_addr_cy              : std_logic;
    signal data_timeout_int        : std_logic;

    signal wready_reg           : std_logic;
    signal awready_reg          : std_logic;
    signal wr_cycle_cmb_int     : std_logic;
    signal wr_cycle_reg         : std_logic;
    signal axi_cycle_cmb_int    : std_logic;
    signal axi_cycle_reg        : std_logic;
    signal Derived_Len_int      : std_logic_vector (3 downto 0);

    signal axi_last_rd_data     : std_logic;
    signal rst_axi_last_rd_data : std_logic;
    signal Bus2IP_WrReq_reg     : std_logic;
    signal Bus2IP_RdReq_reg     : std_logic;
    signal rd_single_cmb        : std_logic;
    signal rw_flag_reg          : std_logic;

    signal Type_of_xfer_cmb     : std_logic;
    signal Type_of_xfer_reg     : std_logic;
    signal ored_ce_d1           : std_logic;

    signal wr_transaction       : std_logic;
    signal last_len_cmb         : std_logic;
    signal wr_addr_transaction  : std_logic;
    signal wr_single_reg        : std_logic;

    signal rnw_cmb_dup          : std_logic;
    signal rnw_cmb_reg_dup      : std_logic;

    signal Rst_Rd_CE_int        : std_logic;
    signal Rst_Rd_CE_int_d1     : std_logic;

    signal active_high_rst      : std_logic;
    
    signal rnw_cmb_int          : std_logic;

    attribute equivalent_register_removal: string;
    attribute equivalent_register_removal of rnw_cmb_dup : signal is "no";

    attribute max_fanout                          : string;
    attribute max_fanout   of rnw_cmb_int         : signal is "30";
    attribute max_fanout   of wready_cmb          : signal is "30";
    attribute max_fanout   of axi_cycle_cmb_int   : signal is "30";
    
    attribute max_fanout   of IP2Bus_WrAck        : signal is "30";
    attribute max_fanout   of IP2Bus_RdAck        : signal is "30";
    attribute max_fanout   of IP2Bus_AddrAck      : signal is "30";

    attribute max_fanout   of S_AXI_ARVALID       : signal is "30";
    attribute max_fanout   of S_AXI_AWVALID       : signal is "30";

    attribute max_fanout   of awready_cmb         : signal is "30";
    attribute max_fanout   of arready_cmb         : signal is "30";

    attribute max_fanout   of data_timeout_int    : signal is "30";
    attribute max_fanout   of addr_timeout_int    : signal is "30";
    attribute max_fanout   of addr_sm_ns_IDLE     : signal is "30";
    
    signal No_addr_space_c, last_rd_addr_ack_reg : std_logic;
-------------------------------------------------------------------------------
---- Begin architecture logic
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

    Derived_Len   <= Derived_Len_int;
    rd_single_cmb_int <= not(or_reduce(S_AXI_ARLEN));

    wr_single_cmb <= not(or_reduce(S_AXI_AWLEN)) and (not rnw_cmb_dup);
    rd_single_cmb <= rd_single_cmb_int;

    wr_cycle_cmb  <= wr_cycle_cmb_int;
    axi_cycle_cmb <= axi_cycle_cmb_int;

    wr_transaction      <= S_AXI_AWVALID and (S_AXI_WVALID);
    wr_addr_transaction <= S_AXI_AWVALID and (not S_AXI_WVALID);

    No_addr_space_c <=No_addr_space;
------------------------
-- ADDR_SM_RD_DATA_BUFFER_GEN:logic states when read FIFO is included in design
------------------------      read and write are either single or burst mode.
    ADDR_SM_RD_DATA_BUFFER_GEN : if (C_RDATA_FIFO_DEPTH /= 0) generate
--------------------------
--------------------------
        ADDR_SM_P: process ( addr_ps,
                             Rd_data_sm_ps_IDLE,

                             S_AXI_ARVALID,
                             S_AXI_AWVALID,
                             S_AXI_WVALID,
                             S_AXI_BREADY,
                             S_AXI_RREADY,
                             wr_transaction,

                             wr_addr_transaction,
                             wr_single_reg,

                             wr_cycle_reg,
                             axi_cycle_reg,

                             rd_single_cmb_int,

                             wr_single_cmb,

                             bvalid_reg,

                             RdFIFO_Space_two,
                             data_timeout_int,
                             addr_timeout_int,

                             second_last_addr,
                             second_last_data,
                             last_data_reg,
                             LAST_data_from_FIFO,

                             IP2Bus_AddrAck,
                             IP2Bus_WrAck,
                             IP2Bus_RdAck,

                             Bus2IP_WrReq_reg,
                             rnw_reg,
                             rw_flag_reg,
			     last_addr, 
			     No_addr_space_c,
			     last_data_for_rd_tr,
			     ORed_CS,
			     last_rd_addr_ack_reg
                           ) is
        begin
            arready_cmb        <= '0';
            awready_cmb        <= '0';
            wready_cmb         <= '0';
            bvalid_cmb         <= bvalid_reg;

            rnw_cmb            <= rnw_reg;
            rnw_cmb_dup        <= rnw_reg;--duplicated

            store_addr_info_int<= '0';
            bus2ip_rd_req_cmb  <= '0';
            bus2ip_wr_req_cmb  <= Bus2IP_WrReq_reg;
            Enable_CS          <= '0';
            Enable_WrCE        <= '0';
            Enable_RdCE        <= '0';
            Rst_Wr_CE          <= '0';
            Rst_Rd_CE_int      <= '0';
            Rst_CS             <= '0';
            wr_cycle_cmb_int   <= wr_cycle_reg;

            axi_cycle_cmb_int  <= axi_cycle_reg;
	    load_addr_fifo <= '0';

            case addr_ps is

            when IDLE => if (Rd_data_sm_ps_IDLE='0') then
                             addr_ns <= IDLE;
                             -- below block of logic is for cases where AXI
                             -- generates ARVALID & [either (rw_flag_reg flag is 
                             -- prioritiezed for read) or S_AXI_AWVALID = 0]
                         elsif ((S_AXI_ARVALID='1') and
                                ((rw_flag_reg='0') or (S_AXI_AWVALID='0')))then
                             if (rd_single_cmb_int='1') then
                                 addr_ns <= RD_SINGLE;
                             else
  			         load_addr_fifo <= '1';
                                 addr_ns <= RD_BURST;
                             end if;
                             axi_cycle_cmb_int <= '1';
                             Enable_CS         <= '1';
                             -- below block of logic is for cases where AXI
                             -- generates AWVALID and WVALID simulataneously
                         elsif ((wr_transaction = '1') and
                             ((rw_flag_reg='1')or (S_AXI_ARVALID='0'))) then
                             wr_cycle_cmb_int <= '1';
                             if(wr_single_cmb='1') then
                                 addr_ns <= WR_SINGLE;
                             else
                                 addr_ns <= WR_BURST;
                             end if;
                             axi_cycle_cmb_int <= '1';
                             Enable_CS         <= '1';
                             -- below block of logic is for cases where AXI
                             -- generates AWVALID ahead of WVALID
                         elsif ((wr_addr_transaction = '1') and
                             ((rw_flag_reg='1')or (S_AXI_ARVALID='0'))) then
                             axi_cycle_cmb_int <= '1';
                             addr_ns <= WR_DATA_WAIT;
                         else
                             addr_ns <= IDLE;
                         end if;

                         arready_cmb <= S_AXI_ARVALID         and
                                        Rd_data_sm_ps_IDLE    and
                                        (not(rw_flag_reg) or
                                         not(S_AXI_AWVALID));
                         awready_cmb <= (wr_transaction       or
                                         wr_addr_transaction) and
                                         Rd_data_sm_ps_IDLE   and
                                        (rw_flag_reg      or
                                         (not S_AXI_ARVALID));
                         wready_cmb  <= (wr_transaction   or
                                         wr_addr_transaction) and
                                         Rd_data_sm_ps_IDLE   and
                                         (rw_flag_reg     or
                                          (not S_AXI_ARVALID));
                         rnw_cmb     <=  S_AXI_ARVALID        and
                                         Rd_data_sm_ps_IDLE   and
                                         (not(rw_flag_reg) or
                                          not(S_AXI_AWVALID));
                         -- duplicated logic starts --
                         rnw_cmb_dup <=  S_AXI_ARVALID        and
                                         Rd_data_sm_ps_IDLE   and
                                         (not(rw_flag_reg) or
                                          not(S_AXI_AWVALID));
                         -- duplicated logic ends --
                         store_addr_info_int <= Rd_data_sm_ps_IDLE;

                         bus2ip_rd_req_cmb <= S_AXI_ARVALID          and
                                              Rd_data_sm_ps_IDLE     and
                                              (not(rw_flag_reg) or
                                                not(S_AXI_AWVALID));
                         bus2ip_wr_req_cmb <= S_AXI_AWVALID       and
                                              S_AXI_WVALID        and
                                              Rd_data_sm_ps_IDLE  and
                                              (rw_flag_reg or
                                                (not S_AXI_ARVALID));
                         Enable_WrCE <= S_AXI_AWVALID      and
                                        S_AXI_WVALID       and
                                        Rd_data_sm_ps_IDLE and
                                        (rw_flag_reg or
                                         (not S_AXI_ARVALID));
                         Enable_RdCE <= S_AXI_ARVALID      and
                                        Rd_data_sm_ps_IDLE and
                                        (not(rw_flag_reg) or
                                                not(S_AXI_AWVALID));

            -- WR_DATA_WAIT = when S_AXI_WVALID = 0, no valid data from AXI   
            when WR_DATA_WAIT => if (S_AXI_WVALID='1') then
                                     wr_cycle_cmb_int <= '1';
                                     if(wr_single_reg='1') then
                                        addr_ns <= WR_SINGLE;
                                     else
                                        addr_ns <= WR_BURST;
                                     end if;
                                     Enable_CS  <= '1';
                                 else
                                     addr_ns <= WR_DATA_WAIT;
                                 end if;
                                 wready_cmb        <= '1';
                                 bus2ip_wr_req_cmb <= S_AXI_WVALID       and
                                                      Rd_data_sm_ps_IDLE;
                                 Enable_WrCE       <= S_AXI_WVALID       and
                                                      Rd_data_sm_ps_IDLE;
            -- RD_SINGLE = state logic for single reads. waits for read ack from
            --             slave IP or address or data time out.
            when RD_SINGLE => if ((IP2Bus_RdAck='1') or
                                  (data_timeout_int='1') or
                                  (addr_timeout_int='1')) then
                                  axi_cycle_cmb_int <= '0';
                                  addr_ns <= IDLE;
                              else
                                  addr_ns <= RD_SINGLE;
                              end if;
                              Rst_CS <= IP2Bus_RdAck     or
                                        data_timeout_int or
                                        addr_timeout_int;

                              Rst_Rd_CE_int<= IP2Bus_RdAck     or
                                              data_timeout_int or
                                              addr_timeout_int;

            -- RD_BURST = state logic checks addr_timeout_int or address ack frm
            --            slave else generates signals for read burst.
            when RD_BURST => if ((addr_timeout_int='1') or
                                 (IP2Bus_AddrAck='1')) then
                                 if(second_last_addr='1') then
                                     Rst_Rd_CE_int   <= No_addr_space_c;
				     addr_ns <= RD_ADDR_LAST;
                                 else
   				     Rst_Rd_CE_int   <= No_addr_space_c;
                                     addr_ns <= RD_BURST;
                                 end if;
                             else
  			         Rst_Rd_CE_int   <= No_addr_space_c;
                                 addr_ns <= RD_BURST;
                             end if;

                             bus2ip_rd_req_cmb <= '1';
                             Enable_RdCE <= not No_addr_space_c;

            -- RD_ADDR_LAST = last address for read burst. waits for address
            --                time out or address ack from slave IP.
            when RD_ADDR_LAST => if ((addr_timeout_int = '1') or
                                     (IP2Bus_AddrAck = '1')
				     ) then
                                     if ((last_data_reg='1')
                                         and (IP2Bus_RdAck='1' or
                                              addr_timeout_int='1')
                                         ) then
                                         axi_cycle_cmb_int <= '0';
                                         Rst_CS            <= '1';
                                         addr_ns <= IDLE;
                                     else
                                         addr_ns <= RD_LAST;
                                     end if;
                                 else
                                     addr_ns <= RD_ADDR_LAST;
                                 end if;

                                 bus2ip_rd_req_cmb <= not( ((addr_timeout_int
                                                           or
                                                           IP2Bus_AddrAck)
							   and 
							   last_addr)or last_rd_addr_ack_reg);

                                 Rst_Rd_CE_int <=No_addr_space_c or 
						   (last_data_reg and 	
						    (IP2Bus_RdAck or  
						    addr_timeout_int) 
						   );                 

                                 Enable_RdCE <= not (No_addr_space_c 
						 or                
						 (last_data_reg and
						 addr_timeout_int)
						 );


            -- RD_LAST = last data in read burst.
            when RD_LAST => if ((last_data_reg='1') and
                                ((data_timeout_int = '1') or (IP2Bus_RdAck='1'))
                               ) then
                                axi_cycle_cmb_int <= '0';
                                rnw_cmb           <= '0';
                                rnw_cmb_dup       <= '0';
                                addr_ns <= IDLE;
                            else
                                addr_ns <= RD_LAST;
                            end if;

			    bus2ip_rd_req_cmb <= '0';
                            Rst_Rd_CE_int   <= last_data_reg 
					       and (IP2Bus_RdAck or 
					            data_timeout_int);
                            Enable_RdCE <= not (last_data_reg and 
			                    (IP2Bus_RdAck or data_timeout_int)); 
                            Rst_CS <= last_data_reg and 
			                     (IP2Bus_RdAck or data_timeout_int); 
			   

            -- WR_SINGLE = state logic for write single transfer.
            when WR_SINGLE => if ((addr_timeout_int='1') or
                                  (IP2Bus_WrAck='1') or
                                  (data_timeout_int='1')) then
                                  addr_ns <= WR_RESP;
                              else
                                  addr_ns <= WR_SINGLE;
                              end if;
                              bus2ip_wr_req_cmb <= '0';
                              bvalid_cmb <= (addr_timeout_int or
                                             IP2Bus_WrAck     or
                                             data_timeout_int);
                              Rst_CS     <= (addr_timeout_int or
                                             IP2Bus_WrAck      or
                                             data_timeout_int);
                              Rst_Wr_CE  <= (addr_timeout_int or
                                             IP2Bus_WrAck     or
                                             data_timeout_int);

            -- WR_BURST = state logic for write burst logic.
            when WR_BURST => if ((IP2Bus_WrAck='1')     or
                                 (addr_timeout_int='1') or
                                 (data_timeout_int='1')) then
                                 if (S_AXI_WVALID='0') then
                                     addr_ns <= WAIT_WR_DATA;
                                 elsif (second_last_data='1') then
                                     addr_ns <= WR_LAST;
                                 else
                                     addr_ns <= WR_BURST;
                                 end if;
                             else
                                 addr_ns <= WR_BURST;
                             end if;

                             wready_cmb        <= IP2Bus_WrAck     or
                                                  addr_timeout_int or
                                                  data_timeout_int;
                             bus2ip_wr_req_cmb <= '1';
                             Rst_Wr_CE         <= IP2Bus_WrAck and
                                                  (not S_AXI_WVALID);

            -- WAIT_WR_DATA = during write burst, if no valid data present from
            --                AXI, generate related logic on IPIC and AXI.
            when WAIT_WR_DATA => if (S_AXI_WVALID='0') then
                                     addr_ns <= WAIT_WR_DATA;
                                 elsif (last_data_reg='1') then
                                     addr_ns <= WR_LAST;
                                 else
                                     addr_ns <= WR_BURST;
                                 end if;
				 bus2ip_wr_req_cmb <= '1';--6/22/2010
                                 wready_cmb        <= '1';
                                 Enable_WrCE       <= S_AXI_WVALID;
  
            -- WR_LAST = state logic for last write burst transfer.
            when WR_LAST =>if ((IP2Bus_WrAck='1')     or
                               (addr_timeout_int='1') or
                               (data_timeout_int='1'))then
                                axi_cycle_cmb_int <= '0';
                                addr_ns           <= WR_RESP;
                           else
                                addr_ns           <= WR_LAST;
                           end if;

                           bus2ip_wr_req_cmb <= not (IP2Bus_WrAck     or
                                                     addr_timeout_int or
                                                     data_timeout_int);
                           bvalid_cmb        <= (IP2Bus_WrAck         or
                                                     addr_timeout_int or
                                                     data_timeout_int);
                           Rst_CS            <= (IP2Bus_WrAck         or
                                                     addr_timeout_int or
                                                     data_timeout_int);
                           Rst_Wr_CE         <= (IP2Bus_WrAck         or
                                                     addr_timeout_int or
                                                     data_timeout_int);

            when WR_RESP => if (S_AXI_BREADY='0') then
                                addr_ns <= WR_RESP;
                            else
                                wr_cycle_cmb_int  <= '0';
                                axi_cycle_cmb_int <= '0';
                                addr_ns           <= IDLE;
                            end if;
                            bvalid_cmb <= (not S_AXI_BREADY);
                            Rst_CS     <= '1';
                            Rst_Wr_CE  <= '1';
            --coverage off
            when others  => addr_ns <= IDLE;
            --coverage on
            end case;
        end process ADDR_SM_P;
    --------------------------
    end generate ADDR_SM_RD_DATA_BUFFER_GEN;
    ---------------------------
------------------------
------------------------
-- ADDR_SM_NO_RD_DATA_BUFFER_GEN : state machine to generate logic flow when
--                                 read FIFO is not included in design
------------------------           AXI write burst are burst writes on IPIC,but
--                                 AXI read burst are single reads on IPIC.
    ADDR_SM_NO_RD_DATA_BUFFER_GEN : if (C_RDATA_FIFO_DEPTH = 0) generate
--    --------------
    -----
    begin
    -----
--------------------------
--------------------------
        ADDR_SM_P: process ( addr_ps,
                             Rd_data_sm_ps_IDLE,

                             S_AXI_ARVALID,
                             S_AXI_AWVALID,
                             S_AXI_WVALID,

                             wr_transaction,
                             wr_addr_transaction,
                             wr_single_reg,

                             S_AXI_BREADY,
                             S_AXI_RREADY,
                             S_AXI_RLAST,
                             bvalid_reg,

                             wr_single_cmb,

                             data_timeout_int,
                             addr_timeout_int,

                             second_last_data,
                             last_data_cmb,
                             last_data_reg,

                             IP2Bus_WrAck,
                             IP2Bus_RdAck,

                             rnw_reg,
                             wr_cycle_reg,
                             axi_cycle_reg,

                             Bus2IP_WrReq_reg,
                             rw_flag_reg

                           ) is
        begin
            arready_cmb         <= '0';
            awready_cmb         <= '0';
            wready_cmb          <= '0';
            bvalid_cmb          <= bvalid_reg;

            rnw_cmb             <= rnw_reg;
            rnw_cmb_dup         <= rnw_reg;-- duplicated logic

            store_addr_info_int <= '0';
            bus2ip_rd_req_cmb   <= '0';
            bus2ip_wr_req_cmb   <= Bus2IP_WrReq_reg;

            Enable_CS           <= '0';
            Enable_WrCE         <= '0';
            Enable_RdCE         <= '0';
            Rst_Wr_CE           <= '0';
            Rst_Rd_CE_int       <= '0';
            Rst_CS              <= '0';
            wr_cycle_cmb_int    <= wr_cycle_reg;

            axi_cycle_cmb_int   <= axi_cycle_reg;
            rst_axi_last_rd_data<= '0';

            case addr_ps is

                when IDLE => if ((S_AXI_ARVALID='1') and
                                    ((rw_flag_reg='0') or (S_AXI_AWVALID='0')))
                                    then
                                     addr_ns <= RD_SINGLE;
                                     axi_cycle_cmb_int <= '1';
                                     Enable_CS         <= '1';
                             -- below block of logic is for cases where AXI
                             -- generates AWVALID and WVALID simulataneously
                             elsif ((wr_transaction = '1') and
                                    ((rw_flag_reg='1')or (S_AXI_ARVALID='0')))then
                                     wr_cycle_cmb_int <= '1';
                                     if(wr_single_cmb='1') then
                                         addr_ns <= WR_SINGLE;
                                     else
                                         addr_ns <= WR_BURST;
                                     end if;
                                     axi_cycle_cmb_int <= '1';
                                     Enable_CS         <= '1';
                             -- below block of logic is for cases where AXI
                             -- generates AWVALID ahead of WVALID
                             elsif ((wr_addr_transaction = '1') and
                               ((rw_flag_reg='1')or (S_AXI_ARVALID='0'))) then
                                axi_cycle_cmb_int <= '1';
                                addr_ns <= WR_DATA_WAIT;

                             else
                                 addr_ns <= IDLE;
                             end if;

                             arready_cmb <= S_AXI_ARVALID      and
                                            Rd_data_sm_ps_IDLE and
                                            (not(rw_flag_reg) or
                                             not(S_AXI_AWVALID));
                             awready_cmb <=(wr_transaction   or
                                             wr_addr_transaction)and
                                            Rd_data_sm_ps_IDLE   and
                                            (rw_flag_reg or
                                             (not S_AXI_ARVALID));
                             wready_cmb  <=(wr_transaction   or
                                             wr_addr_transaction) and
                                             Rd_data_sm_ps_IDLE   and
                                            (rw_flag_reg or
                                             (not S_AXI_ARVALID));

                             rnw_cmb    <=  S_AXI_ARVALID            and
                                            Rd_data_sm_ps_IDLE       and
                                            (not(rw_flag_reg) or
                                             not(S_AXI_AWVALID));
                             -- duplicated logic starts --
                             rnw_cmb_dup<=  S_AXI_ARVALID      and
                                            Rd_data_sm_ps_IDLE and
                                            (not(rw_flag_reg) or
                                             not(S_AXI_AWVALID));
                             -- duplicated logic ends --
                             store_addr_info_int <= Rd_data_sm_ps_IDLE;

                             bus2ip_rd_req_cmb <= S_AXI_ARVALID      and
                                                  Rd_data_sm_ps_IDLE and
                                                  (not(rw_flag_reg) or
                                                    not(S_AXI_AWVALID));

                             bus2ip_wr_req_cmb <= S_AXI_AWVALID       and
                                                  S_AXI_WVALID        and
                                                  Rd_data_sm_ps_IDLE  and
                                                  (rw_flag_reg or
                                                    (not S_AXI_ARVALID));

                             Enable_WrCE <= S_AXI_AWVALID      and
                                            S_AXI_WVALID       and
                                            Rd_data_sm_ps_IDLE and
                                            (rw_flag_reg or
                                             (not S_AXI_ARVALID));
                             Enable_RdCE <= S_AXI_ARVALID      and
                                            Rd_data_sm_ps_IDLE and
                                            (not(rw_flag_reg) or
                                                    not(S_AXI_AWVALID));
            when WR_DATA_WAIT => if (S_AXI_WVALID='1') then
                                     wr_cycle_cmb_int <= '1';
                                     if(wr_single_reg='1') then
                                        addr_ns <= WR_SINGLE;
                                     else
                                        addr_ns <= WR_BURST;
                                     end if;

                                     Enable_CS         <= '1';
                                 else
                                     addr_ns <= WR_DATA_WAIT;
                                 end if;
                                 wready_cmb        <= '1';
                                 bus2ip_wr_req_cmb <= S_AXI_WVALID       and
                                                      Rd_data_sm_ps_IDLE;
                                 Enable_WrCE       <= S_AXI_WVALID       and
                                                      Rd_data_sm_ps_IDLE;

                when RD_SINGLE => if ((IP2Bus_RdAck='1') or
                                      (data_timeout_int='1') or
                                      (addr_timeout_int='1')) then
                                      addr_ns <= RD_WAIT_RREADY;
                                  else
                                      addr_ns <= RD_SINGLE;
                                  end if;

                                  axi_cycle_cmb_int <= not ((IP2Bus_RdAck or
                                                        data_timeout_int  or
                                                        addr_timeout_int) and
                                                        last_data_cmb);
                                  Rst_CS <= (IP2Bus_RdAck     or
                                             data_timeout_int or
                                             addr_timeout_int);

                                  Rst_Rd_CE_int <= (IP2Bus_RdAck     or
                                                    data_timeout_int or
                                                    addr_timeout_int);
                                  Enable_RdCE <= '1';

                when RD_WAIT_RREADY => if (S_AXI_RREADY='0') then
                                           addr_ns <= RD_WAIT_RREADY;
                                       elsif (S_AXI_RLAST='1') then
                                           rnw_cmb <= '0';
                                           rnw_cmb_dup<= '0';
                                           addr_ns <= IDLE;
                                       else
                                           addr_ns  <= RD_SINGLE;
                                       end if;

                                       bus2ip_rd_req_cmb <= (not S_AXI_RLAST)
                                                            and S_AXI_RREADY;
                                       Enable_RdCE <= (not S_AXI_RLAST) and
                                                           S_AXI_RREADY;
                                       Enable_CS <= (not S_AXI_RLAST) and
                                                         S_AXI_RREADY;


                when WR_SINGLE => if ((addr_timeout_int='1') or
                                      (IP2Bus_WrAck='1') or
                                      (data_timeout_int='1')) then
                                      addr_ns <= WR_RESP;
                                  else
                                      addr_ns <= WR_SINGLE;
                                  end if;

                                  bus2ip_wr_req_cmb <= '0';
                                  bvalid_cmb <= addr_timeout_int or
                                                IP2Bus_WrAck     or
                                                data_timeout_int;
                                  Rst_CS     <= addr_timeout_int or
                                                IP2Bus_WrAck     or
                                                data_timeout_int;
                                  Rst_Wr_CE  <= addr_timeout_int or
                                                IP2Bus_WrAck     or
                                                data_timeout_int;

                when WR_BURST => if ((IP2Bus_WrAck='1')     or
                                     (addr_timeout_int='1') or
                                     (data_timeout_int='1'))then
                                     if (S_AXI_WVALID='0') then
                                         addr_ns <= WAIT_WR_DATA;

                                     elsif (second_last_data='1') then
                                         addr_ns <= WR_LAST;

                                     else
                                         addr_ns <= WR_BURST;

                                     end if;
                                 else
                                     addr_ns <= WR_BURST;

                                 end if;

                                 wready_cmb  <= IP2Bus_WrAck     or
                                                addr_timeout_int or
                                                data_timeout_int;
                                 bus2ip_wr_req_cmb <= '1';
                                 Rst_Wr_CE <= (IP2Bus_WrAck     or
                                               addr_timeout_int or
                                               data_timeout_int)and
                                               (not S_AXI_WVALID);


                when WAIT_WR_DATA => if (S_AXI_WVALID='0') then
                                         addr_ns <= WAIT_WR_DATA;
                                     elsif (last_data_reg='1') then
                                         wready_cmb  <= '1';
                                         addr_ns <= WR_LAST;
                                     else
                                         addr_ns <= WR_BURST;
                                     end if;
                                     wready_cmb        <= '1';

                                     Enable_WrCE       <= S_AXI_WVALID;


                when WR_LAST =>if ((IP2Bus_WrAck='1')     or
                                   (addr_timeout_int='1') or
                                   (data_timeout_int='1'))then
                                   axi_cycle_cmb_int <= '0';
				   bus2ip_wr_req_cmb <= '0';
                                   addr_ns           <= WR_RESP;
                               else
                                    bus2ip_wr_req_cmb <= (not IP2Bus_WrAck);

                                    addr_ns     <= WR_LAST;
                                end if;


                                bvalid_cmb        <= IP2Bus_WrAck     or
                                                     addr_timeout_int or
                                                     data_timeout_int;
                                Rst_CS            <= IP2Bus_WrAck     or
                                                     addr_timeout_int or
                                                     data_timeout_int;
                                Rst_Wr_CE         <= IP2Bus_WrAck     or
                                                     addr_timeout_int or
                                                     data_timeout_int;
                                Enable_WrCE       <= S_AXI_WVALID;

                when WR_RESP => if (S_AXI_BREADY='0') then
                                    addr_ns <= WR_RESP;
                                else
                                    wr_cycle_cmb_int  <= '0';
                                    axi_cycle_cmb_int <= '0';
                                    addr_ns           <= IDLE;
                                end if;
                                bvalid_cmb <= not S_AXI_BREADY;
                                Rst_CS     <= '1';
                                Rst_Wr_CE  <= '1';
                --coverage off
                when others  => addr_ns <= IDLE;
                --coverage on
            end case;
        end process ADDR_SM_P;
    --------------------------

    end generate ADDR_SM_NO_RD_DATA_BUFFER_GEN;
    ---------------------------

    -- ORED_CE_P: Register the ORed_CE
    -------------
    ORED_CE_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            ored_ce_d1    <= ORed_CE;
        end if;
    end process ORED_CE_P;

------------------------


    size_cmb <= S_AXI_ARSIZE(1 downto 0) when (rnw_cmb_dup = '1') else
                S_AXI_AWSIZE(1 downto 0);

    addr_sm_ns_IDLE         <= '1' when (addr_ns=IDLE) else '0';
    addr_sm_ns_WAIT_WR_DATA <= '1' when (addr_ns=WAIT_WR_DATA) else '0';


    Type_of_xfer_cmb <= or_reduce(S_AXI_ARBURST) when (rnw_cmb_dup = '1')
                        else
                        or_reduce(S_AXI_AWBURST);
     len_cmb <= S_AXI_ARLEN when (rnw_cmb_dup = '1')
                else
                S_AXI_AWLEN;
--------------------------
 -- ADDR_CTRL_REG_P: stores all qualifier signals
 -------------------
    ADDR_CTRL_REG_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if ((S_AXI_ARESETN = ACTIVE_LOW_RESET) or
                (axi_cycle_cmb_int='0')) then
                size_reg      <= (others => '0');
                burst_reg     <= (others => '0');
                len_reg       <= (others => '0');
                rd_single_reg <= '0';

                wr_single_reg <= '0';

                Type_of_xfer_reg <= '0';--Fixed transfer by default
            elsif(store_addr_info_int='1') then
                len_reg       <= len_cmb;
                size_reg      <= size_cmb;
                rd_single_reg <= rd_single_cmb;
                Type_of_xfer_reg <= Type_of_xfer_cmb;

                wr_single_reg <= wr_single_cmb;

                if(rnw_cmb_dup = '1') then
                    burst_reg <= S_AXI_ARBURST;
                else
                    burst_reg <= S_AXI_AWBURST;
                end if;
            end if;
        end if;
    end process ADDR_CTRL_REG_P;
    -----------------
---------------------------
    -- REG_BID_P,REG_RID_P: Below process makes the RID and BID '0' at POR and
    --                    : generate proper values based upon read/write
    --                      transaction
    -----------------------
    REG_RID_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
           if (S_AXI_ARESETN=ACTIVE_LOW_RESET) then
             S_AXI_RID       <= (others=> '0');
           elsif(arready_cmb='1')then
             S_AXI_RID       <= S_AXI_ARID;
           end if;
        end if;
    end process REG_RID_P;
    ----------------------
    REG_BID_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
           if (S_AXI_ARESETN=ACTIVE_LOW_RESET) then
             S_AXI_BID       <= (others=> '0');
           elsif(awready_cmb='1')then
             S_AXI_BID       <= S_AXI_AWID;
           end if;
        end if;
    end process REG_BID_P;

------------------------
--  -- Register process : register all the signals
------------------------
    REG_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if (S_AXI_ARESETN=ACTIVE_LOW_RESET) then
                addr_ps         <= IDLE;
                addr_sm_ps_IDLE_int <= '1';
                addr_sm_ps_WAIT_WR_DATA <= '0';

                Bus2IP_RdReq_reg<= '0';
                Bus2IP_WrReq_reg<= '0';

                bvalid_reg      <= '0';
                rnw_reg         <= '0';
                wr_cycle_reg    <= '0';
                axi_cycle_reg   <= '0';
                S_AXI_ARREADY   <= '0';
                S_AXI_AWREADY   <= '0';
                Rst_Rd_CE_int_d1  <= '0';
            else
                addr_ps                 <= addr_ns;
                addr_sm_ps_IDLE_int     <= addr_sm_ns_IDLE;
                addr_sm_ps_WAIT_WR_DATA <= addr_sm_ns_WAIT_WR_DATA;

                Bus2IP_RdReq_reg        <= bus2ip_rd_req_cmb;

                Bus2IP_WrReq_reg        <= bus2ip_wr_req_cmb;

                bvalid_reg              <= bvalid_cmb;
                rnw_reg                 <= rnw_cmb;
                wr_cycle_reg            <= wr_cycle_cmb_int;
                axi_cycle_reg           <= axi_cycle_cmb_int;
                S_AXI_ARREADY           <= arready_cmb;
                S_AXI_AWREADY           <= awready_cmb;

                Rst_Rd_CE_int_d1        <= Rst_Rd_CE_int;
            end if;
        end if;
    end process REG_P;


------------------------
-- BURST_ADDR_CNT_P: burst adderss counter
------------------------
    BURST_ADDR_CNT_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if (store_addr_info_int='1') then
                burst_addr_cnt <= len_cmb;
            elsif (
                    ((IP2Bus_AddrAck='1')   or
                     (addr_timeout_int='1')
                    )and
                    ((ORed_CS = '1') and (ORed_CE = '1') and (last_addr='0'))
                   ) then
                burst_addr_cnt <= (burst_addr_cnt - "00000001");
            end if;
        end if;
    end process BURST_ADDR_CNT_P;

    second_last_addr <= not(or_reduce(burst_addr_cnt(7 downto 1))) and
                                                    burst_addr_cnt(0);
    last_addr        <= not(or_reduce(burst_addr_cnt));

    stop_addr_incr <= last_addr;

    LAST_ADDR_ACK_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then    
		if (addr_ps = IDLE) then
			last_rd_addr_ack_reg <= '0';
		elsif((last_addr and IP2Bus_AddrAck)='1') then
			last_rd_addr_ack_reg <= '1';
		end if;
	end if;    
    end process LAST_ADDR_ACK_P;

    ored_out    <= IP2Bus_WrAck or
                   IP2Bus_RdAck or
                   data_timeout_int;
    ha_addr_sum <= ored_out xor addr_timeout_int;
    ha_addr_cy  <= ored_out and addr_timeout_int;

------------------------
-- BURST_DATA_CNT_P: data burst timeout counter. counter will decrement
--                   based upon ack or data/address time out
------------------------
    BURST_DATA_CNT_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if (addr_sm_ns_IDLE='1') then
                burst_data_cnt  <= (others => '0');
            elsif (store_addr_info_int='1')     then
                burst_data_cnt <= len_cmb;
            elsif((
                   (((IP2Bus_WrAck='1')and(Wrce_ored='1'))    or
                   (IP2Bus_RdAck='1')     or
                   (data_timeout_int='1') or
                   (addr_timeout_int='1'))
                   )and
		   ((ORed_CS = '1') and (last_data_cmb='0'))
                  )then
                burst_data_cnt <= burst_data_cnt -
                                  ("000000" & ha_addr_cy & ha_addr_sum);
            end if;
        end if;
    end process BURST_DATA_CNT_P;

    second_last_data <= not(or_reduce(burst_data_cnt(7 downto 1)))
                                             and burst_data_cnt(0);

    last_data_cmb    <= not(or_reduce(burst_data_cnt));


    Rst_Rd_CE <= Rst_Rd_CE_int;
------------------------
-- LAST_DATA_P: last data register information
------------------------
    LAST_DATA_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if ((S_AXI_ARESETN = ACTIVE_LOW_RESET) or
                (axi_cycle_cmb_int='0'))then
                last_data_reg  <= '0';
            elsif ((second_last_data='1') and (ored_out='1')
                                          --and (ORed_CE='1')
					  ) 
					  then
                last_data_reg <= '1';
            else
                last_data_reg <= last_data_cmb;
            end if;
        end if;
    end process LAST_DATA_P;

    Derived_Burst <= burst_reg;
    Derived_Size  <= size_reg;
    Last_data     <= last_data_reg;

--  --------------------------------------------------------------------------
--  Generate burst length for WRAP xfer when C_S_AXI_DATA_WIDTH = 64.
--  --------------------------------------------------------------------------
    LEN_GEN_64 : if ( C_S_AXI_DATA_WIDTH = 64 ) generate
    ------------
    begin
    --  ----------------------------------------------------------------------
    --  Process DERIVED_LEN_P to find the burst length translate from byte,
    --  Half word and word transfer types.
    --  ----------------------------------------------------------------------
    DERIVED_LEN_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if (store_addr_info_int='1') then
                case size_cmb is
                    when "00" =>Derived_Len_int <=("000" & len_cmb(3));
                    when "01" =>Derived_Len_int <=("00" & len_cmb(3 downto 2));
                    when "10" =>Derived_Len_int <=('0' & len_cmb(3 downto 1));
                    when others => Derived_Len_int <= len_cmb(3 downto 0);
                end case;
            end if;
      end if;
    end process DERIVED_LEN_P;
    --------------------------
    end generate LEN_GEN_64;
    ------------------------
--  --------------------------------------------------------------------------
--  Generate burst length for WRAP xfer when C_S_AXI_DATA_WIDTH = 32.
--  --------------------------------------------------------------------------
    LEN_GEN_32 : if ( C_S_AXI_DATA_WIDTH = 32 ) generate
    begin
--  ----------------------------------------------------------------------
--  Process DERIVED_LEN_P to find the burst length translate from byte,
--  Half word and word transfer types.
--  ----------------------------------------------------------------------
    DERIVED_LEN_P: process (S_AXI_ACLK) is
    begin
      if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
        if (store_addr_info_int='1') then
            case size_cmb is
                when "00"   => Derived_Len_int <= ("00" & len_cmb(3 downto 2));
                when "01"   => Derived_Len_int <= ('0' & len_cmb(3 downto 1));
                when others => Derived_Len_int <= len_cmb(3 downto 0);
            end case;
        end if;
      end if;
    end process DERIVED_LEN_P;
    --------------------------
    end generate LEN_GEN_32;
--------------------------

    Addr_int     <= S_AXI_ARADDR when(rnw_cmb_dup = '1')
                    else
                    S_AXI_AWADDR;
    Addr_Timeout <= addr_timeout_int;
    Data_Timeout <= data_timeout_int;
-- ------------------------

------------------------------------------------------------------------------
 -- UNALIGN_BYTE_ENABLE_WITH_ADDR_GEN : generate the un-aligned byte enables
 --                                     during read. the below logic will
 --                                     pass the write strobe as it is, but
 --                                     generates all '1' for read byte enables.
 ----------------------------------
 UNALIGN_BYTE_ENABLE_WITH_ADDR_GEN: if (C_ALIGN_BE_RDADDR = 0) generate
 ----------------------------------
 begin
 ------------------------
 -- BUS2IP_BE_P: Register Bus2IP_BE for write strobe during write mode else '1'.
 ------------------------
    BUS2IP_BE_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if ((S_AXI_ARESETN=ACTIVE_LOW_RESET)) then
                Bus2ip_BE   <= (others => '0');
            elsif ((rnw_cmb_dup='0') and (wready_cmb='1')) then
                Bus2ip_BE <= S_AXI_WSTRB;
            elsif (rnw_cmb_dup='1') then
                Bus2ip_BE <= (others => '1');
            end if;
        end if;
    end process BUS2IP_BE_P;
 ----------------------------
 end generate UNALIGN_BYTE_ENABLE_WITH_ADDR_GEN;
------------------------------------------------------------------------------

------------------------------------------------------------------------------
--
-- ALIGN_BYTE_ENABLE_WITH_ADDR_GEN : generate the address aligned byte enables
--                                   during read. the below logic will
--                                   pass the write strobe as it is.
----------------------------------
 ALIGN_BYTE_ENABLE_WITH_ADDR_GEN: if (C_ALIGN_BE_RDADDR = 1) generate
----------------------------------

 signal Bus2ip_BE_reg : std_logic_vector(((C_S_AXI_DATA_WIDTH/8)-1)downto 0);
 signal Bus2ip_BE_cmb : std_logic_vector(((C_S_AXI_DATA_WIDTH/8)-1)downto 0);
 ----------------------

 ------------------------
 begin
 ------------------------
 -- BUS2IP_BE_P:Register Bus2IP_BE for write strobe during write mode else '1'.
 ------------------------
    BUS2IP_BE_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
	    if ((S_AXI_ARESETN=ACTIVE_LOW_RESET)) then 
                Bus2ip_BE_reg   <= (others => '0');
	    elsif ((rnw_cmb_dup='0') and (wready_cmb='1')) then
                Bus2ip_BE_reg <= S_AXI_WSTRB;
            elsif(store_addr_info_int = '1')or (rnw_cmb_dup='1') then
                Bus2ip_BE_reg <= Bus2ip_BE_cmb;
            end if;
        end if;
    end process BUS2IP_BE_P;

    Bus2ip_BE <= Bus2ip_BE_reg;

 ------------------------------------------------------------------------------
 --  ALIGN_BYTE_ENABLE_DWTH_32_GEN: Generate the below logic for 32 bit dwidth
 ----------------------------------
 ALIGN_BYTE_ENABLE_DWTH_32_GEN: if (C_S_AXI_DATA_WIDTH = 32) generate
 ------------------------------
  ----------------------------------------------------------------------------
-- be_generate_32 : This function returns byte_enables for the 32 bit dwidth
----------------------------------------------------------------------------
   function be_generate_32 (addr_bits : std_logic_vector(1 downto 0);
                            size      : std_logic_vector(1 downto 0))
                            return std_logic_vector is

   variable int_bus2ip_be : std_logic_vector(3 downto 0):= (others => '0');
   -----
   begin
   -----

   int_bus2ip_be(0) := size(1) or
                       (
                        ((not addr_bits(1)) and  (not size(1)))
                        and
                         (not addr_bits(0) or size(0))
                       );
   int_bus2ip_be(1) := size(1) or
                       (
                        ((not addr_bits(1)) and  (not size(1)))
                        and
                         (addr_bits(0) or size(0))
                       );
   int_bus2ip_be(2) := size(1) or
                       (
                        (addr_bits(1) and  (not size(1)))
                        and
                        ((not addr_bits(0)) or size(0))
                       );
   int_bus2ip_be(3) := size(1) or
                       (
                        (addr_bits(1) and  (not size(1)))
                        and
                        (addr_bits(0) or size(0))
                        );
   -- coverage_off
   return int_bus2ip_be;
   -- coverage_on
   end function be_generate_32;
 -----------------------------------------------------------------------------
 ------------------------------
 begin
 -------------------------
 -- RD_ADDR_ALIGN_BE_32_P: the below logic generates the byte enables for
 --                        32 bit data width
 -------------------------
 RD_ADDR_ALIGN_BE_32_P: process(store_addr_info_int,
                                size_cmb,
                                S_AXI_ARADDR(1 downto 0),
                                IP2Bus_AddrAck,
                                addr_timeout_int,
                                size_reg,
                                Bus2ip_BE_reg,
				Rdce_ored
                                )is
 begin
    if(store_addr_info_int = '1')then
        Bus2ip_BE_cmb <= be_generate_32(S_AXI_ARADDR(1 downto 0),size_cmb);
    elsif(((IP2Bus_AddrAck = '1') or (addr_timeout_int = '1'))and 
           (Rdce_ored = '1')
	 )then
        case size_reg is
            when "00" => -- byte
                Bus2ip_BE_cmb <= Bus2ip_BE_reg(2 downto 0) & Bus2ip_BE_reg(3);
            when "01" => -- half word
                Bus2ip_BE_cmb <= Bus2ip_BE_reg(1 downto 0) &
                                                    Bus2ip_BE_reg(3 downto 2);
            -- coverage_off
	    when others => Bus2ip_BE_cmb <= "1111";
            -- coverage_on
        end case;
    else
        Bus2ip_BE_cmb <= Bus2ip_BE_reg;
    end if;
 end process RD_ADDR_ALIGN_BE_32_P;
 ----------------------------------
 end generate ALIGN_BYTE_ENABLE_DWTH_32_GEN;
 ------------------------------- ------------
 ------------------------------------------------------------------------------
 --  ALIGN_BYTE_ENABLE_DWTH_64_GEN: Generate the below logic for 32 bit dwidth
 ----------------------------------
 ALIGN_BYTE_ENABLE_DWTH_64_GEN: if (C_S_AXI_DATA_WIDTH = 64) generate
 -------------------------
-- function declaration
  ---------------------------------------------------------------------------
  -- be_generate_64 : To generate the Byte Enable w.r.t size and address
  ---------------------------------------------------------------------------
  function be_generate_64 (addr_bits : std_logic_vector(2 downto 0);
                           size      : std_logic_vector(1 downto 0))
                           return std_logic_vector is

  variable int_bus2ip_be : std_logic_vector(7 downto 0):= (others => '0');
  -----
  begin
  -----
      int_bus2ip_be(0) :=(size(1) and (size(0) or ((not size(0)) and 
                                                   (not addr_bits(2))))) or
                          ((not size(1))      and
                           (not addr_bits(2)) and 
                           (not addr_bits(1)) and 
                           (size(0) or ((not size(0)) and (not addr_bits(0))))
                          );
    
      int_bus2ip_be(1) :=(size(1) and (size(0) or ((not size(0)) and 
                                                   (not addr_bits(2))))) or
    		         ((not size(1))      and
    		         (not addr_bits(2)) and 
    		         (not addr_bits(1)) and 
    		         (size(0) or ((not size(0)) and addr_bits(0)))
                          );
                          
                          
      int_bus2ip_be(2) := (size(1) and (size(0) or ((not size(0)) and 
                                                   (not addr_bits(2))))) or
                           ((not size(1))      and
    	                    (not addr_bits(2)) and 
          		         addr_bits(1)  and 
    		          (size(0) or ((not size(0)) and (not addr_bits(0))))
                          );
                          
      int_bus2ip_be(3) := (size(1) and (size(0) or ((not size(0)) and 
                                                   (not addr_bits(2))))) or
                           ((not size(1))      and
                            (not addr_bits(2)) and
                                 addr_bits(1)  and
                            (size(0) or ((not size(0)) and addr_bits(0)))     
                          );
    
    
    int_bus2ip_be(4) := (size(1) and (size(0) or ((not size(0)) and 
                                                        addr_bits(2)))) or
                         ((not size(1))      and
                          (not addr_bits(1)) and
                               addr_bits(2)  and
                          (size(0) or ((not size(0)) and (not addr_bits(0))))     
                         );
                        
    int_bus2ip_be(5) := (size(1) and (size(0) or ((not size(0)) and 
                                                        addr_bits(2)))) or
  		        ((not size(1))      and
  		        (not addr_bits(1)) and
  		             addr_bits(2)  and
  		        (size(0) or ((not size(0)) and addr_bits(0)))     
                         );
                        
    int_bus2ip_be(6) := (size(1) and (size(0) or ((not size(0)) and 
                                                       addr_bits(2)))) or
  		        ((not size(1))      and
  		            addr_bits(1)  and
  		            addr_bits(2)  and
  		        (size(0) or ((not size(0)) and (not addr_bits(0))))     
                        );
                        
    int_bus2ip_be(7) := (size(1) and (size(0) or ((not size(0)) and 
                                                       addr_bits(2)))) or
  		      	((not size(1))      and
  		      	      addr_bits(1)  and
  		      	      addr_bits(2)  and
  		      	(size(0) or ((not size(0)) and addr_bits(0)))     
                        );
                             

  -- coverage_off
  return int_bus2ip_be;
  -- coverage_on
  end function be_generate_64;
  -----------------------------------------------------------------------------
 -----
 begin
 -----
 -- RD_ADDR_ALIGN_BE_64_P: The below logic generates the byte enables for
 --                        64 bit data width
 -------------------------
 RD_ADDR_ALIGN_BE_64_P: process(store_addr_info_int,
                                size_reg,
                                size_cmb,
                                S_AXI_ARADDR(2 downto 0),
                                Bus2ip_BE_reg,
                                IP2Bus_AddrAck,
                                addr_timeout_int,
				Rdce_ored
                                )is
 begin
    if(store_addr_info_int = '1')then
        Bus2ip_BE_cmb <= be_generate_64(S_AXI_ARADDR(2 downto 0),size_cmb);
    elsif (((IP2Bus_AddrAck = '1') or (addr_timeout_int = '1')) and
            (Rdce_ored = '1')
          )then
        case size_reg is
            when "00" => -- byte
                Bus2ip_BE_cmb <= Bus2ip_BE_reg(6 downto 0) & Bus2ip_BE_reg(7);
            when "01" => -- half word
                Bus2ip_BE_cmb <= Bus2ip_BE_reg(5 downto 0) &
                                                    Bus2ip_BE_reg(7 downto 6);
            when "10" => -- half word
                Bus2ip_BE_cmb <= Bus2ip_BE_reg(3 downto 0) &
                                                    Bus2ip_BE_reg(7 downto 4);
            -- coverage_off
	    when others => Bus2ip_BE_cmb <= "11111111";
	    -- coverage_on
        end case;
    else
            Bus2ip_BE_cmb <= Bus2ip_BE_reg;
    end if;
 end process RD_ADDR_ALIGN_BE_64_P;
 -------------------------------
 end generate ALIGN_BYTE_ENABLE_DWTH_64_GEN;
 ------------------------------------------------------------------------------

 end generate ALIGN_BYTE_ENABLE_WITH_ADDR_GEN;
--
------------------------
-- BUS2IP_DATA_P: Register bus2IP_Data signals
------------------------
    BUS2IP_DATA_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if ((S_AXI_ARESETN=ACTIVE_LOW_RESET)) then -- or
                Bus2IP_data <= (others => '0');
            elsif (
                   ((S_AXI_WVALID='1') and (wready_cmb='1'))
                  ) then
                Bus2IP_data <= S_AXI_WDATA;
            end if;
        end if;
    end process BUS2IP_DATA_P;
-------------------------------------------------------------------------------
    ----------------------------
    -- BURST_LENGTH_FIFO_0_GEN :Generate the combo signal for burst signal when
    ---------------------------- FIFO = 32. This signal is active for WR only
    --                           as RD transactions are converted in singles
    BURST_LENGTH_FIFO_0_GEN : if (C_RDATA_FIFO_DEPTH = 0) generate
    -------------------------
    signal burstlength_reg : std_logic_vector(7 downto 0);
    begin
    ---------------------------------
    --     BUS2IP_BURST_FIFO_0_REG_P: Register the bus2ip_burst signal when
    --------------------------------- FIFO =0. During write, pass AWLEN, else 0
    BUS2IP_BURST_FIFO_0_REG_P: process (S_AXI_ACLK) is
    begin
        if S_AXI_ACLK'event and S_AXI_ACLK='1' then
            if ((S_AXI_ARESETN = ACTIVE_LOW_RESET)) then -- or
                burstlength_reg       <= (others => '0');
	    elsif(store_addr_info_int='1')then
                if (rnw_cmb_dup = '0') then
                    burstlength_reg       <= S_AXI_AWLEN;
                else
                    burstlength_reg       <= (others => '0');
                end if;
	    end if;
        end if;
    end process BUS2IP_BURST_FIFO_0_REG_P;
    --------------------------------------
    Bus2IP_BurstLength <= burstlength_reg;

    end generate BURST_LENGTH_FIFO_0_GEN;
    --------------------------
    ----------------------------
    --BURST_LENGTH_FIFO_32_GEN :Generate the combo signal for burst signal when
    ---------------------------- FIFO = 32. This signal is active for WR only
    --                           as RD transactions are converted in singles
    BURST_LENGTH_FIFO_32_GEN : if (C_RDATA_FIFO_DEPTH /= 0) generate
    -------------------------
    begin

    Bus2IP_BurstLength <= len_reg;

    end generate BURST_LENGTH_FIFO_32_GEN;

    ----------------------------
    --BUS2IP_BURST_FIFO_0_GEN :GEnerate the bus2IP_Burst signal for
    ---------------------------- FIFO = 0 condition.
    BUS2IP_BURST_FIFO_0_GEN : if (C_RDATA_FIFO_DEPTH = 0) generate
    -------------------------
    signal len_cmb_int      :  std_logic_vector (7 downto 0);
    signal last_len_cmb_int : std_logic;
    begin

    len_cmb_int <= S_AXI_AWLEN when (rnw_cmb_dup = '0')
                   else
                   (others => '0');

    last_len_cmb_int    <= (or_reduce(len_cmb_int));

    BUS2IP_BURST_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if ((S_AXI_ARESETN=ACTIVE_LOW_RESET) --or
                ) then
                Bus2IP_Burst <= '0';
            elsif (store_addr_info_int='1') then
                Bus2IP_Burst <= last_len_cmb_int;
            elsif ((last_data_cmb='1') or
                   ((second_last_data='1') and (ored_out='1'))
                  ) then
                Bus2IP_Burst <= '0';
            end if;
        end if;
    end process BUS2IP_BURST_P;

    end generate BUS2IP_BURST_FIFO_0_GEN;

    ----------------------------
    --BUS2IP_BURST_FIFO_32_GEN :Generate the bus2IP_Burst signal for
    ---------------------------- FIFO = 32 condition.
    BUS2IP_BURST_FIFO_32_GEN : if (C_RDATA_FIFO_DEPTH /= 0) generate
    -------------------------
    begin

    last_len_cmb    <= (or_reduce(len_cmb));

    BUS2IP_BURST_P: process (S_AXI_ACLK) is
    begin
        if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
            if ((S_AXI_ARESETN=ACTIVE_LOW_RESET) --or
                ) then
                Bus2IP_Burst <= '0';
            elsif (store_addr_info_int='1') then
                Bus2IP_Burst <= last_len_cmb;
            elsif ((last_data_cmb='1') or
                   ((second_last_data='1') and (ored_out='1'))
                  ) then
                Bus2IP_Burst <= '0';
            end if;
        end if;
    end process BUS2IP_BURST_P;

    end generate BUS2IP_BURST_FIFO_32_GEN;
    --------------------------
-------------------------------------------------------------------------------
----------------------
-- BRESP_1_P: Generation of write response signals
--            the error response will be generated based upon one of the below -
--           1. The IP generates the write ack and error ack together
--           2. The slave doesnt respond either address phase or data phase when
--              write cycle is going on IPIC.
----------------------
    BRESP_1_P: process (S_AXI_ACLK) is
    begin
        if S_AXI_ACLK'event and S_AXI_ACLK='1' then
            
            S_AXI_BRESP(0)  <= '0';                
            
            if (addr_sm_ns_IDLE='1') then
                S_AXI_BRESP(1) <= '0';
            elsif(
                  ((IP2Bus_WrAck='1')  and
                   (IP2Bus_Error='1')
                   )
                  or
                  (((data_timeout_int='1') or (addr_timeout_int='1')) and 
                    (rnw_cmb_dup = '0')
                   )
                 ) then
                S_AXI_BRESP(1) <= '1';
            end if;
        end if;
    end process BRESP_1_P;
-------------------------------------------------------------------------------
-- RW_FLAG_P: round robin algo for read/write AXI transfers. P.O.R. will be READ
------------- as priority, but if READ is absent then WRITE will be assigned
--            the transfer. once write is done, then read-write-read-write...
RW_FLAG_P: process(S_AXI_ACLK)is
begin
     if(S_AXI_ACLK'event and S_AXI_ACLK='1')then
         if (S_AXI_ARESETN=ACTIVE_LOW_RESET)then
                 rw_flag_reg <= '0';
         elsif((addr_sm_ps_IDLE_int='1') and (Rd_data_sm_ps_IDLE='1'))then
                 rw_flag_reg <=
                 (rw_flag_reg and
                   not(S_AXI_AWVALID))or
                                ((not rw_flag_reg)and S_AXI_ARVALID);
         end if;
     end if;
end process RW_FLAG_P;
-------------------------------------------------------------------------------
    ------------------------
    ADDR_TOUT_GEN : if (C_INCLUDE_TIMEOUT_CNT = 1) generate
    --------------
        constant TIMEOUT_CNT_VALUE : integer := C_TIMEOUT_CNTR_VAL;
        constant COUNTER_WIDTH     : integer := clog2(TIMEOUT_CNT_VALUE);
        constant APTO_LD_VALUE   : std_logic_vector((COUNTER_WIDTH-1) downto 0)
                                 := std_logic_vector(to_unsigned
                                     (TIMEOUT_CNT_VALUE-2,COUNTER_WIDTH));
        signal apto_cnt_ld       : std_logic;

        signal apto_cnt_en       : std_logic;
        signal timeout_i         : std_logic;
        signal addr_timeout_i    : std_logic;
    -----
    begin
    -----
        addr_timeout_int <= (not IP2Bus_AddrAck) and addr_timeout_i;
        apto_cnt_ld      <= (not ORed_CE)   or
                            IP2Bus_AddrAck  or
                            addr_timeout_int;

        -- APTO_CNT_EN_P : Registered the apto_cnt_en signal
        ------------------
        APTO_CNT_EN_P: process (S_AXI_ACLK) is
        begin
            if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
               if ((addr_sm_ns_IDLE='1') or
                   (IP2Bus_AddrAck='1')  or
                   (ORed_CE = '0')-- req for singles
                  ) then
                    apto_cnt_en <= '0';
               elsif(((ored_ce_d1 = '0') and (ORed_CE = '1')) or --1 hot encode
                     (ored_out = '1')                         or
                     (ORed_CE = '1' and addr_timeout_i='1') -- req for burst
                    ) then --
                    apto_cnt_en <= '1';
               else
                    apto_cnt_en <= apto_cnt_en;
               end if;
            end if;
        end process APTO_CNT_EN_P;
------------------------
------------------------
        APTO_COUNTER_I : entity proc_common_v3_00_a.counter_f
          generic map(
            C_NUM_BITS    =>  COUNTER_WIDTH,
            C_FAMILY      =>  "nofamily"
              )
          port map(
            Clk           =>  S_AXI_ACLK,      -- in
            Rst           =>  active_high_rst, -- in
            Load_In       =>  APTO_LD_VALUE,   -- in std_logic_vector
            Count_Enable  =>  apto_cnt_en,     -- in
            Count_Load    =>  apto_cnt_ld,     -- in
            Count_Down    =>  '1',             -- in
            Count_Out     =>  open,            -- out std_logic_vector
            Carry_Out     =>  addr_timeout_i   -- out
            );
    --------------------------
    end generate ADDR_TOUT_GEN;
    ---------------------------

    NO_ADDR_TOUT_GEN : if (C_INCLUDE_TIMEOUT_CNT = 0) generate
    --------------
        addr_timeout_int <= '0';

    end generate NO_ADDR_TOUT_GEN;
    ---------------------------
------------------------
-- DPHASE_TOUT_GEN: when data phase counter is enabled
------------------------
    DPHASE_TOUT_GEN : if (C_INCLUDE_TIMEOUT_CNT = 1) generate
    --------------
                                   --user defined cycles
        constant TIMEOUT_CNT_VALUE : integer := C_TIMEOUT_CNTR_VAL;

        constant COUNTER_WIDTH     : Integer := clog2(TIMEOUT_CNT_VALUE);
        constant DPTO_LD_VALUE     : std_logic_vector(COUNTER_WIDTH-1 downto 0)
                                   := std_logic_vector(to_unsigned
                                      (TIMEOUT_CNT_VALUE-3,COUNTER_WIDTH));
        signal pend_dack_cnt       : std_logic_vector (7 downto 0)
                                     := (others => '0');
        signal no_pend_dack        : std_logic;
        signal dpto_cntr_ld_en     : std_logic;
        signal dpto_cnt_en         : std_logic;
        signal timeout_i           : std_logic;
        signal pend_dack           : std_logic;
        signal rst_counter         : std_logic;

    -----
    begin
    -----
------------------------
------------------------
     -- PEND_DACK_CNT_P: check for pending data ack w.r.t. address ack
     -------------------
        PEND_DACK_CNT_P: process (S_AXI_ACLK) is
        begin
            if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
                if(addr_sm_ns_IDLE='1') then
                        pend_dack_cnt <= (others => '0');
                else
                        pend_dack_cnt <= pend_dack_cnt +
                        (ORed_CE and IP2Bus_AddrAck and (not addr_timeout_int))
                                                       - ored_out;
                end if;
            end if;
        end process PEND_DACK_CNT_P;


        pend_dack       <= or_reduce(pend_dack_cnt);
        dpto_cntr_ld_en <= ((not ored_ce_d1) and ORed_CE) or ored_out;
        rst_counter     <= data_timeout_int or active_high_rst;
------------------------
-- DPTO_COUNTER_EN_P: Data phase time out counter enable logic
------------------------
        DPTO_COUNTER_EN_P: process (S_AXI_ACLK) is
        begin
            if (S_AXI_ACLK'event and S_AXI_ACLK='1') then
                if (addr_sm_ns_IDLE='1') then
                    dpto_cnt_en  <= '0';
                elsif (pend_dack='1') then
                    dpto_cnt_en  <= '1';
                elsif ((ored_out='1') or (pend_dack='0')) then
                    dpto_cnt_en  <= '0';
                end if;
            end if;
        end process DPTO_COUNTER_EN_P;

------------------------
-- DPTO_COUNTER_I: Data phase timeout counter
------------------------
        DPTO_COUNTER_I : entity proc_common_v3_00_a.counter_f
          generic map(
            C_NUM_BITS    =>  COUNTER_WIDTH,
            C_FAMILY      =>  "nofamily"
              )
          port map(
            Clk           =>  S_AXI_ACLK,       -- in
            Rst           =>  active_high_rst,  -- in
            Load_In       =>  DPTO_LD_VALUE,    -- in std_logic_vector
            Count_Enable  =>  dpto_cnt_en,      -- in
            Count_Load    =>  dpto_cntr_ld_en,  -- in
            Count_Down    =>  '1',              -- in
            Count_Out     =>  open,             -- out std_logic_vector
            Carry_Out     =>  data_timeout_int  -- out
            );

    --------------------------

    end generate DPHASE_TOUT_GEN;
    --------------------------- -----------------------------

    ----------------------
    -- NO_DPHASE_TOUT_GEN: data timeout counter is not referred when
    --                     timeout counter is not included in the design
    ----------------------
    NO_DPHASE_TOUT_GEN : if (C_INCLUDE_TIMEOUT_CNT = 0) generate
    --------------
        data_timeout_int <= '0';

    end generate NO_DPHASE_TOUT_GEN;
    ---------------------------

 
 S_AXI_BVALID    <= bvalid_reg;
 S_AXI_WREADY    <= wready_cmb;

 Store_addr_info <= store_addr_info_int;

 Bus2IP_RNW      <= rnw_reg;
 Bus2IP_WrReq    <= Bus2IP_WrReq_reg;
 Bus2IP_RdReq    <= Bus2IP_RdReq_reg;

 rnw_cmb_int     <= rnw_cmb;
 RNW             <= rnw_cmb_int;

 ADDR_sm_ps_IDLE <= addr_sm_ps_IDLE_int;
-------------------------------------------------------------
 Next_addr_strobe <= addr_sm_ps_WAIT_WR_DATA and S_AXI_WVALID;
 Type_of_xfer     <= Type_of_xfer_reg;
-------------------------------------------------------------

end imp;
