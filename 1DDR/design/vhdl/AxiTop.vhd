-- Copyright 2018 Delft University of Technology
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

LIBRARY work;
USE work.Axi_pkg.ALL;

-------------------------------------------------------------------------------
-- AXI4 compatible top level for Fletcher generated accelerators.
-------------------------------------------------------------------------------
-- Requires an AXI4 port to host memory.
-- Requires an AXI4-lite port from host for MMIO.
-------------------------------------------------------------------------------
ENTITY AxiTop IS
  GENERIC (
    -- Host bus properties
    BUS_ADDR_WIDTH : NATURAL := 64;
    BUS_DATA_WIDTH : NATURAL := 512;
    BUS_LEN_WIDTH : NATURAL := 8;
    BUS_BURST_MAX_LEN : NATURAL := 64;
    BUS_BURST_STEP_LEN : NATURAL := 1;

    -- MMIO bus properties
    MMIO_ADDR_WIDTH : NATURAL := 32;
    MMIO_DATA_WIDTH : NATURAL := 32;

    -- Arrow properties
    INDEX_WIDTH : NATURAL := 32;

    -- Accelerator properties
    TAG_WIDTH : NATURAL := 1;
    NUM_ARROW_BUFFERS : NATURAL := 1;
    NUM_REGS : NATURAL := 15;
    REG_WIDTH : NATURAL := 32
  );

  PORT (
    kcd_clk : IN STD_LOGIC;
    kcd_reset : IN STD_LOGIC;
    bcd_clk : IN STD_LOGIC;
    bcd_reset : IN STD_LOGIC;

    ---------------------------------------------------------------------------
    -- AXI4 master as Host Memory Interface
    ---------------------------------------------------------------------------
    -- Read address channel
    m_axi_araddr : OUT STD_LOGIC_VECTOR(BUS_ADDR_WIDTH - 1 DOWNTO 0);
    m_axi_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_arvalid : OUT STD_LOGIC;
    m_axi_arready : IN STD_LOGIC;
    m_axi_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Read data channel
    m_axi_rdata : IN STD_LOGIC_VECTOR(BUS_DATA_WIDTH - 1 DOWNTO 0);
    m_axi_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_rlast : IN STD_LOGIC;
    m_axi_rvalid : IN STD_LOGIC;
    m_axi_rready : OUT STD_LOGIC;

    -- Write address channel
    m_axi_awvalid : OUT STD_LOGIC;
    m_axi_awready : IN STD_LOGIC;
    m_axi_awaddr : OUT STD_LOGIC_VECTOR(BUS_ADDR_WIDTH - 1 DOWNTO 0);
    m_axi_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Write data channel
    m_axi_wvalid : OUT STD_LOGIC;
    m_axi_wready : IN STD_LOGIC;
    m_axi_wdata : OUT STD_LOGIC_VECTOR(BUS_DATA_WIDTH - 1 DOWNTO 0);
    m_axi_wlast : OUT STD_LOGIC;
    m_axi_wstrb : OUT STD_LOGIC_VECTOR(BUS_DATA_WIDTH/8 - 1 DOWNTO 0);

    ---------------------------------------------------------------------------
    -- AXI4-lite Slave as MMIO interface
    ---------------------------------------------------------------------------
    -- Write adress channel
    s_axi_awvalid : IN STD_LOGIC;
    s_axi_awready : OUT STD_LOGIC;
    s_axi_awaddr : IN STD_LOGIC_VECTOR(MMIO_ADDR_WIDTH - 1 DOWNTO 0);

    -- Write data channel
    s_axi_wvalid : IN STD_LOGIC;
    s_axi_wready : OUT STD_LOGIC;
    s_axi_wdata : IN STD_LOGIC_VECTOR(MMIO_DATA_WIDTH - 1 DOWNTO 0);
    s_axi_wstrb : IN STD_LOGIC_VECTOR((MMIO_DATA_WIDTH/8) - 1 DOWNTO 0);

    -- Write response channel
    s_axi_bvalid : OUT STD_LOGIC;
    s_axi_bready : IN STD_LOGIC;
    s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- Read address channel
    s_axi_arvalid : IN STD_LOGIC;
    s_axi_arready : OUT STD_LOGIC;
    s_axi_araddr : IN STD_LOGIC_VECTOR(MMIO_ADDR_WIDTH - 1 DOWNTO 0);

    -- Read data channel
    s_axi_rvalid : OUT STD_LOGIC;
    s_axi_rready : IN STD_LOGIC;
    s_axi_rdata : OUT STD_LOGIC_VECTOR(MMIO_DATA_WIDTH - 1 DOWNTO 0);
    s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)

  );
