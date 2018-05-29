-------------------------------------------------------------------------------
--  AXI Slave Burst IP Interface (IPIF) - entity/architecture pair
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
-- ** limitations on product liability.                                  **-- **                                                                    **
-- ** Copyright 2010 Xilinx, Inc.                                        **
-- ** All rights reserved.                                               **
-- **                                                                    **
-- ** This disclaimer and copyright notice must be retained as part      **
-- ** of this file at all times.                                         **
-- ************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        axi_slave_burst.vhd
-- Version:         v1.00.a
-- Description:     This is the top level design file for the axi_slave_burst
--                  function. It provides a standardized slave interface
--                  between the IPIC and the AXI. This version supports
--                  read wirte, read only & write only interfaces. This does
--                  not surrport AxiLite and AxiStream interfaces.
-------------------------------------------------------------------------------
-- Structure:
--              --axi_slave_burst.vhd
--               -- control_state_machine.vhd
--               -- read_data_path.vhd
--               -- address_decode.vhd
--               -- addr_gen.vhd
-------------------------------------------------------------------------------
-- Author:      NSK
--
-- History:
--  SK 07/23/09      -- First version
-- ~~~~~~
-- Created the first version v1.00.a
-- ^^^^^^
-- SK
-- 1. Added wr_cycle_cmb,axi_cycle_cmb signals in the port list of control
--    state machine and read data path, address decode logic
-- 2. Corrected the port mapping for read only interface
-- ~~~~~~~
--   NSK      10/02/2009
-- ^^^^^^^
-- 1. Replaced signal "Last_rd_data" by "last_data"
-- 2. In the instances of "control_state_machine" added signal in port map
--    A. Last_data => last_data
-- 3. In the instances of "read_data_path" added signal in port map
--    A. Replaced signal "Last_rd_data" by "last_data"
-- 4. "rd_single_cmb" is replaced by "rd_single_reg".
-- 5. removed S_AXI_RLAST_int => S_AXI_RLAST_interface and replaced interface
--    with rlast_int
-- ~~~~~~~
-- SK           10/09/09
-- ^^^^^^^
-- 1. Added "Addr_Timeout" port and interface with control state machine
--    to addr_gen logic.
-- ~~~~~~~
--   NSK      10/10/2009
-- ^^^^^^^
-- 1. In all the instances of "read_data_path" replaced port "Last_rd_data"
--    by "Last_rd_data_ipic".
-- ~~~~~~~
-- ~~~~~~~
--   SK      10/12/2009
-- ^^^^^^^
-- 1. Changed "S_AXI_AWCACHE","S_AXI_AWPROT","S_AXI_ARCACHE", "S_AXI_ARPROT"
--    port widths in port list.
-- 2. Removed "S_AXI_WID" from port list
-- ~~~~~~~
-- ~~~~~~~
--   SK      10/14/2009
-- ^^^^^^^
-- 1. During read only access, tied S_AXI_AWREADY, S_AXI_WREADY, S_AXI_BID,
--    S_AXI_BRESP, S_AXI_BVALID to '0' to remove the simulation warnings.
-- 2. "S_AXI_ARREADY","S_AXI_RID", "S_AXI_RLAST" are assigned to '0' for write
--    only transactions.
-- 3. Rd_data_sm_ps_IDLE assignment is corrected in control state machine instance
--    for "SUPPORT_W_ONLY_TRANSACTIONS"
-- ~~~~~~~
--   SK      10/21/2009
-- ^^^^^^^
-- 1. Added Rd_barrier in the interface list signals. Added Rd_barrier interface
--    to control_state_machine.vhd, read_data_path.vhd
-- ~~~~~~~
--   SK      10/29/2009
-- 1. Added IP2Bus_RdAck, Data_Timeout, Rdce_ored signal in "addr_gen.vhd"
--    instance.
-- 2. Added Rdce_ored in "address_decode.vhd" instance.
-- 3. Added new signal "Type_of_xfer" in IPIC port list.
-- ~~~~~~~
--   SK      11/13/2009
-- ^^^^^^^
-- 1. Added "Take_addr_back_up" in port list of control_state_machine  as output
--    as well as in addr_gen.vhd as input port list.
-- ~~~~~~~
--   SK      11/16/2009
-- ^^^^^^^
-- 1. Removed AXI Low power signals, added ,C_RDATA_FIFO_DEPTH in addr_gen.vhd
--    parameter map list.
-- ~~~~~~~
--   SK      11/17/2009
-- ^^^^^^^
-- 1. Removed BARRIER signals from the core.
-- ~~~~~~~
--   SK      11/22/2009
-- ^^^^^^^
-- 1. Added  RNW_reg in addr_gen.vhd port list.
-- ~~~~~~~
--   SK      11/22/2009
-- ^^^^^^^
-- 1. Reverted back the chagnes made on 22 nov for RNW_reg.
-- ~~~~~~~
--   SK      11/24/2009
-- ^^^^^^^
-- 1. Added missing signal "ORed_CE" in address_decode instance port list.
-- ~~~~~~~
--   SK      11/27/2009
-- ^^^^^^^
-- 1. Added "ORed_CS" in port list in control_state_machine.vhd file.
-- 2. Added Bus2IP_CS_i vectored signal in the signal declaration list.
-- 3. Added ORed_CS <= or_reduce(Bus2IP_CS_i); logic in each instance.
-- ~~~~~~~
--   SK      11/27/2009
-- ^^^^^^^
-- 1. Removed "C_S_AXI_MIN_SIZE" unused parameter.
-- ~~~~~~~
--   SK      12/09/09
-- ^^^^^^^
-- 1. Updated C_S_AXI_ID_WIDTH parameter range from fixed 4 to 1 to 16.
-- 2. Added port Ored_CE in addr_gen module port instance.
-- ~~~~~~~
--   SK      11/27/2009
-- ^^^^^^^
-- 1. Updated the parameter C_S_AXI_SUPPORTS_WRITE & C_S_AXI_SUPPORTS_READ.
--    Replaced C_S_AXI_SUPPORTS_READ_WRITE.
-- 2. Updated width of S_AXI_AWCACHE & S_AXI_ARCACHE from (4 downto 0) to
--    (3 downto 0).
-- 3. Updated width of S_AXI_ARPROT & S_AXI_AWPROT from (3 downto 0) to
--    (2 downto 0);
-- 4. Updated "proc_common_pkg.log2" with "proc_common_pkg.clog2".
--    Updated the instances of log2 to clog2.
-- ~~~~~~~
--   SK      02/28/2010
-- ^^^^^^^
-- 1. Removed unused "S_AXI_AWLOCK"&"S_AXI_ARLOCK" from "control_state_machine"
--    instace port list.
-- 2. Removed unused "axi_cycle_cmb" from portlist of "address_decode" instance
-- 3. Added "S_AXI_AWVALID" in "address_decode" instance port list.
-- ~~~~~~~
--   SK      05/10/2010
-- ^^^^^^^
-- 1. Added assertion for C_S_AXI_SUPPORTS_WRITE = 0 & C_S_AXI_SUPPORTS_READ = 0
--    condition.
-- ~~~~~~~
--  SK      07/29/10
-- ^^^^^^^
-- 1. Code clean for final publish. LOCK signal width is reduced to 1 bit from 
--    original 2 bits.
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
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.proc_common_pkg.clog2;
use proc_common_v3_00_a.proc_common_pkg.max2;
use proc_common_v3_00_a.family_support.all;
use proc_common_v3_00_a.ipif_pkg.all;
use proc_common_v3_00_a.or_gate128;

