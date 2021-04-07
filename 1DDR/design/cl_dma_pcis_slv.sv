// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

module cl_dma_pcis_slv #()

(
    input aclk,
    input aresetn,

    axi_bus_t.master sh_cl_dma_pcis_bus,
    axi_bus_t.master cl_axi_mstr_bus,
    axi_bus_t sh_cl_dma_pcis_q,

    axi_bus_t.slave cl_sh_ddr_bus


);

//----------------------------
// Internal signals
//----------------------------
axi_bus_t cl_sh_ddr_q();
axi_bus_t sh_cl_pcis();

//----------------------------
// End Internal signals
//----------------------------


//reset synchronizers
(* dont_touch = "true" *) logic slr0_sync_aresetn;
(* dont_touch = "true" *) logic slr1_sync_aresetn;
(* dont_touch = "true" *) logic slr2_sync_aresetn;
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR0_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr0_sync_aresetn));
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR1_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr1_sync_aresetn));
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR2_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr2_sync_aresetn));

//----------------------------
// flop the dma_pcis interface input of CL
//----------------------------

   // AXI4 Register Slice for dma_pcis interface
   axi_register_slice PCI_AXL_REG_SLC (
       .aclk          (aclk),
       .aresetn       (slr0_sync_aresetn),
       .s_axi_awid    (sh_cl_dma_pcis_bus.awid),
       .s_axi_awaddr  (sh_cl_dma_pcis_bus.awaddr),
       .s_axi_awlen   (sh_cl_dma_pcis_bus.awlen),
       .s_axi_awvalid (sh_cl_dma_pcis_bus.awvalid),
       .s_axi_awsize  (sh_cl_dma_pcis_bus.awsize),
       .s_axi_awready (sh_cl_dma_pcis_bus.awready),
       .s_axi_wdata   (sh_cl_dma_pcis_bus.wdata),
       .s_axi_wstrb   (sh_cl_dma_pcis_bus.wstrb),
       .s_axi_wlast   (sh_cl_dma_pcis_bus.wlast),
       .s_axi_wvalid  (sh_cl_dma_pcis_bus.wvalid),
       .s_axi_wready  (sh_cl_dma_pcis_bus.wready),
       .s_axi_bid     (sh_cl_dma_pcis_bus.bid),
       .s_axi_bresp   (sh_cl_dma_pcis_bus.bresp),
       .s_axi_bvalid  (sh_cl_dma_pcis_bus.bvalid),
       .s_axi_bready  (sh_cl_dma_pcis_bus.bready),
       .s_axi_arid    (sh_cl_dma_pcis_bus.arid),
       .s_axi_araddr  (sh_cl_dma_pcis_bus.araddr),
       .s_axi_arlen   (sh_cl_dma_pcis_bus.arlen),
       .s_axi_arvalid (sh_cl_dma_pcis_bus.arvalid),
       .s_axi_arsize  (sh_cl_dma_pcis_bus.arsize),
       .s_axi_arready (sh_cl_dma_pcis_bus.arready),
       .s_axi_rid     (sh_cl_dma_pcis_bus.rid),
       .s_axi_rdata   (sh_cl_dma_pcis_bus.rdata),
       .s_axi_rresp   (sh_cl_dma_pcis_bus.rresp),
       .s_axi_rlast   (sh_cl_dma_pcis_bus.rlast),
       .s_axi_rvalid  (sh_cl_dma_pcis_bus.rvalid),
       .s_axi_rready  (sh_cl_dma_pcis_bus.rready),

       .m_axi_awid    (sh_cl_dma_pcis_q.awid),
       .m_axi_awaddr  (sh_cl_dma_pcis_q.awaddr),
       .m_axi_awlen   (sh_cl_dma_pcis_q.awlen),
       .m_axi_awvalid (sh_cl_dma_pcis_q.awvalid),
       .m_axi_awsize  (sh_cl_dma_pcis_q.awsize),
       .m_axi_awready (sh_cl_dma_pcis_q.awready),
       .m_axi_wdata   (sh_cl_dma_pcis_q.wdata),
       .m_axi_wstrb   (sh_cl_dma_pcis_q.wstrb),
       .m_axi_wvalid  (sh_cl_dma_pcis_q.wvalid),
       .m_axi_wlast   (sh_cl_dma_pcis_q.wlast),
       .m_axi_wready  (sh_cl_dma_pcis_q.wready),
       .m_axi_bresp   (sh_cl_dma_pcis_q.bresp),
       .m_axi_bvalid  (sh_cl_dma_pcis_q.bvalid),
       .m_axi_bid     (sh_cl_dma_pcis_q.bid),
       .m_axi_bready  (sh_cl_dma_pcis_q.bready),
       .m_axi_arid    (sh_cl_dma_pcis_q.arid),
       .m_axi_araddr  (sh_cl_dma_pcis_q.araddr),
       .m_axi_arlen   (sh_cl_dma_pcis_q.arlen),
       .m_axi_arsize  (sh_cl_dma_pcis_q.arsize),
       .m_axi_arvalid (sh_cl_dma_pcis_q.arvalid),
       .m_axi_arready (sh_cl_dma_pcis_q.arready),
       .m_axi_rid     (sh_cl_dma_pcis_q.rid),
       .m_axi_rdata   (sh_cl_dma_pcis_q.rdata),
       .m_axi_rresp   (sh_cl_dma_pcis_q.rresp),
       .m_axi_rlast   (sh_cl_dma_pcis_q.rlast),
       .m_axi_rvalid  (sh_cl_dma_pcis_q.rvalid),
       .m_axi_rready  (sh_cl_dma_pcis_q.rready)
   );