END AxiTop;

ARCHITECTURE Behavorial OF AxiTop IS

  -- Write response channels
  SIGNAL m_axi_bvalid : STD_LOGIC;
  SIGNAL m_axi_bready : STD_LOGIC := '1';
  SIGNAL m_axi_bresp : STD_LOGIC_VECTOR(1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- Default wrapper component.
  -----------------------------------------------------------------------------
  COMPONENT ptoa_wrapper IS
    GENERIC (
      BUS_DATA_WIDTH : NATURAL;
      BUS_ADDR_WIDTH : NATURAL;
      BUS_LEN_WIDTH : NATURAL;
      BUS_BURST_STEP_LEN : NATURAL;
      BUS_BURST_MAX_LEN : NATURAL;
      INDEX_WIDTH : NATURAL;
      NUM_ARROW_BUFFERS : NATURAL;
      NUM_REGS : NATURAL;
      REG_WIDTH : NATURAL;
      TAG_WIDTH : NATURAL
    );
    PORT (
      acc_clk : IN STD_LOGIC;
      acc_reset : IN STD_LOGIC;
      bus_clk : IN STD_LOGIC;
      bus_reset : IN STD_LOGIC;
      mst_rreq_valid : OUT STD_LOGIC;
      mst_rreq_ready : IN STD_LOGIC;
      mst_rreq_addr : OUT STD_LOGIC_VECTOR(BUS_ADDR_WIDTH - 1 DOWNTO 0);
      mst_rreq_len : OUT STD_LOGIC_VECTOR(BUS_LEN_WIDTH - 1 DOWNTO 0);
      mst_rdat_valid : IN STD_LOGIC;
      mst_rdat_ready : OUT STD_LOGIC;
      mst_rdat_data : IN STD_LOGIC_VECTOR(BUS_DATA_WIDTH - 1 DOWNTO 0);
      mst_rdat_last : IN STD_LOGIC;
      mst_wreq_valid : OUT STD_LOGIC;
      mst_wreq_ready : IN STD_LOGIC;
      mst_wreq_addr : OUT STD_LOGIC_VECTOR(BUS_ADDR_WIDTH - 1 DOWNTO 0);
      mst_wreq_len : OUT STD_LOGIC_VECTOR(BUS_LEN_WIDTH - 1 DOWNTO 0);
      mst_wreq_last : OUT STD_LOGIC;
      mst_wdat_valid : OUT STD_LOGIC;
      mst_wdat_ready : IN STD_LOGIC;
      mst_wdat_data : OUT STD_LOGIC_VECTOR(BUS_DATA_WIDTH - 1 DOWNTO 0);
      mst_wdat_strobe : OUT STD_LOGIC_VECTOR(BUS_DATA_WIDTH/8 - 1 DOWNTO 0);
      mst_wdat_last : OUT STD_LOGIC;
      regs_in : IN STD_LOGIC_VECTOR(NUM_REGS * REG_WIDTH - 1 DOWNTO 0);
      regs_out : OUT STD_LOGIC_VECTOR(NUM_REGS * REG_WIDTH - 1 DOWNTO 0);
      regs_out_en : OUT STD_LOGIC_VECTOR(NUM_REGS - 1 DOWNTO 0)
    );
  END COMPONENT;
  -----------------------------------------------------------------------------

  -- Fletcher bus signals
  SIGNAL bcd_reset_n : STD_LOGIC;

  SIGNAL bus_rreq_addr : STD_LOGIC_VECTOR(BUS_ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL bus_rreq_len : STD_LOGIC_VECTOR(BUS_LEN_WIDTH - 1 DOWNTO 0);
  SIGNAL bus_rreq_valid : STD_LOGIC;
  SIGNAL bus_rreq_ready : STD_LOGIC;

  SIGNAL bus_rdat_data : STD_LOGIC_VECTOR(BUS_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL bus_rdat_last : STD_LOGIC;
  SIGNAL bus_rdat_valid : STD_LOGIC;
  SIGNAL bus_rdat_ready : STD_LOGIC;

  SIGNAL bus_wreq_valid : STD_LOGIC;
  SIGNAL bus_wreq_ready : STD_LOGIC;
  SIGNAL bus_wreq_addr : STD_LOGIC_VECTOR(BUS_ADDR_WIDTH - 1 DOWNTO 0);
  SIGNAL bus_wreq_len : STD_LOGIC_VECTOR(BUS_LEN_WIDTH - 1 DOWNTO 0);
  SIGNAL bus_wreq_last : STD_LOGIC;

  SIGNAL bus_wdat_valid : STD_LOGIC;
  SIGNAL bus_wdat_ready : STD_LOGIC;
  SIGNAL bus_wdat_data : STD_LOGIC_VECTOR(BUS_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL bus_wdat_strobe : STD_LOGIC_VECTOR(BUS_DATA_WIDTH/8 - 1 DOWNTO 0);
  SIGNAL bus_wdat_last : STD_LOGIC;

  SIGNAL slv_bus_wrep_valid : STD_LOGIC;
  SIGNAL slv_bus_wrep_ready : STD_LOGIC;
  SIGNAL slv_bus_wrep_ok : STD_LOGIC;

  -- MMIO registers
  SIGNAL regs_in : STD_LOGIC_VECTOR(NUM_REGS * REG_WIDTH - 1 DOWNTO 0);
  SIGNAL regs_out : STD_LOGIC_VECTOR(NUM_REGS * REG_WIDTH - 1 DOWNTO 0);
  SIGNAL regs_out_en : STD_LOGIC_VECTOR(NUM_REGS - 1 DOWNTO 0);
BEGIN

  -- Active low reset
  bcd_reset_n <= '1' WHEN bcd_reset = '0' ELSE
    '0';

  -----------------------------------------------------------------------------
  -- Fletcher generated wrapper
  -----------------------------------------------------------------------------
  ptoa_wrapper_inst : ptoa_wrapper
  GENERIC MAP(
    BUS_DATA_WIDTH => BUS_DATA_WIDTH,
    BUS_ADDR_WIDTH => BUS_ADDR_WIDTH,
    BUS_LEN_WIDTH => BUS_LEN_WIDTH,
    BUS_BURST_STEP_LEN => BUS_BURST_STEP_LEN,
    BUS_BURST_MAX_LEN => BUS_BURST_MAX_LEN,
    INDEX_WIDTH => INDEX_WIDTH,
    NUM_ARROW_BUFFERS => NUM_ARROW_BUFFERS,
    NUM_REGS => NUM_REGS,
    REG_WIDTH => REG_WIDTH,
    TAG_WIDTH => TAG_WIDTH
  )
  PORT MAP(
    acc_clk => kcd_clk,
    acc_reset => kcd_reset,
    bus_clk => bcd_clk,
    bus_reset => bcd_reset,
    mst_rreq_valid => bus_rreq_valid,
    mst_rreq_ready => bus_rreq_ready,
    mst_rreq_addr => bus_rreq_addr,
    mst_rreq_len => bus_rreq_len,
    mst_rdat_valid => bus_rdat_valid,
    mst_rdat_ready => bus_rdat_ready,
    mst_rdat_data => bus_rdat_data,
    mst_rdat_last => bus_rdat_last,
    mst_wreq_valid => bus_wreq_valid,
    mst_wreq_ready => bus_wreq_ready,
    mst_wreq_addr => bus_wreq_addr,
    mst_wreq_len => bus_wreq_len,
    mst_wreq_last => bus_wreq_last,
    mst_wdat_valid => bus_wdat_valid,
    mst_wdat_ready => bus_wdat_ready,
    mst_wdat_data => bus_wdat_data,
    mst_wdat_strobe => bus_wdat_strobe,
    mst_wdat_last => bus_wdat_last,
    regs_in => regs_in,
    regs_out => regs_out,
    regs_out_en => regs_out_en
  );

  -----------------------------------------------------------------------------
  -- AXI read converter
  -----------------------------------------------------------------------------
  -- Buffering bursts is disabled (ENABLE_FIFO=false) because BufferReaders
  -- are already able to absorb full bursts.
  axi_read_conv_inst : AxiReadConverter
  GENERIC MAP(
    ADDR_WIDTH => BUS_ADDR_WIDTH,
    MASTER_DATA_WIDTH => BUS_DATA_WIDTH,
    MASTER_LEN_WIDTH => BUS_LEN_WIDTH,
    SLAVE_DATA_WIDTH => BUS_DATA_WIDTH,
    SLAVE_LEN_WIDTH => BUS_LEN_WIDTH,
    SLAVE_MAX_BURST => BUS_BURST_MAX_LEN,
    ENABLE_FIFO => false
  )
  PORT MAP(
    clk => bcd_clk,
    reset_n => bcd_reset_n,
    slv_bus_rreq_addr => bus_rreq_addr,
    slv_bus_rreq_len => bus_rreq_len,
    slv_bus_rreq_valid => bus_rreq_valid,
    slv_bus_rreq_ready => bus_rreq_ready,
    slv_bus_rdat_data => bus_rdat_data,
    slv_bus_rdat_last => bus_rdat_last,
    slv_bus_rdat_valid => bus_rdat_valid,
    slv_bus_rdat_ready => bus_rdat_ready,
    m_axi_araddr => m_axi_araddr,
    m_axi_arlen => m_axi_arlen,
    m_axi_arvalid => m_axi_arvalid,
    m_axi_arready => m_axi_arready,
    m_axi_arsize => m_axi_arsize,
    m_axi_rdata => m_axi_rdata,
    m_axi_rlast => m_axi_rlast,
    m_axi_rvalid => m_axi_rvalid,
    m_axi_rready => m_axi_rready
  );

  -----------------------------------------------------------------------------
  -- AXI write converter
  -----------------------------------------------------------------------------
  -- Buffering bursts is disabled (ENABLE_FIFO=false) because BufferWriters
  -- are already able to absorb full bursts.
  axi_write_conv_inst : AxiWriteConverter
  GENERIC MAP(
    ADDR_WIDTH => BUS_ADDR_WIDTH,
    MASTER_DATA_WIDTH => BUS_DATA_WIDTH,
    MASTER_LEN_WIDTH => BUS_LEN_WIDTH,
    SLAVE_DATA_WIDTH => BUS_DATA_WIDTH,
    SLAVE_LEN_WIDTH => BUS_LEN_WIDTH,
    SLAVE_MAX_BURST => BUS_BURST_MAX_LEN,
    ENABLE_FIFO => false
  )
  PORT MAP(
    clk => bcd_clk,
    reset_n => bcd_reset_n,
    slv_bus_wreq_addr => bus_wreq_addr,
    slv_bus_wreq_len => bus_wreq_len,
    slv_bus_wreq_last => bus_wreq_last,
    slv_bus_wreq_valid => bus_wreq_valid,
    slv_bus_wreq_ready => bus_wreq_ready,
    slv_bus_wdat_data => bus_wdat_data,
    slv_bus_wdat_strobe => bus_wdat_strobe,
    slv_bus_wdat_last => bus_wdat_last,
    slv_bus_wdat_valid => bus_wdat_valid,
    slv_bus_wdat_ready => bus_wdat_ready,
    slv_bus_wrep_valid => slv_bus_wrep_valid,
    slv_bus_wrep_ready => slv_bus_wrep_ready,
    slv_bus_wrep_ok => slv_bus_wrep_ok,
    m_axi_awaddr => m_axi_awaddr,
    m_axi_awlen => m_axi_awlen,
    m_axi_awvalid => m_axi_awvalid,
    m_axi_awready => m_axi_awready,
    m_axi_awsize => m_axi_awsize,
    m_axi_wdata => m_axi_wdata,
    m_axi_wstrb => m_axi_wstrb,
    m_axi_wlast => m_axi_wlast,
    m_axi_wvalid => m_axi_wvalid,
    m_axi_wready => m_axi_wready,
    m_axi_bvalid => m_axi_bvalid,
    m_axi_bready => m_axi_bready,
    m_axi_bresp => m_axi_bresp
  );

  -----------------------------------------------------------------------------
  -- AXI MMIO
  -----------------------------------------------------------------------------
  axi_mmio_inst : AxiMmio
  GENERIC MAP(
    BUS_ADDR_WIDTH => MMIO_ADDR_WIDTH,
    BUS_DATA_WIDTH => MMIO_DATA_WIDTH,
    NUM_REGS => NUM_REGS
  )
  PORT MAP(
    clk => bcd_clk,
    reset_n => bcd_reset_n,
    s_axi_awvalid => s_axi_awvalid,
    s_axi_awready => s_axi_awready,
    s_axi_awaddr => s_axi_awaddr,
    s_axi_wvalid => s_axi_wvalid,
    s_axi_wready => s_axi_wready,
    s_axi_wdata => s_axi_wdata,
    s_axi_wstrb => s_axi_wstrb,
    s_axi_bvalid => s_axi_bvalid,
    s_axi_bready => s_axi_bready,
    s_axi_bresp => s_axi_bresp,
    s_axi_arvalid => s_axi_arvalid,
    s_axi_arready => s_axi_arready,
    s_axi_araddr => s_axi_araddr,
    s_axi_rvalid => s_axi_rvalid,
    s_axi_rready => s_axi_rready,
    s_axi_rdata => s_axi_rdata,
    s_axi_rresp => s_axi_rresp,
    regs_out => regs_in,
    regs_in => regs_out,
    regs_in_en => regs_out_en
  );

END ARCHITECTURE;