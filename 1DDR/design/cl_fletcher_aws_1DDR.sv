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


`define FLETCHER_TOP AxiTop

module cl_fletcher_aws_1DDR #(parameter NUM_DDR=1) 

(
   `include "cl_ports.vh"

);

`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "cl_dram_dma_defines.vh"

// TIE OFF ALL UNUSED INTERFACES
// Including all the unused interface to tie off
// This list is put in the top of the fie to remind
// developers to remve the specific interfaces
// that the CL will use

`include "unused_flr_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_pcim_template.inc"
`include "unused_apppf_irq_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_ocl_template.inc"


//---------------------------- 
// Internal signals
//---------------------------- 
axi_bus_t axi_bus_tied();

axi_bus_t sh_cl_dma_pcis_bus();
axi_bus_t sh_cl_dma_pcis_q();

axi_bus_t cl_sh_ddr_bus();

axi_bus_t sh_bar1_bus();
axi_bus_t cl_axi_slv_bus();
axi_bus_t cl_axi_mstr_bus();

logic clk;
(* dont_touch = "true" *) logic pipe_rst_n;
logic pre_sync_rst_n;
(* dont_touch = "true" *) logic sync_rst_n;

//---------------------------- 
// End Internal signals
//----------------------------

// Unused 'full' signals
assign cl_sh_dma_rd_full  = 1'b0;
assign cl_sh_dma_wr_full  = 1'b0;

// Unused *burst signals
assign cl_sh_ddr_arburst[1:0] = 2'h0;
assign cl_sh_ddr_awburst[1:0] = 2'h0;


assign clk = clk_main_a0;

assign cl_sh_id0 = `CL_SH_ID0;
assign cl_sh_id1 = `CL_SH_ID1;


//reset synchronizer
lib_pipe #(.WIDTH(1), .STAGES(4)) PIPE_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(rst_main_n), .out_bus(pipe_rst_n));
   
always_ff @(negedge pipe_rst_n or posedge clk)
   if (!pipe_rst_n)
   begin
      pre_sync_rst_n <= 0;
      sync_rst_n <= 0;
   end
   else
   begin
      pre_sync_rst_n <= 1;
      sync_rst_n <= pre_sync_rst_n;
   end

///////////////////////////////////////////////////////////////////////
///////////////// DMA PCIS SLAVE module ///////////////////////////////
///////////////////////////////////////////////////////////////////////
 
assign sh_cl_dma_pcis_bus.awvalid = sh_cl_dma_pcis_awvalid;
assign sh_cl_dma_pcis_bus.awaddr = sh_cl_dma_pcis_awaddr;
assign sh_cl_dma_pcis_bus.awid[5:0] = sh_cl_dma_pcis_awid;
assign sh_cl_dma_pcis_bus.awlen = sh_cl_dma_pcis_awlen;
assign sh_cl_dma_pcis_bus.awsize = sh_cl_dma_pcis_awsize;
assign cl_sh_dma_pcis_awready = sh_cl_dma_pcis_bus.awready;
assign sh_cl_dma_pcis_bus.wvalid = sh_cl_dma_pcis_wvalid;
assign sh_cl_dma_pcis_bus.wdata = sh_cl_dma_pcis_wdata;
assign sh_cl_dma_pcis_bus.wstrb = sh_cl_dma_pcis_wstrb;
assign sh_cl_dma_pcis_bus.wlast = sh_cl_dma_pcis_wlast;
assign cl_sh_dma_pcis_wready = sh_cl_dma_pcis_bus.wready;
assign cl_sh_dma_pcis_bvalid = sh_cl_dma_pcis_bus.bvalid;
assign cl_sh_dma_pcis_bresp = sh_cl_dma_pcis_bus.bresp;
assign sh_cl_dma_pcis_bus.bready = sh_cl_dma_pcis_bready;
assign cl_sh_dma_pcis_bid = sh_cl_dma_pcis_bus.bid[5:0];
assign sh_cl_dma_pcis_bus.arvalid = sh_cl_dma_pcis_arvalid;
assign sh_cl_dma_pcis_bus.araddr = sh_cl_dma_pcis_araddr;
assign sh_cl_dma_pcis_bus.arid[5:0] = sh_cl_dma_pcis_arid;
assign sh_cl_dma_pcis_bus.arlen = sh_cl_dma_pcis_arlen;
assign sh_cl_dma_pcis_bus.arsize = sh_cl_dma_pcis_arsize;
assign cl_sh_dma_pcis_arready = sh_cl_dma_pcis_bus.arready;
assign cl_sh_dma_pcis_rvalid = sh_cl_dma_pcis_bus.rvalid;
assign cl_sh_dma_pcis_rid = sh_cl_dma_pcis_bus.rid[5:0];
assign cl_sh_dma_pcis_rlast = sh_cl_dma_pcis_bus.rlast;
assign cl_sh_dma_pcis_rresp = sh_cl_dma_pcis_bus.rresp;
assign cl_sh_dma_pcis_rdata = sh_cl_dma_pcis_bus.rdata;
assign sh_cl_dma_pcis_bus.rready = sh_cl_dma_pcis_rready;

assign cl_sh_ddr_awid = cl_sh_ddr_bus.awid;
assign cl_sh_ddr_awaddr = cl_sh_ddr_bus.awaddr;
assign cl_sh_ddr_awlen = cl_sh_ddr_bus.awlen;
assign cl_sh_ddr_awsize = cl_sh_ddr_bus.awsize;
assign cl_sh_ddr_awvalid = cl_sh_ddr_bus.awvalid;
assign cl_sh_ddr_bus.awready = sh_cl_ddr_awready;
assign cl_sh_ddr_wid = 16'b0;
assign cl_sh_ddr_wdata = cl_sh_ddr_bus.wdata;
assign cl_sh_ddr_wstrb = cl_sh_ddr_bus.wstrb;
assign cl_sh_ddr_wlast = cl_sh_ddr_bus.wlast;
assign cl_sh_ddr_wvalid = cl_sh_ddr_bus.wvalid;
assign cl_sh_ddr_bus.wready = sh_cl_ddr_wready;
assign cl_sh_ddr_bus.bid = sh_cl_ddr_bid;
assign cl_sh_ddr_bus.bresp = sh_cl_ddr_bresp;
assign cl_sh_ddr_bus.bvalid = sh_cl_ddr_bvalid;
assign cl_sh_ddr_bready = cl_sh_ddr_bus.bready;
assign cl_sh_ddr_arid = cl_sh_ddr_bus.arid;
assign cl_sh_ddr_araddr = cl_sh_ddr_bus.araddr;
assign cl_sh_ddr_arlen = cl_sh_ddr_bus.arlen;
assign cl_sh_ddr_arsize = cl_sh_ddr_bus.arsize;
assign cl_sh_ddr_arvalid = cl_sh_ddr_bus.arvalid;
assign cl_sh_ddr_bus.arready = sh_cl_ddr_arready;
assign cl_sh_ddr_bus.rid = sh_cl_ddr_rid;
assign cl_sh_ddr_bus.rresp = sh_cl_ddr_rresp;
assign cl_sh_ddr_bus.rvalid = sh_cl_ddr_rvalid;
assign cl_sh_ddr_bus.rdata = sh_cl_ddr_rdata;
assign cl_sh_ddr_bus.rlast = sh_cl_ddr_rlast;
assign cl_sh_ddr_rready = cl_sh_ddr_bus.rready;

(* dont_touch = "true" *) logic dma_pcis_slv_sync_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) DMA_PCIS_SLV_SLC_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(dma_pcis_slv_sync_rst_n));
cl_dma_pcis_slv #() CL_DMA_PCIS_SLV (
    .aclk(clk),
    .aresetn(dma_pcis_slv_sync_rst_n),

    .sh_cl_dma_pcis_bus(sh_cl_dma_pcis_bus),
    .cl_axi_mstr_bus(cl_axi_mstr_bus),

    .sh_cl_dma_pcis_q(sh_cl_dma_pcis_q),

    .cl_sh_ddr_bus     (cl_sh_ddr_bus)
  );

///////////////////////////////////////////////////////////////////////
///////////////// DMA PCIS SLAVE module ///////////////////////////////
///////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
///////////////// Secondary AXI Master module /////////////////////////
///////////////////////////////////////////////////////////////////////


//-----------------------------------------
// BAR 1 Connections -> sh_bar1
//-----------------------------------------
assign bar1_sh_awready = sh_bar1_bus.awready;
assign sh_bar1_bus.awvalid = sh_bar1_awvalid;
assign sh_bar1_bus.awaddr  = sh_bar1_awaddr ;

assign bar1_sh_wready  = sh_bar1_bus.wready ;
assign sh_bar1_bus.wvalid  = sh_bar1_wvalid ;
assign sh_bar1_bus.wdata   = sh_bar1_wdata  ;
assign sh_bar1_bus.wstrb   = sh_bar1_wstrb  ;

assign bar1_sh_bvalid  = sh_bar1_bus.bvalid ;
assign bar1_sh_bresp   = sh_bar1_bus.bresp  ;
assign sh_bar1_bus.bready  = sh_bar1_bready ;

assign bar1_sh_arready = sh_bar1_bus.arready;
assign sh_bar1_bus.arvalid = sh_bar1_arvalid;
assign sh_bar1_bus.araddr  = sh_bar1_araddr ;

assign bar1_sh_rvalid  = sh_bar1_bus.rvalid ;
assign bar1_sh_rdata   = sh_bar1_bus.rdata  ;
assign bar1_sh_rresp   = sh_bar1_bus.rresp  ;
assign sh_bar1_bus.rready  = sh_bar1_rready ;


//-----------------------------------------
// BAR1 Slice
//-----------------------------------------
axi_register_slice_light BAR1_SLICE (
  .aclk          (clk),
  .aresetn       (sync_rst_n),

  // Slave in
  .s_axi_awvalid (sh_bar1_bus.awvalid  ),
  .s_axi_awready (sh_bar1_bus.awready  ),
  .s_axi_awaddr  (sh_bar1_bus.awaddr   ),

  .s_axi_wvalid  (sh_bar1_bus.wvalid   ),
  .s_axi_wready  (sh_bar1_bus.wready   ),
  .s_axi_wdata   (sh_bar1_bus.wdata    ),
  .s_axi_wstrb   (sh_bar1_bus.wstrb    ),

  .s_axi_bvalid  (sh_bar1_bus.bvalid   ),
  .s_axi_bready  (sh_bar1_bus.bready   ),
  .s_axi_bresp   (sh_bar1_bus.bresp    ),

  .s_axi_arvalid (sh_bar1_bus.arvalid  ),
  .s_axi_arready (sh_bar1_bus.arready  ),
  .s_axi_araddr  (sh_bar1_bus.araddr   ),

  .s_axi_rvalid  (sh_bar1_bus.rvalid   ),
  .s_axi_rready  (sh_bar1_bus.rready   ),
  .s_axi_rdata   (sh_bar1_bus.rdata    ),
  .s_axi_rresp   (sh_bar1_bus.rresp    ),

  // Master out
  .m_axi_awaddr  (cl_axi_slv_bus.awaddr ),
  .m_axi_awvalid (cl_axi_slv_bus.awvalid),
  .m_axi_awready (cl_axi_slv_bus.awready),

  .m_axi_wdata   (cl_axi_slv_bus.wdata  ),
  .m_axi_wstrb   (cl_axi_slv_bus.wstrb  ),
  .m_axi_wvalid  (cl_axi_slv_bus.wvalid ),
  .m_axi_wready  (cl_axi_slv_bus.wready ),

  .m_axi_bresp   (cl_axi_slv_bus.bresp  ),
  .m_axi_bvalid  (cl_axi_slv_bus.bvalid ),
  .m_axi_bready  (cl_axi_slv_bus.bready ),

  .m_axi_araddr  (cl_axi_slv_bus.araddr ),
  .m_axi_arvalid (cl_axi_slv_bus.arvalid),
  .m_axi_arready (cl_axi_slv_bus.arready),

  .m_axi_rdata   (cl_axi_slv_bus.rdata  ),
  .m_axi_rresp   (cl_axi_slv_bus.rresp  ),
  .m_axi_rvalid  (cl_axi_slv_bus.rvalid ),
  .m_axi_rready  (cl_axi_slv_bus.rready )
);

`FLETCHER_TOP #() FLETCHER_TOP_INST (
   .kcd_clk(clk),
   .bcd_clk(clk),
   .kcd_reset(!dma_pcis_slv_sync_rst_n),
   .bcd_reset(!dma_pcis_slv_sync_rst_n),

   // Master interface
   .m_axi_arvalid(cl_axi_mstr_bus.arvalid),
   .m_axi_arready(cl_axi_mstr_bus.arready),
   .m_axi_araddr (cl_axi_mstr_bus.araddr ),
   .m_axi_arlen  (cl_axi_mstr_bus.arlen  ),
   .m_axi_arsize (cl_axi_mstr_bus.arsize ),

   .m_axi_rvalid (cl_axi_mstr_bus.rvalid ),
   .m_axi_rready (cl_axi_mstr_bus.rready ),
   .m_axi_rdata  (cl_axi_mstr_bus.rdata  ),
   .m_axi_rresp  (cl_axi_mstr_bus.rresp  ),
   .m_axi_rlast  (cl_axi_mstr_bus.rlast  ),

    // Write address channel
   .m_axi_awvalid(cl_axi_mstr_bus.awvalid),
   .m_axi_awready(cl_axi_mstr_bus.awready),
   .m_axi_awaddr (cl_axi_mstr_bus.awaddr),
   .m_axi_awlen  (cl_axi_mstr_bus.awlen),
   .m_axi_awsize (cl_axi_mstr_bus.awsize),

    // Write data channel
   .m_axi_wvalid (cl_axi_mstr_bus.wvalid),
   .m_axi_wready (cl_axi_mstr_bus.wready),
   .m_axi_wdata  (cl_axi_mstr_bus.wdata),
   .m_axi_wlast  (cl_axi_mstr_bus.wlast),
   .m_axi_wstrb  (cl_axi_mstr_bus.wstrb),

   // Slave interface
   .s_axi_awvalid(cl_axi_slv_bus.awvalid),
   .s_axi_awready(cl_axi_slv_bus.awready),
   .s_axi_awaddr (cl_axi_slv_bus.awaddr ),
   .s_axi_wvalid (cl_axi_slv_bus.wvalid ),
   .s_axi_wready (cl_axi_slv_bus.wready ),
   .s_axi_wdata  (cl_axi_slv_bus.wdata  ),
   .s_axi_wstrb  (cl_axi_slv_bus.wstrb  ),
   .s_axi_bvalid (cl_axi_slv_bus.bvalid ),
   .s_axi_bready (cl_axi_slv_bus.bready ),
   .s_axi_bresp  (cl_axi_slv_bus.bresp  ),
   .s_axi_arvalid(cl_axi_slv_bus.arvalid),
   .s_axi_arready(cl_axi_slv_bus.arready),
   .s_axi_araddr (cl_axi_slv_bus.araddr ),
   .s_axi_rvalid (cl_axi_slv_bus.rvalid ),
   .s_axi_rready (cl_axi_slv_bus.rready ),
   .s_axi_rdata  (cl_axi_slv_bus.rdata  ),
   .s_axi_rresp  (cl_axi_slv_bus.rresp  )
);