library axi_slave_burst_v1_00_a;
use axi_slave_burst_v1_00_a.all;

-------------------------------------------------------------------------------
--                     Definition of Generics
-------------------------------------------------------------------------------
--==================
-- System Parameters
--==================
-- C_FAMILY               -- Target FPGA family
-- C_RDATA_FIFO_DEPTH     -- Decides the Read FIFO data depth.allowed values,-
--                        -- 0 or 32 only.
--                        -- This buffer values are essential to set, if core
--                        -- needs the read buffer.
-- C_TIMEOUT_CNTR_VAL     -- Read Data Time-out Counter - allowed value
--                        -- 8 or 16 only.
--================
-- Core Parameters
--================
-- C_S_AXI_SUPPORTS_WRITE -- if set to '1', then the core supports write xfer
--                        -- if '0', then the core doesnt support write xfer
-- C_S_AXI_SUPPORTS_READ  -- if set to '1', then the core supports read xfer
--                        -- if '0', then the core doesnt support read xfer
-- C_S_AXI_ADDR_WIDTH     -- AXI address bus width - allowed value - 32 only
-- C_S_AXI_DATA_WIDTH     -- AXI data bus width - allowed value - 32 or 64 only
-- C_S_AXI_ID_WIDTH       -- AXI Identification TAG width - 1 to 16

-- C_ARD_ADDR_RANGE_ARRAY -- Base /High Address Pair for each Address Range
-- C_ARD_NUM_CE_ARRAY     -- Desired number of chip enables for address range

-------------------------------------------------------------------------------
--                  Definition of Ports
-------------------------------------------------------------------------------
-- S_AXI_ACLK            -- AXI Clock
-- S_AXI_ARESETN          -- AXI Reset - active low
--==================================
-- AXI Write Address Channel Signals
--==================================
-- S_AXI_AWID            -- AXI Write Address ID
-- S_AXI_AWADDR          -- AXI Write address - 32 bit
-- S_AXI_AWLEN           -- AXI Write Data Length
-- S_AXI_AWSIZE          -- AXI Burst Size - allowed values
--                       -- 000 - byte burst
--                       -- 001 - half word
--                       -- 010 - word
--                       -- 011 - double word
--                       -- NA for all remaining values
-- S_AXI_AWBURST         -- AXI Burst Type
--                       -- 00  - Fixed
--                       -- 01  - Incr
--                       -- 10  - Wrap
--                       -- 11  - Reserved
-- S_AXI_AWLOCK          -- AXI Lock type
-- S_AXI_AWCACHE         -- AXI Cache Type
-- S_AXI_AWPROT          -- AXI Protection Type
-- S_AXI_AWVALID         -- Write address valid
-- S_AXI_AWREADY         -- Write address ready
--===============================
-- AXI Write Data Channel Signals
--===============================
-- S_AXI_WDATA           -- AXI Write data width
-- S_AXI_WSTRB           -- AXI Write strobes
-- S_AXI_WLAST           -- AXI Last write indicator signal
-- S_AXI_WVALID          -- AXI Write valid
-- S_AXI_WREADY          -- AXI Write ready
--================================
-- AXI Write Data Response Signals
--================================
-- S_AXI_BID             -- AXI Write Response channel number
-- S_AXI_BRESP           -- AXI Write response
--                       -- 00  - Okay
--                       -- 01  - ExOkay
--                       -- 10  - Slave Error
--                       -- 11  - Decode Error
-- S_AXI_BVALID          -- AXI Write response valid
-- S_AXI_BREADY          -- AXI Response ready
--=================================
-- AXI Read Address Channel Signals
--=================================
-- S_AXI_ARID            -- AXI Read ID
-- S_AXI_ARADDR          -- AXI Read address
-- S_AXI_ARLEN           -- AXI Read Data length
-- S_AXI_ARSIZE          -- AXI Read Size
-- S_AXI_ARBURST         -- AXI Read Burst length
-- S_AXI_ARLOCK          -- AXI Read Lock
-- S_AXI_ARCACHE         -- AXI Read Cache
-- S_AXI_ARPROT          -- AXI Read Protection
-- S_AXI_RVALID          -- AXI Read valid
-- S_AXI_RREADY          -- AXI Read ready
--==============================
-- AXI Read Data Channel Signals
--==============================
-- S_AXI_RID             -- AXI Read Channel ID
-- S_AXI_RDATA           -- AXI Read data
-- S_AXI_RRESP           -- AXI Read response
-- S_AXI_RLAST           -- AXI Read Data Last signal
-- S_AXI_RVALID          -- AXI Read address valid
-- S_AXI_RREADY          -- AXI Read address ready
--============================
-- User IPIC interface Signals
--============================
-- Bus2IP_Clk            -- 1:1 synchronization clock provided to User IP
-- Bus2IP_Resetn          -- Active low reset for use by the User IP

-- IP2Bus_Data           -- Input Read Data bus from the User IP
-- IP2Bus_WrAck          -- Active high Write Data qualifier from the IP
-- IP2Bus_RdAck          -- Active high Read Data qualifier from the IP
-- IP2Bus_AddrAck        -- Active high Address qualifier from the IP
-- IP2Bus_Error          -- Error signal from the IP

-- Bus2IP_Addr           -- Desired address of read or write operation
-- Bus2IP_Data           -- Write data bus to the User IP
-- Bus2IP_RNW            -- Read or write indicator for the transaction
-- Bus2IP_BE             -- Byte enables for the data bus
-- Bus2IP_Burst          -- Burst information to the IP
-- Bus2IP_BurstLength    -- Burst length information to the IP in terms of no.
--                       -- of "beats"
-- Bus2IP_WrReq          -- Write Request signal to the IP
-- Bus2IP_RdReq          -- Read Request signal to the IP
-- Bus2IP_CS             -- Chip select for the transcations
-- Bus2IP_RdCE           -- Chip enables for the read
-- Bus2IP_WrCE           -- Chip enables for the write
-- Type_of_xfer          -- Fixed transfer or incr/wrap transfer.
-------------------------------------------------------------------------------