//-----------------------------------------------------
//TIE-OFF unused signals to prevent critical warnings
//-----------------------------------------------------
   assign sh_cl_dma_pcis_q.rid[15:6] = 10'b0 ;
   assign sh_cl_dma_pcis_q.bid[15:6] = 10'b0 ;

//----------------------------
// axi interconnect for DDR address decodes
//----------------------------
(* dont_touch = "true" *) cl_axi_interconnect AXI_CROSSBAR
       (.ACLK(aclk),
        .ARESETN(slr1_sync_aresetn),

        .M00_AXI_araddr(cl_sh_ddr_q.araddr),
        .M00_AXI_arburst(),
        .M00_AXI_arcache(),
        .M00_AXI_arid(cl_sh_ddr_q.arid[6:0]),
        .M00_AXI_arlen(cl_sh_ddr_q.arlen),
        .M00_AXI_arlock(),
        .M00_AXI_arprot(),
        .M00_AXI_arqos(),
        .M00_AXI_arready(cl_sh_ddr_q.arready),
        .M00_AXI_arregion(),
        .M00_AXI_arsize(cl_sh_ddr_q.arsize),
        .M00_AXI_arvalid(cl_sh_ddr_q.arvalid),
        .M00_AXI_awaddr(cl_sh_ddr_q.awaddr),
        .M00_AXI_awburst(),
        .M00_AXI_awcache(),
        .M00_AXI_awid(cl_sh_ddr_q.awid[6:0]),
        .M00_AXI_awlen(cl_sh_ddr_q.awlen),
        .M00_AXI_awlock(),
        .M00_AXI_awprot(),
        .M00_AXI_awqos(),
        .M00_AXI_awready(cl_sh_ddr_q.awready),
        .M00_AXI_awregion(),
        .M00_AXI_awsize(cl_sh_ddr_q.awsize),
        .M00_AXI_awvalid(cl_sh_ddr_q.awvalid),
        .M00_AXI_bid(cl_sh_ddr_q.bid[6:0]),
        .M00_AXI_bready(cl_sh_ddr_q.bready),
        .M00_AXI_bresp(cl_sh_ddr_q.bresp),
        .M00_AXI_bvalid(cl_sh_ddr_q.bvalid),
        .M00_AXI_rdata(cl_sh_ddr_q.rdata),
        .M00_AXI_rid(cl_sh_ddr_q.rid[6:0]),
        .M00_AXI_rlast(cl_sh_ddr_q.rlast),
        .M00_AXI_rready(cl_sh_ddr_q.rready),
        .M00_AXI_rresp(cl_sh_ddr_q.rresp),
        .M00_AXI_rvalid(cl_sh_ddr_q.rvalid),
        .M00_AXI_wdata(cl_sh_ddr_q.wdata),
        .M00_AXI_wlast(cl_sh_ddr_q.wlast),
        .M00_AXI_wready(cl_sh_ddr_q.wready),
        .M00_AXI_wstrb(cl_sh_ddr_q.wstrb),
        .M00_AXI_wvalid(cl_sh_ddr_q.wvalid),

        .S00_AXI_araddr({sh_cl_dma_pcis_q.araddr[63:37], 1'b0, sh_cl_dma_pcis_q.araddr[35:0]}),
        .S00_AXI_arburst(2'b1),
        .S00_AXI_arcache(4'b11),
        .S00_AXI_arid(sh_cl_dma_pcis_q.arid[5:0]),
        .S00_AXI_arlen(sh_cl_dma_pcis_q.arlen),
        .S00_AXI_arlock(1'b0),
        .S00_AXI_arprot(3'b10),
        .S00_AXI_arqos(4'b0),
        .S00_AXI_arready(sh_cl_dma_pcis_q.arready),
        .S00_AXI_arregion(4'b0),
        .S00_AXI_arsize(sh_cl_dma_pcis_q.arsize),
        .S00_AXI_arvalid(sh_cl_dma_pcis_q.arvalid),
        .S00_AXI_awaddr({sh_cl_dma_pcis_q.awaddr[63:37], 1'b0, sh_cl_dma_pcis_q.awaddr[35:0]}),
        .S00_AXI_awburst(2'b1),
        .S00_AXI_awcache(4'b11),
        .S00_AXI_awid(sh_cl_dma_pcis_q.awid[5:0]),
        .S00_AXI_awlen(sh_cl_dma_pcis_q.awlen),
        .S00_AXI_awlock(1'b0),
        .S00_AXI_awprot(3'b10),
        .S00_AXI_awqos(4'b0),
        .S00_AXI_awready(sh_cl_dma_pcis_q.awready),
        .S00_AXI_awregion(4'b0),
        .S00_AXI_awsize(sh_cl_dma_pcis_q.awsize),
        .S00_AXI_awvalid(sh_cl_dma_pcis_q.awvalid),
        .S00_AXI_bid(sh_cl_dma_pcis_q.bid[5:0]),
        .S00_AXI_bready(sh_cl_dma_pcis_q.bready),
        .S00_AXI_bresp(sh_cl_dma_pcis_q.bresp),
        .S00_AXI_bvalid(sh_cl_dma_pcis_q.bvalid),
        .S00_AXI_rdata(sh_cl_dma_pcis_q.rdata),
        .S00_AXI_rid(sh_cl_dma_pcis_q.rid[5:0]),
        .S00_AXI_rlast(sh_cl_dma_pcis_q.rlast),
        .S00_AXI_rready(sh_cl_dma_pcis_q.rready),
        .S00_AXI_rresp(sh_cl_dma_pcis_q.rresp),
        .S00_AXI_rvalid(sh_cl_dma_pcis_q.rvalid),
        .S00_AXI_wdata(sh_cl_dma_pcis_q.wdata),
        .S00_AXI_wlast(sh_cl_dma_pcis_q.wlast),
        .S00_AXI_wready(sh_cl_dma_pcis_q.wready),
        .S00_AXI_wstrb(sh_cl_dma_pcis_q.wstrb),
        .S00_AXI_wvalid(sh_cl_dma_pcis_q.wvalid),

        .S01_AXI_araddr({cl_axi_mstr_bus.araddr[63:37], 1'b0, cl_axi_mstr_bus.araddr[35:0]}),
        .S01_AXI_arburst(2'b1),
        .S01_AXI_arcache(4'b11),
        .S01_AXI_arid(cl_axi_mstr_bus.arid[5:0]),
        .S01_AXI_arlen(cl_axi_mstr_bus.arlen),
        .S01_AXI_arlock(1'b0),
        .S01_AXI_arprot(3'b10),
        .S01_AXI_arqos(4'b0),
        .S01_AXI_arready(cl_axi_mstr_bus.arready),
        .S01_AXI_arregion(4'b0),
        .S01_AXI_arsize(cl_axi_mstr_bus.arsize),
        .S01_AXI_arvalid(cl_axi_mstr_bus.arvalid),
        .S01_AXI_awaddr({cl_axi_mstr_bus.awaddr[63:37], 1'b0, cl_axi_mstr_bus.awaddr[35:0]}),
        .S01_AXI_awburst(2'b1),
        .S01_AXI_awcache(4'b11),
        .S01_AXI_awid(cl_axi_mstr_bus.awid[5:0]),
        .S01_AXI_awlen(cl_axi_mstr_bus.awlen),
        .S01_AXI_awlock(1'b0),
        .S01_AXI_awprot(3'b10),
        .S01_AXI_awqos(4'b0),
        .S01_AXI_awready(cl_axi_mstr_bus.awready),
        .S01_AXI_awregion(4'b0),
        .S01_AXI_awsize(cl_axi_mstr_bus.awsize),
        .S01_AXI_awvalid(cl_axi_mstr_bus.awvalid),
        .S01_AXI_bid(cl_axi_mstr_bus.bid[5:0]),
        .S01_AXI_bready(cl_axi_mstr_bus.bready),
        .S01_AXI_bresp(cl_axi_mstr_bus.bresp),
        .S01_AXI_bvalid(cl_axi_mstr_bus.bvalid),
        .S01_AXI_rdata(cl_axi_mstr_bus.rdata),
        .S01_AXI_rid(cl_axi_mstr_bus.rid[5:0]),
        .S01_AXI_rlast(cl_axi_mstr_bus.rlast),
        .S01_AXI_rready(cl_axi_mstr_bus.rready),
        .S01_AXI_rresp(cl_axi_mstr_bus.rresp),
        .S01_AXI_rvalid(cl_axi_mstr_bus.rvalid),
        .S01_AXI_wdata(cl_axi_mstr_bus.wdata),
        .S01_AXI_wlast(cl_axi_mstr_bus.wlast),
        .S01_AXI_wready(cl_axi_mstr_bus.wready),
        .S01_AXI_wstrb(cl_axi_mstr_bus.wstrb),
        .S01_AXI_wvalid(cl_axi_mstr_bus.wvalid));

//----------------------------
// flop the output of interconnect for DDRC
//----------------------------
   axi_register_slice DDR_C_TST_AXI4_REG_SLC (
       .aclk           (aclk),
       .aresetn        (slr1_sync_aresetn),

       .s_axi_awid     (cl_sh_ddr_q.awid),
       .s_axi_awaddr   ({cl_sh_ddr_q.awaddr[63:36], 2'b0, cl_sh_ddr_q.awaddr[33:0]}),
       .s_axi_awlen    (cl_sh_ddr_q.awlen),
       .s_axi_awsize   (cl_sh_ddr_q.awsize),
       .s_axi_awvalid  (cl_sh_ddr_q.awvalid),
       .s_axi_awready  (cl_sh_ddr_q.awready),
       .s_axi_wdata    (cl_sh_ddr_q.wdata),
       .s_axi_wstrb    (cl_sh_ddr_q.wstrb),
       .s_axi_wlast    (cl_sh_ddr_q.wlast),
       .s_axi_wvalid   (cl_sh_ddr_q.wvalid),
       .s_axi_wready   (cl_sh_ddr_q.wready),
       .s_axi_bid      (cl_sh_ddr_q.bid),
       .s_axi_bresp    (cl_sh_ddr_q.bresp),
       .s_axi_bvalid   (cl_sh_ddr_q.bvalid),
       .s_axi_bready   (cl_sh_ddr_q.bready),
       .s_axi_arid     (cl_sh_ddr_q.arid),
       .s_axi_araddr   ({cl_sh_ddr_q.araddr[63:36], 2'b0, cl_sh_ddr_q.araddr[33:0]}),
       .s_axi_arlen    (cl_sh_ddr_q.arlen),
       .s_axi_arsize   (cl_sh_ddr_q.arsize),
       .s_axi_arvalid  (cl_sh_ddr_q.arvalid),
       .s_axi_arready  (cl_sh_ddr_q.arready),
       .s_axi_rid      (cl_sh_ddr_q.rid),
       .s_axi_rdata    (cl_sh_ddr_q.rdata),
       .s_axi_rresp    (cl_sh_ddr_q.rresp),
       .s_axi_rlast    (cl_sh_ddr_q.rlast),
       .s_axi_rvalid   (cl_sh_ddr_q.rvalid),
       .s_axi_rready   (cl_sh_ddr_q.rready),
       .m_axi_awid     (cl_sh_ddr_bus.awid),
       .m_axi_awaddr   (cl_sh_ddr_bus.awaddr),
       .m_axi_awlen    (cl_sh_ddr_bus.awlen),
       .m_axi_awsize   (cl_sh_ddr_bus.awsize),
       .m_axi_awvalid  (cl_sh_ddr_bus.awvalid),
       .m_axi_awready  (cl_sh_ddr_bus.awready),
       .m_axi_wdata    (cl_sh_ddr_bus.wdata),
       .m_axi_wstrb    (cl_sh_ddr_bus.wstrb),
       .m_axi_wlast    (cl_sh_ddr_bus.wlast),
       .m_axi_wvalid   (cl_sh_ddr_bus.wvalid),
       .m_axi_wready   (cl_sh_ddr_bus.wready),
       .m_axi_bid      (cl_sh_ddr_bus.bid),
       .m_axi_bresp    (cl_sh_ddr_bus.bresp),
       .m_axi_bvalid   (cl_sh_ddr_bus.bvalid),
       .m_axi_bready   (cl_sh_ddr_bus.bready),
       .m_axi_arid     (cl_sh_ddr_bus.arid),
       .m_axi_araddr   (cl_sh_ddr_bus.araddr),
       .m_axi_arlen    (cl_sh_ddr_bus.arlen),
       .m_axi_arsize   (cl_sh_ddr_bus.arsize),
       .m_axi_arvalid  (cl_sh_ddr_bus.arvalid),
       .m_axi_arready  (cl_sh_ddr_bus.arready),
       .m_axi_rid      (cl_sh_ddr_bus.rid),
       .m_axi_rdata    (cl_sh_ddr_bus.rdata),
       .m_axi_rresp    (cl_sh_ddr_bus.rresp),
       .m_axi_rlast    (cl_sh_ddr_bus.rlast),
       .m_axi_rvalid   (cl_sh_ddr_bus.rvalid),
       .m_axi_rready   (cl_sh_ddr_bus.rready)
   );



endmodule