assign cl_axi_mstr_bus.bready = 1'b1;

///////////////////////////////////////////////////////////////////////
///////////////// Secondary AXI Master module /////////////////////////
///////////////////////////////////////////////////////////////////////



//----------------------------------------- 
// Virtual JTAG ILA Debug core example 
//-----------------------------------------


`ifndef DISABLE_VJTAG_DEBUG

   cl_ila CL_ILA   (

   .aclk(clk),
   .drck(drck),
   .shift(shift),
      .tdi(tdi),
   .update(update),
   .sel(sel),
   .tdo(tdo),
   .tms(tms),
   .tck(tck),
   .runtest(runtest),
   .reset(reset),
   .capture(capture),
   .bscanid_en(bscanid_en),
   .sh_cl_dma_pcis_q(sh_cl_dma_pcis_q)
);

cl_vio CL_VIO (

   .clk_extra_a1(clk_extra_a1)

);


`endif //  `ifndef DISABLE_VJTAG_DEBUG

//----------------------------------------- 
// Virtual JATG ILA Debug core example 
//-----------------------------------------
// tie off for ILA port when probing block not present
   assign axi_bus_tied.awvalid = 1'b0 ;
   assign axi_bus_tied.awaddr = 64'b0 ;
   assign axi_bus_tied.awready = 1'b0 ;
   assign axi_bus_tied.wvalid = 1'b0 ;
   assign axi_bus_tied.wstrb = 64'b0 ;
   assign axi_bus_tied.wlast = 1'b0 ;
   assign axi_bus_tied.wready = 1'b0 ;
   assign axi_bus_tied.wdata = 512'b0 ;
   assign axi_bus_tied.arready = 1'b0 ;
   assign axi_bus_tied.rdata = 512'b0 ;
   assign axi_bus_tied.araddr = 64'b0 ;
   assign axi_bus_tied.arvalid = 1'b0 ;
   assign axi_bus_tied.awid = 16'b0 ;
   assign axi_bus_tied.arid = 16'b0 ;
   assign axi_bus_tied.awlen = 8'b0 ;
   assign axi_bus_tied.rlast = 1'b0 ;
   assign axi_bus_tied.rresp = 2'b0 ;
   assign axi_bus_tied.rid = 16'b0 ;
   assign axi_bus_tied.rvalid = 1'b0 ;
   assign axi_bus_tied.arlen = 8'b0 ;
   assign axi_bus_tied.bresp = 2'b0 ;
   assign axi_bus_tied.rready = 1'b0 ;
   assign axi_bus_tied.bvalid = 1'b0 ;
   assign axi_bus_tied.bid = 16'b0 ;
   assign axi_bus_tied.bready = 1'b0 ;


endmodule   