entity axi_slave_burst is
    generic (
---- System Parameters
     C_FAMILY                       : string   := "virtex6";
     C_RDATA_FIFO_DEPTH             : integer  := 0;-- 0 or 32
     C_INCLUDE_TIMEOUT_CNT          : integer range 0 to 1   := 1;
     C_TIMEOUT_CNTR_VAL             : integer  := 8;-- allowed values 8 or 16
     C_ALIGN_BE_RDADDR              : integer range 0 to 1   := 0;
---- AXI Parameters
     C_S_AXI_SUPPORTS_WRITE         : integer range 0 to 1      := 1;
     C_S_AXI_SUPPORTS_READ          : integer range 0 to 1      := 1;
     --C_S_AXI_SUPPORTS_READ_WRITE  : string   := "11";   -- "01" read only ,
     --                                                   -- "10" write only,
     --                                                   -- "11" read-write,
     --                                                   -- "00" skipped slot

     C_S_AXI_ADDR_WIDTH     : integer range 32 to 32 := 32;
     C_S_AXI_DATA_WIDTH     : integer range 32 to 64 := 32;
     C_S_AXI_ID_WIDTH       : integer range 1 to 16   := 4;

     C_ARD_ADDR_RANGE_ARRAY : SLV64_ARRAY_TYPE :=
       (
         X"0000_0000_7000_0000", -- IP user0 base address
         X"0000_0000_7000_00FF", -- IP user0 high address

         X"0000_0000_7000_0100", -- IP user1 base address
         X"0000_0000_7000_01FF"  -- IP user1 high address
     );
     C_ARD_NUM_CE_ARRAY     : INTEGER_ARRAY_TYPE :=
        (
          1,         -- User0 CE Number -- only 1 is supported per addr range
          1          -- User1 CE Number -- only 1 is supported per addr range
        )
     );

    port (
--  -- AXI Slave signals ------------------------------------------------------
--   -- AXI Global System Signals
       S_AXI_ACLK    : in  std_logic;
       S_AXI_ARESETN : in  std_logic;
--   -- AXI Write Address Channel Signals
       S_AXI_AWID    : in  std_logic_vector((C_S_AXI_ID_WIDTH-1) downto 0);
       S_AXI_AWADDR  : in  std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);
       S_AXI_AWLEN   : in  std_logic_vector(7 downto 0);
       S_AXI_AWSIZE  : in  std_logic_vector(2 downto 0);
       S_AXI_AWBURST : in  std_logic_vector(1 downto 0);
       S_AXI_AWLOCK  : in  std_logic;
       S_AXI_AWCACHE : in  std_logic_vector(3 downto 0);
       S_AXI_AWPROT  : in  std_logic_vector(2 downto 0);
       S_AXI_AWVALID : in  std_logic;
       S_AXI_AWREADY : out std_logic;
--   -- AXI Write Channel Signals
       S_AXI_WDATA   : in  std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
       S_AXI_WSTRB   : in  std_logic_vector
                               (((C_S_AXI_DATA_WIDTH/8)-1) downto 0);
       S_AXI_WLAST   : in  std_logic;
       S_AXI_WVALID  : in  std_logic;
       S_AXI_WREADY  : out std_logic;
--   -- AXI Write Response Channel Signals
       S_AXI_BID     : out std_logic_vector((C_S_AXI_ID_WIDTH-1) downto 0);
       S_AXI_BRESP   : out std_logic_vector(1 downto 0);
       S_AXI_BVALID  : out std_logic;
       S_AXI_BREADY  : in  std_logic;
--   -- AXI Read Address Channel Signals
       S_AXI_ARID    : in  std_logic_vector((C_S_AXI_ID_WIDTH-1) downto 0);
       S_AXI_ARADDR  : in  std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);
       S_AXI_ARLEN   : in  std_logic_vector(7 downto 0);
       S_AXI_ARSIZE  : in  std_logic_vector(2 downto 0);
       S_AXI_ARBURST : in  std_logic_vector(1 downto 0);
       S_AXI_ARLOCK  : in  std_logic;
       S_AXI_ARCACHE : in  std_logic_vector(3 downto 0);
       S_AXI_ARPROT  : in  std_logic_vector(2 downto 0);
       S_AXI_ARVALID : in  std_logic;
       S_AXI_ARREADY : out std_logic;
--   -- AXI Read Data Channel Signals
       S_AXI_RID     : out std_logic_vector((C_S_AXI_ID_WIDTH-1) downto 0);
       S_AXI_RDATA   : out std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
       S_AXI_RRESP   : out std_logic_vector(1 downto 0);
       S_AXI_RLAST   : out std_logic;
       S_AXI_RVALID  : out std_logic;
       S_AXI_RREADY  : in  std_logic;
      -- Controls to the IP/IPIF modules
       Bus2IP_Clk    : out std_logic;
       Bus2IP_Resetn : out std_logic;
       IP2Bus_Data   : in  std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0 );
       IP2Bus_WrAck  : in  std_logic;
       IP2Bus_RdAck  : in  std_logic;
       IP2Bus_AddrAck: in  std_logic;
       IP2Bus_Error  : in  std_logic;

       Bus2IP_Addr   : out std_logic_vector((C_S_AXI_ADDR_WIDTH-1) downto 0);
       Bus2IP_Data   : out std_logic_vector((C_S_AXI_DATA_WIDTH-1) downto 0);
       Bus2IP_RNW    : out std_logic;
       Bus2IP_BE    : out std_logic_vector(((C_S_AXI_DATA_WIDTH/8)-1)downto 0);
       Bus2IP_Burst  : out std_logic;
       Bus2IP_BurstLength: out std_logic_vector(7 downto 0);
       Bus2IP_WrReq  : out std_logic;
       Bus2IP_RdReq  : out std_logic;
       Bus2IP_CS     : out std_logic_vector
                             ((((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1)downto 0);
       Bus2IP_RdCE   : out std_logic_vector
                               ((calc_num_ce(C_ARD_NUM_CE_ARRAY)-1)downto 0);
       Bus2IP_WrCE   : out std_logic_vector
                                 ((calc_num_ce(C_ARD_NUM_CE_ARRAY)-1)downto 0);
       Type_of_xfer  : out std_logic
        );

-- Fan-out attributes for XST
attribute MAX_FANOUT                             : string;
attribute MAX_FANOUT of S_AXI_ACLK               : signal is "10000";
attribute MAX_FANOUT of S_AXI_ARESETN            : signal is "10000";

end entity axi_slave_burst;
-------------------------------------------------------------------------------
------------------------
-- Architecture Section
------------------------
architecture imp of axi_slave_burst is
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
constant C_MAX_BURST_LENGTH  : integer := 8;

-------------------------------------------------------------------------------
-- internal signal declaration
-------------------------------------------------------------------------------
signal Rd_fifo_empty   : std_logic := '0';
signal RNW_reg         : std_logic := '0';
signal last_data       : std_logic := '0';
signal Rd_fifo_empty_1 : std_logic := '0';
signal Address_int     : std_logic_vector ((C_S_AXI_ADDR_WIDTH-1) downto 0)
                       :=(others => '0');
signal Addr_int        : std_logic_vector ((C_S_AXI_ADDR_WIDTH-1) downto 0)
                       :=(others => '0');

signal Derived_Burst :  std_logic_vector(1 downto 0);
signal Derived_Size  :  std_logic_vector(1 downto 0);
signal Derived_Len   :  std_logic_vector(3 downto 0);

signal Rd_data_sm_ps_IDLE     : std_logic:='0';
signal Addr_SM_PS_IDLE        : std_logic:='0';
signal Addr_SM_NS_IDLE        : std_logic:='0';
signal ORed_CE                : std_logic:='0';
signal Addr_Timeout           : std_logic:='0';
signal Rst_CS                 : std_logic:='0';
signal Rst_Rd_CE              : std_logic:='0';
signal Rst_Wr_CE              : std_logic:='0';
signal wr_cycle_cmb           : std_logic:='0';
signal axi_cycle_cmb          : std_logic:='0';
signal RdFIFO_Space_two       : std_logic:='0';
signal store_addr_info        : std_logic:='0';
signal Enable_WrCE            : std_logic:='0';
signal Enable_RdCE            : std_logic:='0';
signal Data_Timeout           : std_logic:='0';
signal Enable_CS              : std_logic:='0';
signal rd_single_reg          : std_logic:='0';
signal RNW                    : std_logic:='0';
signal rlast_int              : std_logic:='0';
signal addr_sm_ps_IDLE_int    : std_logic:='0';

signal Rdce_ored              : std_logic:='0';
signal Wrce_ored              : std_logic:='0';

signal Next_addr_strobe       : std_logic;
signal Bus2IP_CS_i            : std_logic_vector
                             ((((C_ARD_ADDR_RANGE_ARRAY'LENGTH)/2)-1)downto 0);
signal ORed_CS                : std_logic;
signal LAST_FIFO_data         : std_logic;


signal No_addr_space  	     : std_logic;
signal last_data_for_rd_tr   : std_logic;
signal stop_addr_incr 	     : std_logic;
signal load_addr_fifo	     : std_logic;
signal Bus2IP_RdReq_addr_fifo: std_logic;

-------------------------------------------------------------------------------
-- Begin architecture logic
-------------------------------------------------------------------------------
begin
-------------------------------------------------------------------------------
-- Slave Attachment
-------------------------------------------------------------------------------

    Bus2IP_Clk    <= S_AXI_ACLK;

    Bus2IP_Resetn <= S_AXI_ARESETN;

    Bus2IP_RNW    <= RNW_reg;
    S_AXI_RLAST   <= rlast_int;

 -- SUPPORT_RW_TRANSACTIONS: The below logic is only for R/W Transactions
 ---------------------------
 SUPPORT_RW_TRANSACTIONS: if (C_S_AXI_SUPPORTS_WRITE = 1) and
                                           (C_S_AXI_SUPPORTS_READ = 1) generate
 begin
    CONTROL_SM_I: entity axi_slave_burst_v1_00_a.control_state_machine
    generic map(
     C_FAMILY                   => C_FAMILY             ,
     C_RDATA_FIFO_DEPTH         => C_RDATA_FIFO_DEPTH   ,
     C_INCLUDE_TIMEOUT_CNT      => C_INCLUDE_TIMEOUT_CNT,
     C_TIMEOUT_CNTR_VAL         => C_TIMEOUT_CNTR_VAL   ,
     C_ALIGN_BE_RDADDR          => C_ALIGN_BE_RDADDR    ,
     C_S_AXI_ADDR_WIDTH         => C_S_AXI_ADDR_WIDTH   ,
     C_S_AXI_DATA_WIDTH         => C_S_AXI_DATA_WIDTH   ,
     C_S_AXI_ID_WIDTH           => C_S_AXI_ID_WIDTH     ,
     C_MAX_BURST_LENGTH         => C_MAX_BURST_LENGTH
     )
    port map(
     S_AXI_ACLK               => S_AXI_ACLK           ,
     S_AXI_ARESETN            => S_AXI_ARESETN        ,
     -- write channel address signals
     S_AXI_AWID               => S_AXI_AWID           ,
     S_AXI_AWADDR             => S_AXI_AWADDR         ,
     S_AXI_AWLEN              => S_AXI_AWLEN          ,
     S_AXI_AWSIZE             => S_AXI_AWSIZE         ,
     S_AXI_AWBURST            => S_AXI_AWBURST        ,

     S_AXI_AWVALID            => S_AXI_AWVALID        ,
     S_AXI_AWREADY            => S_AXI_AWREADY        ,
     -- write channel data signals
     S_AXI_WDATA              => S_AXI_WDATA          ,
     S_AXI_WSTRB              => S_AXI_WSTRB          ,

     S_AXI_WVALID             => S_AXI_WVALID         ,
     S_AXI_WREADY             => S_AXI_WREADY         ,
     -- write channel response signals
     S_AXI_BID                => S_AXI_BID            ,
     S_AXI_BRESP              => S_AXI_BRESP          ,
     S_AXI_BVALID             => S_AXI_BVALID         ,
     S_AXI_BREADY             => S_AXI_BREADY         ,
     -- read channel address signals
     S_AXI_ARID               => S_AXI_ARID           ,
     S_AXI_ARADDR             => S_AXI_ARADDR         ,
     S_AXI_ARLEN              => S_AXI_ARLEN          ,
     S_AXI_ARSIZE             => S_AXI_ARSIZE         ,
     S_AXI_ARBURST            => S_AXI_ARBURST        ,

     S_AXI_ARVALID            => S_AXI_ARVALID        ,
     S_AXI_ARREADY            => S_AXI_ARREADY        ,
     -- read channel response signals
     S_AXI_RREADY             => S_AXI_RREADY         ,
     S_AXI_RLAST              => rlast_int            ,
     S_AXI_RID                => S_AXI_RID            ,
     -- ip2bus signals

     IP2Bus_WrAck             => IP2Bus_WrAck         ,
     IP2Bus_RdAck             => IP2Bus_RdAck         ,
     IP2Bus_AddrAck           => IP2Bus_AddrAck       ,
     IP2Bus_Error             => IP2Bus_Error         ,
     -- bus2ip signals
     Bus2IP_Data              => Bus2IP_Data          ,
     Bus2IP_RNW               => RNW_reg              ,
     Bus2IP_BE                => Bus2IP_BE            ,
     Bus2IP_Burst             => Bus2IP_Burst         ,
     Bus2IP_BurstLength       => Bus2IP_BurstLength   ,

     Bus2IP_WrReq             => Bus2IP_WrReq         ,
     Bus2IP_RdReq             => Bus2IP_RdReq         ,
     Data_Timeout             => Data_Timeout         ,
     Rd_data_sm_ps_IDLE       => Rd_data_sm_ps_IDLE   ,
     -- to address generation logic
     Addr_int                 => Addr_int             ,
     Derived_Len              => Derived_Len          ,
     Derived_Burst            => Derived_Burst        ,
     Derived_Size             => Derived_Size         ,
     -- to address decode
     Enable_CS                => Enable_CS            ,
     Enable_WrCE              => Enable_WrCE          ,
     Enable_RdCE              => Enable_RdCE          ,
     Rst_CS                   => Rst_CS               ,
     Rst_Wr_CE                => Rst_Wr_CE            ,
     Rst_Rd_CE                => Rst_Rd_CE            ,
     -- from read data path
     RdFIFO_Space_two         => RdFIFO_Space_two     ,
     Addr_Timeout             => Addr_Timeout         ,
     -- from address decode
     ORed_CE                  => ORed_CE              ,
     Wrce_ored                => Wrce_ored,
     Store_addr_info          => store_addr_info      ,

     rd_single_reg            => rd_single_reg        ,
     wr_cycle_cmb             => wr_cycle_cmb         ,

     axi_cycle_cmb            => axi_cycle_cmb        ,
     Last_data                => last_data            ,

     RNW                      => RNW                  ,
     addr_sm_ps_IDLE          => addr_sm_ps_IDLE_int  ,
     Next_addr_strobe         => Next_addr_strobe     ,


     Type_of_xfer             => Type_of_xfer         ,

     ORed_CS                  => ORed_CS                ,
     LAST_data_from_FIFO      => LAST_FIFO_data       ,

     No_addr_space            => No_addr_space,
     last_data_for_rd_tr      => last_data_for_rd_tr,
     stop_addr_incr           => stop_addr_incr,

     load_addr_fifo           => load_addr_fifo,

     Rdce_ored                => Rdce_ored      
     );

    READ_DATA_SM_I: entity axi_slave_burst_v1_00_a.read_data_path
    generic map(
     C_FAMILY                 => C_FAMILY             ,
     C_RDATA_FIFO_DEPTH       => C_RDATA_FIFO_DEPTH   ,
     C_INCLUDE_TIMEOUT_CNT    => C_INCLUDE_TIMEOUT_CNT,
     C_TIMEOUT_CNTR_VAL       => C_TIMEOUT_CNTR_VAL   ,
     C_S_AXI_DATA_WIDTH       => C_S_AXI_DATA_WIDTH
     )
    port map(
     S_AXI_ACLK               => S_AXI_ACLK   ,
     S_AXI_ARESETN            => S_AXI_ARESETN ,
     S_AXI_ARLEN              => S_AXI_ARLEN  ,
     S_AXI_RDATA              => S_AXI_RDATA  ,
     S_AXI_RRESP              => S_AXI_RRESP  ,
     S_AXI_RLAST              => rlast_int    ,
     S_AXI_RVALID             => S_AXI_RVALID ,
     S_AXI_RREADY             => S_AXI_RREADY ,

     -- Controls to the IP/IPIF modules
     Store_addr_info          => store_addr_info,
     IP2Bus_Data              => IP2Bus_Data   ,
     IP2Bus_RdAck             => IP2Bus_RdAck  ,
     IP2Bus_AddrAck           => IP2Bus_AddrAck,
     IP2Bus_Error             => IP2Bus_Error  ,

     Rd_Single                => rd_single_reg ,
     Last_rd_data_ipic        => last_data     ,
     Rd_data_sm_ps_IDLE       => Rd_data_sm_ps_IDLE,
     Data_Timeout             => Data_Timeout  ,
     RdFIFO_Space_two         => RdFIFO_Space_two,
     Addr_Timeout             => Addr_Timeout  ,
     wr_cycle_cmb             => wr_cycle_cmb  ,
     Rdce_ored                => Rdce_ored      ,
     LAST_data_from_FIFO      => LAST_FIFO_data,
     No_addr_space            => No_addr_space,
     last_data_for_rd_tr      => last_data_for_rd_tr,

     load_addr_fifo => load_addr_fifo
    );

    ADDRESS_GEN_I: entity axi_slave_burst_v1_00_a.addr_gen
     generic map(
     C_S_AXI_ADDR_WIDTH      => C_S_AXI_ADDR_WIDTH,
     C_S_AXI_DATA_WIDTH      => C_S_AXI_DATA_WIDTH,
     C_RDATA_FIFO_DEPTH      => C_RDATA_FIFO_DEPTH
     )
     port map(
     Bus2IP_Clk              => S_AXI_ACLK           ,
     Bus2IP_Resetn           => S_AXI_ARESETN        ,

     Store_addr_info         => store_addr_info      ,

     Derived_Burst           => Derived_Burst        ,
     Derived_Size            => Derived_Size         ,
     Derived_Len             => Derived_Len          ,
     RNW_cmb                 => RNW                  ,

     Addr_int                => Addr_int             ,
     ORed_CE                 => ORed_CE              ,

     Ip2Bus_Addr_ack         => IP2Bus_AddrAck       ,
     S_AXI_WSTRB             => S_AXI_WSTRB          ,
     Bus2IP_Addr             => Bus2IP_Addr          ,
     Next_addr_strobe        => Next_addr_strobe     ,
     axi_cycle_cmb           => axi_cycle_cmb        ,
     Addr_Timeout            => Addr_Timeout         ,

     IP2Bus_RdAck            => IP2Bus_RdAck         ,
     Data_Timeout            => Data_Timeout         ,
     Rdce_ored               => Rdce_ored            ,

     IP2Bus_WrAck            => IP2Bus_WrAck         ,
     stop_addr_incr          => stop_addr_incr
     );

   ADDRESS_DECODE_I: entity axi_slave_burst_v1_00_a.address_decode
   generic map(
     C_S_AXI_ADDR_WIDTH      => C_S_AXI_ADDR_WIDTH    ,
     C_ADDR_DECODE_BITS      => C_S_AXI_ADDR_WIDTH    ,
     C_ARD_ADDR_RANGE_ARRAY  => C_ARD_ADDR_RANGE_ARRAY,
     C_ARD_NUM_CE_ARRAY      => C_ARD_NUM_CE_ARRAY    ,
     C_FAMILY                => C_FAMILY
     )
   port map(
     Bus2IP_Clk              => S_AXI_ACLK            ,
     Bus2IP_Resetn           => S_AXI_ARESETN         ,

     Enable_CS               => Enable_CS             ,
     Enable_RdCE             => Enable_RdCE           ,
     Enable_WrCE             => Enable_WrCE           ,

     Rst_CS                  => Rst_CS                ,
     Rst_Wr_CE               => Rst_Wr_CE             ,
     Rst_Rd_CE               => Rst_Rd_CE             ,

     Addr_SM_PS_IDLE         => Addr_SM_PS_IDLE_int   ,
     RNW                     => RNW                   ,
     Addr_int                => Addr_int              ,
     ORed_CE                 => ORed_CE               ,

     S_AXI_AWVALID           => S_AXI_AWVALID         ,

     Bus2IP_CS               => Bus2IP_CS_i           ,
     Bus2IP_RdCE             => Bus2IP_RdCE           ,
     Bus2IP_WrCE             => Bus2IP_WrCE           ,
     Rdce_ored               => Rdce_ored,
     Wrce_ored => Wrce_ored
     );

  ORed_CS     <= or_reduce(Bus2IP_CS_i);

  Bus2IP_CS   <= Bus2IP_CS_i;

end generate SUPPORT_RW_TRANSACTIONS;

-------------------------------------------------------------------------------
SUPPORT_W_ONLY_TRANSACTIONS: if (C_S_AXI_SUPPORTS_WRITE = 1) and
                                           (C_S_AXI_SUPPORTS_READ = 0) generate
begin
    CONTROL_SM_I: entity axi_slave_burst_v1_00_a.control_state_machine
    generic map(
     C_FAMILY                  => C_FAMILY                     ,
     C_RDATA_FIFO_DEPTH        => C_RDATA_FIFO_DEPTH           ,
     C_INCLUDE_TIMEOUT_CNT     => C_INCLUDE_TIMEOUT_CNT        ,
     C_TIMEOUT_CNTR_VAL        => C_TIMEOUT_CNTR_VAL           ,
     C_ALIGN_BE_RDADDR         => C_ALIGN_BE_RDADDR            ,
     C_S_AXI_ADDR_WIDTH        => C_S_AXI_ADDR_WIDTH           ,
     C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH           ,
     C_S_AXI_ID_WIDTH          => C_S_AXI_ID_WIDTH             ,

     C_MAX_BURST_LENGTH        => C_MAX_BURST_LENGTH
     )
    port map(
     S_AXI_ACLK               => S_AXI_ACLK           ,
     S_AXI_ARESETN            => S_AXI_ARESETN        ,
     -- write channel address signals
     S_AXI_AWID               => S_AXI_AWID           ,
     S_AXI_AWADDR             => S_AXI_AWADDR         ,
     S_AXI_AWLEN              => S_AXI_AWLEN          ,
     S_AXI_AWSIZE             => S_AXI_AWSIZE         ,
     S_AXI_AWBURST            => S_AXI_AWBURST        ,

     S_AXI_AWVALID            => S_AXI_AWVALID        ,
     S_AXI_AWREADY            => S_AXI_AWREADY        ,
     -- write channel data signals
     S_AXI_WDATA              => S_AXI_WDATA          ,
     S_AXI_WSTRB              => S_AXI_WSTRB          ,

     S_AXI_WVALID             => S_AXI_WVALID         ,
     S_AXI_WREADY             => S_AXI_WREADY         ,
     -- write channel response signals
     S_AXI_BID                => S_AXI_BID            ,
     S_AXI_BRESP              => S_AXI_BRESP          ,
     S_AXI_BVALID             => S_AXI_BVALID         ,
     S_AXI_BREADY             => S_AXI_BREADY         ,
     -- read channel address signals
     S_AXI_ARID               => (others => '0')      ,
     S_AXI_ARADDR             => (others => '0')      ,
     S_AXI_ARLEN              => (others => '0')      ,
     S_AXI_ARSIZE             => (others => '0')      ,
     S_AXI_ARBURST            => (others => '0')      ,

     S_AXI_ARVALID            => '0'                  ,
     S_AXI_ARREADY            => open                 ,

     S_AXI_RID                => open                 ,
     S_AXI_RREADY             => '0'                  ,
     S_AXI_RLAST              => '0'                  ,


     IP2Bus_WrAck             => IP2Bus_WrAck         ,
     IP2Bus_RdAck             => '0'                  ,
     IP2Bus_AddrAck           => IP2Bus_AddrAck       ,
     IP2Bus_Error             => IP2Bus_Error         ,

     Bus2IP_Data              => Bus2IP_Data          ,
     Bus2IP_RNW               => RNW_reg              ,
     Bus2IP_BE                => Bus2IP_BE            ,
     Bus2IP_Burst             => Bus2IP_Burst         ,
     Bus2IP_BurstLength       => Bus2IP_BurstLength   ,

     Bus2IP_WrReq             => Bus2IP_WrReq         ,
     Bus2IP_RdReq             => open                 ,
     Data_Timeout             => Data_Timeout         ,
     Rd_data_sm_ps_IDLE       => '1'                  ,
     -- to address generation logic
     Addr_int                 => Addr_int             ,
     Derived_Len              => Derived_Len          ,
     Derived_Burst            => Derived_Burst        ,
     Derived_Size             => Derived_Size         ,
     -- to address decode
     Enable_CS                => Enable_CS            ,
     Enable_WrCE              => Enable_WrCE          ,
     Enable_RdCE              => open                 ,
     Rst_CS                   => Rst_CS               ,
     Rst_Wr_CE                => Rst_Wr_CE            ,
     Rst_Rd_CE                => open                 ,
     -- from read data path
     RdFIFO_Space_two         => '0'                  ,
     Addr_Timeout             => Addr_Timeout         ,
     -- from address decode
     ORed_CE                  => ORed_CE              ,
     Wrce_ored                => Wrce_ored,
     Store_addr_info          => store_addr_info      ,
     rd_single_reg            => open                 ,
     wr_cycle_cmb             => open                 ,

     axi_cycle_cmb            => axi_cycle_cmb        ,
     Last_data                => last_data            ,
     RNW                      => RNW                  ,
     addr_sm_ps_IDLE          => addr_sm_ps_IDLE_int  ,
     Next_addr_strobe         => Next_addr_strobe     ,

     Type_of_xfer             => Type_of_xfer         ,

     ORed_CS                  => ORed_CS              ,
     LAST_data_from_FIFO      => '0'                  ,

     No_addr_space            => No_addr_space,
     last_data_for_rd_tr      => '0',

     stop_addr_incr           => stop_addr_incr,

     load_addr_fifo           => open,
     Rdce_ored                => Rdce_ored 

   );

   ADDRESS_GEN_I: entity axi_slave_burst_v1_00_a.addr_gen
     generic map(
     C_S_AXI_ADDR_WIDTH      => C_S_AXI_ADDR_WIDTH,
     C_S_AXI_DATA_WIDTH      => C_S_AXI_DATA_WIDTH,
     C_RDATA_FIFO_DEPTH      => C_RDATA_FIFO_DEPTH
     )
     port map(
     Bus2IP_Clk              => S_AXI_ACLK           ,
     Bus2IP_Resetn           => S_AXI_ARESETN        ,

     Store_addr_info         => store_addr_info      ,

     Derived_Burst           => Derived_Burst        ,
     Derived_Size            => Derived_Size         ,
     Derived_Len             => Derived_Len          ,
     RNW_cmb                 => RNW                  ,

     Addr_int                => Addr_int             ,
     ORed_CE                 => ORed_CE              ,

     Ip2Bus_Addr_ack         => IP2Bus_AddrAck       ,
     S_AXI_WSTRB             => S_AXI_WSTRB          ,
     Bus2IP_Addr             => Bus2IP_Addr          ,
     axi_cycle_cmb           => axi_cycle_cmb        ,
     Next_addr_strobe        => Next_addr_strobe     ,
     Addr_Timeout            => Addr_Timeout         ,

     IP2Bus_RdAck            => IP2Bus_RdAck         ,
     Data_Timeout            => Data_Timeout         ,
     Rdce_ored               => Rdce_ored            ,

     IP2Bus_WrAck            => IP2Bus_WrAck         ,

     stop_addr_incr          => stop_addr_incr
     );

   ADDRESS_DECODE_I: entity axi_slave_burst_v1_00_a.address_decode
   generic map(
     C_S_AXI_ADDR_WIDTH      => C_S_AXI_ADDR_WIDTH    ,
     C_ADDR_DECODE_BITS      => C_S_AXI_ADDR_WIDTH    ,
     C_ARD_ADDR_RANGE_ARRAY  => C_ARD_ADDR_RANGE_ARRAY,
     C_ARD_NUM_CE_ARRAY      => C_ARD_NUM_CE_ARRAY    ,
     C_FAMILY                => C_FAMILY
     )
   port map(
     Bus2IP_Clk              => S_AXI_ACLK            ,
     Bus2IP_Resetn           => S_AXI_ARESETN         ,

     Enable_CS               => Enable_CS             ,
     Enable_RdCE             => '0'                   ,
     Enable_WrCE             => Enable_WrCE           ,

     Rst_CS                  => Rst_CS                ,
     Rst_Wr_CE               => Rst_Wr_CE             ,
     Rst_Rd_CE               => '0'                   ,

     Addr_SM_PS_IDLE         => addr_sm_ps_IDLE_int   ,
     RNW                     => RNW                   ,
     Addr_int                => Addr_int              ,
     ORed_CE                 => ORed_CE               ,

     S_AXI_AWVALID           => S_AXI_AWVALID         ,

     Bus2IP_CS               => Bus2IP_CS_i           ,
     Bus2IP_RdCE             => open                  ,
     Bus2IP_WrCE             => Bus2IP_WrCE           ,
     Rdce_ored               => Rdce_ored             ,

     Wrce_ored               => Wrce_ored
     );

  ORed_CS      <= or_reduce(Bus2IP_CS_i);

  Bus2IP_CS    <= Bus2IP_CS_i;

  Bus2IP_RdCE  <= (others => '0');
  S_AXI_RRESP  <= (others => '0');
  S_AXI_RDATA  <= (others => '0');
  S_AXI_RVALID <= '0';
  S_AXI_ARREADY<= '0';
  S_AXI_RID    <= (others => '0');
  S_AXI_RLAST  <= '0';


end generate SUPPORT_W_ONLY_TRANSACTIONS;

-------------------------------------------------------------------------------
-- SUPPORT_R_ONLY_TRANSACTIONS: this logic is Read Only Transacction
-- ----------------------------
SUPPORT_R_ONLY_TRANSACTIONS: if (C_S_AXI_SUPPORTS_WRITE = 0) and
                                           (C_S_AXI_SUPPORTS_READ = 1) generate
begin
    S_AXI_AWREADY <= '0';
    S_AXI_WREADY  <= '0';
    S_AXI_BID     <= (others=>'0');
    S_AXI_BRESP   <= (others=>'0');
    S_AXI_BVALID  <= '0';

    CONTROL_SM_I: entity axi_slave_burst_v1_00_a.control_state_machine
    generic map(
     C_FAMILY                 => C_FAMILY             ,
     C_RDATA_FIFO_DEPTH       => C_RDATA_FIFO_DEPTH   ,
     C_INCLUDE_TIMEOUT_CNT    => C_INCLUDE_TIMEOUT_CNT,
     C_TIMEOUT_CNTR_VAL       => C_TIMEOUT_CNTR_VAL   ,
     C_ALIGN_BE_RDADDR        => C_ALIGN_BE_RDADDR    ,
     C_S_AXI_ADDR_WIDTH       => C_S_AXI_ADDR_WIDTH   ,
     C_S_AXI_DATA_WIDTH       => C_S_AXI_DATA_WIDTH   ,
     C_S_AXI_ID_WIDTH         => C_S_AXI_ID_WIDTH     ,
     C_MAX_BURST_LENGTH       => C_MAX_BURST_LENGTH
     )
    port map(
     S_AXI_ACLK               => S_AXI_ACLK     ,
     S_AXI_ARESETN            => S_AXI_ARESETN  ,
     -- write channel address signals
     S_AXI_AWID               => (others => '0'),
     S_AXI_AWADDR             => (others => '0'),
     S_AXI_AWLEN              => (others => '0'),
     S_AXI_AWSIZE             => (others => '0'),
     S_AXI_AWBURST            => (others => '0'),

     S_AXI_AWVALID            => '0'            ,
     S_AXI_AWREADY            => open           ,
     -- write channel data signals
     S_AXI_WDATA              => (others => '0'),
     S_AXI_WSTRB              => (others => '0'),

     S_AXI_WVALID             => '0'            ,
     S_AXI_WREADY             => open           ,
     -- write channel response signals
     S_AXI_BID                => open           ,
     S_AXI_BRESP              => open           ,
     S_AXI_BVALID             => open           ,
     S_AXI_BREADY             => '0'            ,
     -- read channel address signals
     S_AXI_ARID               => S_AXI_ARID     ,
     S_AXI_ARADDR             => S_AXI_ARADDR   ,
     S_AXI_ARLEN              => S_AXI_ARLEN    ,
     S_AXI_ARSIZE             => S_AXI_ARSIZE   ,
     S_AXI_ARBURST            => S_AXI_ARBURST  ,

     S_AXI_ARVALID            => S_AXI_ARVALID  ,
     S_AXI_ARREADY            => S_AXI_ARREADY  ,
     -- read channel data signals
     S_AXI_RID                => S_AXI_RID      ,
     S_AXI_RREADY             => S_AXI_RREADY   ,
     S_AXI_RLAST              => rlast_int      ,


     IP2Bus_WrAck             => '0'            ,
     IP2Bus_RdAck             => IP2Bus_RdAck   ,
     IP2Bus_AddrAck           => IP2Bus_AddrAck ,
     IP2Bus_Error             => IP2Bus_Error   ,

     Bus2IP_Data              => open           ,
     Bus2IP_RNW               => RNW_reg        ,
     Bus2IP_BE                => open           ,
     Bus2IP_Burst             => Bus2IP_Burst   ,
     Bus2IP_BurstLength       => Bus2IP_BurstLength,
     Bus2IP_WrReq             => open           ,
     Bus2IP_RdReq             => Bus2IP_RdReq   ,
     Data_Timeout             => Data_Timeout   ,
     Rd_data_sm_ps_IDLE       => Rd_data_sm_ps_IDLE,
     -- to address generation logic
     Addr_int                 => Addr_int       ,
     Derived_Len              => Derived_Len    ,
     Derived_Burst            => Derived_Burst  ,
     Derived_Size             => Derived_Size   ,
     -- to address decode
     Enable_CS                => Enable_CS      ,
     Enable_WrCE              => open           ,
     Enable_RdCE              => Enable_RdCE    ,
     Rst_CS                   => Rst_CS         ,
     Rst_Wr_CE                => open           ,
     Rst_Rd_CE                => Rst_Rd_CE      ,
     -- from read data path
     RdFIFO_Space_two         => RdFIFO_Space_two,
     Addr_Timeout             => Addr_Timeout   ,
     -- from address decode
     ORed_CE                  => ORed_CE        ,
     Wrce_ored                => Wrce_ored      ,

     Store_addr_info          => store_addr_info,
     rd_single_reg            => rd_single_reg  ,
     wr_cycle_cmb             => wr_cycle_cmb   ,
     axi_cycle_cmb            => axi_cycle_cmb  ,
     Last_data                => last_data      ,
     RNW                      => RNW            ,
     addr_sm_ps_IDLE          => addr_sm_ps_IDLE_int,
     Next_addr_strobe         => Next_addr_strobe ,

     Type_of_xfer             => Type_of_xfer     ,

     ORed_CS                  => ORed_CS          ,
     LAST_data_from_FIFO      => LAST_FIFO_data   ,

     No_addr_space            => No_addr_space,
     last_data_for_rd_tr      => last_data_for_rd_tr,
     
     stop_addr_incr => stop_addr_incr,

     load_addr_fifo => load_addr_fifo,

     Rdce_ored                => Rdce_ored 
   );

   Rst_Wr_CE    <= '0';
   Enable_WrCE  <= '0';
   Bus2IP_WrReq <= '0';
   Bus2IP_Data  <= (others => '0');
   Bus2IP_BE    <= (others => '1');
-------------------------------------------------------------------------------

READ_DATA_SM_I: entity axi_slave_burst_v1_00_a.read_data_path
    generic map(
     C_FAMILY                 => C_FAMILY             ,
     C_RDATA_FIFO_DEPTH       => C_RDATA_FIFO_DEPTH   ,
     C_INCLUDE_TIMEOUT_CNT    => C_INCLUDE_TIMEOUT_CNT,
     C_TIMEOUT_CNTR_VAL       => C_TIMEOUT_CNTR_VAL   ,
     C_S_AXI_DATA_WIDTH       => C_S_AXI_DATA_WIDTH
     )
    port map(
     S_AXI_ACLK               => S_AXI_ACLK         ,
     S_AXI_ARESETN            => S_AXI_ARESETN      ,
     S_AXI_ARLEN              => S_AXI_ARLEN        ,
     S_AXI_RDATA              => S_AXI_RDATA        ,
     S_AXI_RRESP              => S_AXI_RRESP        ,
     S_AXI_RLAST              => rlast_int          ,
     S_AXI_RVALID             => S_AXI_RVALID       ,
     S_AXI_RREADY             => S_AXI_RREADY       ,
     -- Controls to the IP/IPIF modules
     Store_addr_info          => store_addr_info    ,
     IP2Bus_Data              => IP2Bus_Data        ,
     IP2Bus_RdAck             => IP2Bus_RdAck       ,
     IP2Bus_AddrAck           => IP2Bus_AddrAck     ,
     IP2Bus_Error             => IP2Bus_Error       ,
     Rd_Single                => rd_single_reg      ,
     Last_rd_data_ipic        => last_data          ,
     Rd_data_sm_ps_IDLE       => Rd_data_sm_ps_IDLE ,
     Data_Timeout             => Data_Timeout       ,
     RdFIFO_Space_two         => RdFIFO_Space_two   ,
     Addr_Timeout             => Addr_Timeout       ,
     wr_cycle_cmb             => wr_cycle_cmb       ,
     Rdce_ored                => Rdce_ored          ,
     LAST_data_from_FIFO      => LAST_FIFO_data,
     No_addr_space            => No_addr_space,
     last_data_for_rd_tr      => last_data_for_rd_tr,

     load_addr_fifo => load_addr_fifo
    );

ADDRESS_GEN_I: entity axi_slave_burst_v1_00_a.addr_gen
     generic map(
     C_S_AXI_ADDR_WIDTH      => C_S_AXI_ADDR_WIDTH,
     C_S_AXI_DATA_WIDTH      => C_S_AXI_DATA_WIDTH,
     C_RDATA_FIFO_DEPTH      => C_RDATA_FIFO_DEPTH
     )
     port map(
     Bus2IP_Clk              => S_AXI_ACLK        ,
     Bus2IP_Resetn           => S_AXI_ARESETN     ,

     Store_addr_info         => store_addr_info   ,

     Derived_Burst           => Derived_Burst     ,
     Derived_Size            => Derived_Size      ,
     Derived_Len             => Derived_Len       ,
     RNW_cmb                 => RNW               ,

     Addr_int                => Addr_int          ,
     ORed_CE                 => ORed_CE           ,

     Ip2Bus_Addr_ack         => IP2Bus_AddrAck    ,
     S_AXI_WSTRB             => (others => '0')   ,
     Bus2IP_Addr             => Bus2IP_Addr       ,
     axi_cycle_cmb           => axi_cycle_cmb     ,
     Next_addr_strobe        => Next_addr_strobe  ,
     Addr_Timeout            => Addr_Timeout      ,

     IP2Bus_RdAck            => IP2Bus_RdAck      ,
     Data_Timeout            => Data_Timeout      ,
     Rdce_ored               => Rdce_ored         ,

     IP2Bus_WrAck            => IP2Bus_WrAck      ,
     stop_addr_incr          => stop_addr_incr
     );


ADDRESS_DECODE_I: entity axi_slave_burst_v1_00_a.address_decode
   generic map(
     C_S_AXI_ADDR_WIDTH      => C_S_AXI_ADDR_WIDTH,
     C_ADDR_DECODE_BITS      => C_S_AXI_ADDR_WIDTH,
     C_ARD_ADDR_RANGE_ARRAY  => C_ARD_ADDR_RANGE_ARRAY,
     C_ARD_NUM_CE_ARRAY      => C_ARD_NUM_CE_ARRAY,
     C_FAMILY                => C_FAMILY
     )
   port map(
     Bus2IP_Clk              => S_AXI_ACLK         ,
     Bus2IP_Resetn           => S_AXI_ARESETN      ,

     Enable_CS               => Enable_CS          ,
     Enable_RdCE             => Enable_RdCE        ,
     Enable_WrCE             => '0'                ,

     Rst_CS                  => Rst_CS             ,
     Rst_Wr_CE               => '0'                ,
     Rst_Rd_CE               => Rst_Rd_CE          ,

     Addr_SM_PS_IDLE         => addr_sm_ps_IDLE_int,
     RNW                     => RNW                ,
     Addr_int                => Addr_int           ,
     ORed_CE                 => ORed_CE            ,

     S_AXI_AWVALID           => S_AXI_AWVALID      ,

     Bus2IP_CS               => Bus2IP_CS_i        ,
     Bus2IP_RdCE             => Bus2IP_RdCE        ,
     Bus2IP_WrCE             => open               ,
     Rdce_ored               => Rdce_ored,
     Wrce_ored               => Wrce_ored
     );

  ORed_CS     <= or_reduce(Bus2IP_CS_i);

  Bus2IP_CS   <= Bus2IP_CS_i;

  Bus2IP_WrCE <= (others => '0');

end generate SUPPORT_R_ONLY_TRANSACTIONS;
-----------------------------------------
 -- PASS_THROUGH_TRANSACTIONS : this is Pass Through transaction only. No
 --                             response from the core.
PASS_THROUGH_TRANSACTIONS: if (C_S_AXI_SUPPORTS_WRITE = 0) and
                                         (C_S_AXI_SUPPORTS_READ = 0) generate
begin
  -- IPIC side output signals
  ASSERT (((C_S_AXI_SUPPORTS_WRITE = 1) and (C_S_AXI_SUPPORTS_READ = 1)) or
          ((C_S_AXI_SUPPORTS_WRITE = 0) and (C_S_AXI_SUPPORTS_READ = 1)) or
          ((C_S_AXI_SUPPORTS_WRITE = 1) and (C_S_AXI_SUPPORTS_READ = 0)) 
          )
  REPORT "*** Ilegal parameter(s) C_S_AXI_SUPPORTS_WRITE=0 and C_S_AXI_SUPPORTS_READ=0 combination. The slave IP will be in reset state and wont receive any clock. Simulation wont proceed... ***"
  SEVERITY error;

  Bus2IP_Clk   <= '0';
  Bus2IP_Resetn<= '0';

  Bus2IP_WrCE <= (others => '0');
  Bus2IP_RdCE <= (others => '0');
  Bus2IP_Addr <= (others => '0');
  Bus2IP_Data <= (others => '0');
  Bus2IP_RNW  <= '0';
  Bus2IP_BE   <= (others => '0');
  Bus2IP_Burst<= '0';
  Bus2IP_BurstLength<=  (others => '0');
  Bus2IP_WrReq  <= '0';
  Bus2IP_RdReq  <= '0';
  Bus2IP_CS     <=  (others => '0');
  Type_of_xfer  <= '0';

  -- AXI side output signals
  S_AXI_AWREADY <= '0';
  S_AXI_WREADY  <= '0';
  S_AXI_BID     <= (others => '0');
  S_AXI_BRESP   <= (others => '0');
  S_AXI_BVALID  <= '0';
  S_AXI_ARREADY <= '0';
  S_AXI_RID     <= (others => '0');
  S_AXI_RDATA   <= (others => '0');
  S_AXI_RRESP   <= (others => '0');
  S_AXI_RLAST   <= '0';
  S_AXI_RVALID  <= '0';

end generate PASS_THROUGH_TRANSACTIONS;
--=============================================================================

end imp;
