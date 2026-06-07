`timescale 1ns / 1ps

module bram_to_tot_calc_tb;

import axi_vip_pkg::*;
import axi_pkg::*;


// ----- AXI BFM -----
axi_master_t axi_master_calc = new();
axi_master_t axi_master_bram = new();
axi_master_t axi_master_mem = new();

// ----- Local parameters -----
localparam CLK_PERIOD = 10ns; // 100MHz
parameter SAMPLE_NUM_PER_CYCLE = 24;
parameter WIDTH = 32;
parameter FRAC = 8;
parameter ID = 32'h0000_CA7C;
parameter BRAM_BASE_ADDR = 32'hC000_0000;

// ----- Local variables -----
logic clk;
logic rst;
wire [31:0] bram_addr;
wire bram_arvalid;
logic [31:0] bram_rdata;
logic bram_rvalid;
logic bram_rready;
logic bram_arready;

// ----- Samples stream -----
wire [287:0] samples;
wire samples_valid;
wire samples_ready;

// ----- AXI signals -----

// ----- BRAM AXI -----
wire [BFM_AXI_VIP_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
wire [2 : 0] s00_axi_awprot;
wire s00_axi_awvalid;
wire s00_axi_awready;
wire [BFM_AXI_VIP_DATA_WIDTH-1 : 0] s00_axi_wdata;
wire [(BFM_AXI_VIP_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
wire s00_axi_wvalid;
wire s00_axi_wready;
wire [1 : 0] s00_axi_bresp;
wire s00_axi_bvalid;
wire s00_axi_bready;
wire [BFM_AXI_VIP_ADDR_WIDTH-1 : 0] s00_axi_araddr;
wire [2 : 0] s00_axi_arprot;
wire s00_axi_arvalid;
wire s00_axi_arready;
wire [BFM_AXI_VIP_DATA_WIDTH-1 : 0] s00_axi_rdata;
wire [1 : 0] s00_axi_rresp;
wire s00_axi_rvalid;
wire s00_axi_rready;

// ----- TOT_CALC AXI -----
wire [BFM_AXI_VIP_ADDR_WIDTH-1 : 0] s01_axi_awaddr;
wire [2 : 0] s01_axi_awprot;
wire s01_axi_awvalid;
wire s01_axi_awready;
wire [BFM_AXI_VIP_DATA_WIDTH-1 : 0] s01_axi_wdata;
wire [(BFM_AXI_VIP_DATA_WIDTH/8)-1 : 0] s01_axi_wstrb;
wire s01_axi_wvalid;
wire s01_axi_wready;
wire [1 : 0] s01_axi_bresp;
wire s01_axi_bvalid;
wire s01_axi_bready;
wire [BFM_AXI_VIP_ADDR_WIDTH-1 : 0] s01_axi_araddr;
wire [2 : 0] s01_axi_arprot;
wire s01_axi_arvalid;
wire s01_axi_arready;
wire [BFM_AXI_VIP_DATA_WIDTH-1 : 0] s01_axi_rdata;
wire [1 : 0] s01_axi_rresp;
wire s01_axi_rvalid;
wire s01_axi_rready;


wire [BFM_AXI_VIP_ADDR_WIDTH-1 : 0] s02_axi_awaddr;
wire [2 : 0] s02_axi_awprot;
wire s02_axi_awvalid;
wire s02_axi_awready;
wire [BFM_AXI_VIP_DATA_WIDTH-1 : 0] s02_axi_wdata;
wire [(BFM_AXI_VIP_DATA_WIDTH/8)-1 : 0] s02_axi_wstrb;
wire s02_axi_wvalid;
wire s02_axi_wready;
wire [1 : 0] s02_axi_bresp;
wire s02_axi_bvalid;
wire s02_axi_bready;
wire [5 : 0] s02_axi_araddr;
wire [2 : 0] s02_axi_arprot;
wire s02_axi_arvalid;
wire s02_axi_arready;
wire [BFM_AXI_VIP_DATA_WIDTH-1 : 0] s02_axi_rdata;
wire [1 : 0] s02_axi_rresp;
wire s02_axi_rvalid;
wire s02_axi_rready;
wire s02_axi_wlast;

initial begin
  clk = 1'b0;
  forever begin
    #(CLK_PERIOD/2) clk = ~clk;
  end
end


parameter C_S00_AXI_DATA_WIDTH = 32;
parameter C_S00_AXI_ADDR_WIDTH = 4;
parameter C_M00_AXI_START_DATA_VALUE = 32'hAA000000;
parameter C_M00_AXI_TARGET_SLAVE_BASE_ADDR = 32'h40000000;
parameter C_M00_AXI_ADDR_WIDTH = 32;
parameter C_M00_AXI_DATA_WIDTH = 32;
parameter C_M00_AXI_TRANSACTIONS_NUM = 4;


wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr;
wire [2 : 0] m00_axi_awprot;
wire m00_axi_awvalid;
wire m00_axi_awready;
wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata;
wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb;
wire m00_axi_wvalid;
wire m00_axi_wready;
wire [1 : 0] m00_axi_bresp;
wire m00_axi_bvalid;
wire m00_axi_bready;
wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr;
wire [2 : 0] m00_axi_arprot;
wire m00_axi_arvalid;
wire m00_axi_arready;
wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata;
wire [1 : 0] m00_axi_rresp;
wire m00_axi_rvalid;
wire m00_axi_rready;

adc_bram_simulator_v1_2 #(
  .C_S00_AXI_DATA_WIDTH            (C_S00_AXI_DATA_WIDTH),
  .C_S00_AXI_ADDR_WIDTH            (C_S00_AXI_ADDR_WIDTH),
  .C_M00_AXI_START_DATA_VALUE      (C_M00_AXI_START_DATA_VALUE),
  .C_M00_AXI_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
  .C_M00_AXI_ADDR_WIDTH            (C_M00_AXI_ADDR_WIDTH),
  .C_M00_AXI_DATA_WIDTH            (C_M00_AXI_DATA_WIDTH),
  .C_M00_AXI_TRANSACTIONS_NUM      (C_M00_AXI_TRANSACTIONS_NUM)
)
u_adc_bram_simulator_v1_2 (
  // Ports of Axi Master Bus Interface M00_AXI
  .m00_axi_aclk        (clk),
  .m00_axi_aresetn     (!rst),
  .m00_axi_araddr      (m00_axi_araddr),
  .m00_axi_arprot      (m00_axi_arprot),
  .m00_axi_arready     (m00_axi_arready),
  .m00_axi_arvalid     (m00_axi_arvalid),
  .m00_axi_awaddr      (m00_axi_awaddr),
  .m00_axi_awprot      (m00_axi_awprot),
  .m00_axi_awready     (m00_axi_awready),
  .m00_axi_awvalid     (m00_axi_awvalid),
  .m00_axi_bready      (m00_axi_bready),
  .m00_axi_bresp       (m00_axi_bresp),
  .m00_axi_bvalid      (m00_axi_bvalid),
  .m00_axi_error       (m00_axi_error),
  .m00_axi_init_axi_txn(m00_axi_init_axi_txn),
  .m00_axi_rdata       (m00_axi_rdata),
  .m00_axi_rready      (m00_axi_rready),
  .m00_axi_rresp       (m00_axi_rresp),
  .m00_axi_rvalid      (m00_axi_rvalid),
  .m00_axi_txn_done    (m00_axi_txn_done),
  .m00_axi_wdata       (m00_axi_wdata),
  .m00_axi_wready      (m00_axi_wready),
  .m00_axi_wstrb       (m00_axi_wstrb),
  .m00_axi_wvalid      (m00_axi_wvalid),

  // Ports of Axi Slave Bus Interface S00_AXI
  .s00_axi_aclk        (clk),
  .s00_axi_aresetn     (!rst),
  .s00_axi_araddr      (s00_axi_araddr),
  .s00_axi_arprot      (s00_axi_arprot),
  .s00_axi_arready     (s00_axi_arready),
  .s00_axi_arvalid     (s00_axi_arvalid),
  .s00_axi_awaddr      (s00_axi_awaddr),
  .s00_axi_awprot      (s00_axi_awprot),
  .s00_axi_awready     (s00_axi_awready),
  .s00_axi_awvalid     (s00_axi_awvalid),
  .s00_axi_bready      (s00_axi_bready),
  .s00_axi_bresp       (s00_axi_bresp),
  .s00_axi_bvalid      (s00_axi_bvalid),
  .s00_axi_rdata       (s00_axi_rdata),
  .s00_axi_rready      (s00_axi_rready),
  .s00_axi_rresp       (s00_axi_rresp),
  .s00_axi_rvalid      (s00_axi_rvalid),
  .s00_axi_wdata       (s00_axi_wdata),
  .s00_axi_wready      (s00_axi_wready),
  .s00_axi_wstrb       (s00_axi_wstrb),
  .s00_axi_wvalid      (s00_axi_wvalid),
  // Sample stream
  .samples             (samples),
  .samples_ready       (samples_ready),
  .samples_valid       (samples_valid)
);

tot_calculator_v1_5 #(
  .SAMPLE_NUM_PER_CYCLE(SAMPLE_NUM_PER_CYCLE),
  .WIDTH               (WIDTH),
  .FRAC                (FRAC),
  .ID                  (ID),
  .C_S00_AXI_DATA_WIDTH(BFM_AXI_VIP_DATA_WIDTH),
  .C_S00_AXI_ADDR_WIDTH(BFM_AXI_VIP_ADDR_WIDTH)
)
u_tot_calculator_v1_5 (
  .s00_axi_aclk   (clk),
  .s00_axi_aresetn(~rst),
  .s00_axi_araddr (s01_axi_araddr),
  .s00_axi_arprot (s01_axi_arprot),
  .s00_axi_arready(s01_axi_arready),
  .s00_axi_arvalid(s01_axi_arvalid),
  .s00_axi_awaddr (s01_axi_awaddr),
  .s00_axi_awprot (s01_axi_awprot),
  .s00_axi_awready(s01_axi_awready),
  .s00_axi_awvalid(s01_axi_awvalid),
  .s00_axi_bready (s01_axi_bready),
  .s00_axi_bresp  (s01_axi_bresp),
  .s00_axi_bvalid (s01_axi_bvalid),
  .s00_axi_rdata  (s01_axi_rdata),
  .s00_axi_rready (s01_axi_rready),
  .s00_axi_rresp  (s01_axi_rresp),
  .s00_axi_rvalid (s01_axi_rvalid),
  .s00_axi_wdata  (s01_axi_wdata),
  .s00_axi_wready (s01_axi_wready),
  .s00_axi_wstrb  (s01_axi_wstrb),
  .s00_axi_wvalid (s01_axi_wvalid),
  // ToT calculator ports
  .sample         (samples),
  .sample_ready   (samples_ready),
  .sample_valid   (samples_valid)
);


axi_vip_v1_1_14_top #(
  .C_AXI_PROTOCOL       (BFM_AXI_VIP_PROTOCOL),
  .C_AXI_INTERFACE_MODE (BFM_AXI_VIP_INTERFACE_MODE),
  .C_AXI_ADDR_WIDTH     (BFM_AXI_VIP_ADDR_WIDTH),
  .C_AXI_WDATA_WIDTH    (BFM_AXI_VIP_DATA_WIDTH),
  .C_AXI_RDATA_WIDTH    (BFM_AXI_VIP_DATA_WIDTH),
  .C_AXI_WID_WIDTH      (BFM_AXI_VIP_ID_WIDTH),
  .C_AXI_RID_WIDTH      (BFM_AXI_VIP_ID_WIDTH),
  .C_AXI_AWUSER_WIDTH   (BFM_AXI_VIP_AWUSER_WIDTH),
  .C_AXI_ARUSER_WIDTH   (BFM_AXI_VIP_ARUSER_WIDTH),
  .C_AXI_WUSER_WIDTH    (BFM_AXI_VIP_WUSER_WIDTH),
  .C_AXI_RUSER_WIDTH    (BFM_AXI_VIP_RUSER_WIDTH),
  .C_AXI_BUSER_WIDTH    (BFM_AXI_VIP_BUSER_WIDTH),
  .C_AXI_SUPPORTS_NARROW(BFM_AXI_VIP_SUPPORTS_NARROW),
  .C_AXI_HAS_BURST      (BFM_AXI_VIP_HAS_BURST),
  .C_AXI_HAS_LOCK       (BFM_AXI_VIP_HAS_LOCK),
  .C_AXI_HAS_CACHE      (BFM_AXI_VIP_HAS_CACHE),
  .C_AXI_HAS_REGION     (BFM_AXI_VIP_HAS_REGION),
  .C_AXI_HAS_PROT       (BFM_AXI_VIP_HAS_PROT),
  .C_AXI_HAS_QOS        (BFM_AXI_VIP_HAS_QOS),
  .C_AXI_HAS_WSTRB      (BFM_AXI_VIP_HAS_WSTRB),
  .C_AXI_HAS_BRESP      (BFM_AXI_VIP_HAS_BRESP),
  .C_AXI_HAS_RRESP      (BFM_AXI_VIP_HAS_RRESP),
  .C_AXI_HAS_ARESETN    (BFM_AXI_VIP_HAS_ARESETN)
) BRAM_AXI (
  .aclk          (clk),
  .aclken        (1'b1),
  .aresetn       (~rst),
  .s_axi_awid    (),
  .s_axi_awaddr  (),
  .s_axi_awlen   (),
  .s_axi_awsize  (),
  .s_axi_awburst (),
  .s_axi_awlock  (),
  .s_axi_awcache (),
  .s_axi_awprot  (),
  .s_axi_awregion(),
  .s_axi_awqos   (),
  .s_axi_awuser  (),
  .s_axi_awvalid (),
  .s_axi_awready (),
  .s_axi_wid     (),
  .s_axi_wdata   (),
  .s_axi_wstrb   (),
  .s_axi_wlast   (),
  .s_axi_wuser   (),
  .s_axi_wvalid  (),
  .s_axi_wready  (),
  .s_axi_bid     (),
  .s_axi_bresp   (),
  .s_axi_buser   (),
  .s_axi_bvalid  (),
  .s_axi_bready  (),
  .s_axi_arid    (),
  .s_axi_araddr  (),
  .s_axi_arlen   (),
  .s_axi_arsize  (),
  .s_axi_arburst (),
  .s_axi_arlock  (),
  .s_axi_arcache (),
  .s_axi_arprot  (),
  .s_axi_arregion(),
  .s_axi_arqos   (),
  .s_axi_aruser  (),
  .s_axi_arvalid (),
  .s_axi_arready (),
  .s_axi_rid     (),
  .s_axi_rdata   (),
  .s_axi_rresp   (),
  .s_axi_rlast   (),
  .s_axi_ruser   (),
  .s_axi_rvalid  (),
  .s_axi_rready  (),

  // Master side
  .m_axi_awid    (),
  .m_axi_awaddr  (s00_axi_awaddr),
  .m_axi_awlen   (),
  .m_axi_awsize  (),
  .m_axi_awburst (),
  .m_axi_awlock  (),
  .m_axi_awcache (),
  .m_axi_awprot  (s00_axi_awprot),
  .m_axi_awregion(),
  .m_axi_awqos   (),
  .m_axi_awuser  (),
  .m_axi_awvalid (s00_axi_awvalid),
  .m_axi_awready (s00_axi_awready),
  .m_axi_wid     (),
  .m_axi_wdata   (s00_axi_wdata),
  .m_axi_wstrb   (s00_axi_wstrb),
  .m_axi_wlast   (),
  .m_axi_wuser   (),
  .m_axi_wvalid  (s00_axi_wvalid),
  .m_axi_wready  (s00_axi_wready),
  .m_axi_bid     (),
  .m_axi_bresp   (s00_axi_bresp),
  .m_axi_buser   (1'b0),
  .m_axi_bvalid  (s00_axi_bvalid),
  .m_axi_bready  (s00_axi_bready),
  .m_axi_arid    (),
  .m_axi_araddr  (s00_axi_araddr),
  .m_axi_arlen   (),
  .m_axi_arsize  (),
  .m_axi_arburst (),
  .m_axi_arlock  (),
  .m_axi_arcache (),
  .m_axi_arprot  (s00_axi_arprot),
  .m_axi_arregion(),
  .m_axi_arqos   (),
  .m_axi_aruser  (),
  .m_axi_arvalid (s00_axi_arvalid),
  .m_axi_arready (s00_axi_arready),
  .m_axi_rid     (),
  .m_axi_rdata   (s00_axi_rdata),
  .m_axi_rresp   (s00_axi_rresp),
  .m_axi_rlast   (1'b0),
  .m_axi_ruser   (1'b0),
  .m_axi_rvalid  (s00_axi_rvalid),
  .m_axi_rready  (s00_axi_rready)
);

axi_vip_v1_1_14_top #(
  .C_AXI_PROTOCOL       (BFM_AXI_VIP_PROTOCOL),
  .C_AXI_INTERFACE_MODE (BFM_AXI_VIP_INTERFACE_MODE),
  .C_AXI_ADDR_WIDTH     (BFM_AXI_VIP_ADDR_WIDTH),
  .C_AXI_WDATA_WIDTH    (BFM_AXI_VIP_DATA_WIDTH),
  .C_AXI_RDATA_WIDTH    (BFM_AXI_VIP_DATA_WIDTH),
  .C_AXI_WID_WIDTH      (BFM_AXI_VIP_ID_WIDTH),
  .C_AXI_RID_WIDTH      (BFM_AXI_VIP_ID_WIDTH),
  .C_AXI_AWUSER_WIDTH   (BFM_AXI_VIP_AWUSER_WIDTH),
  .C_AXI_ARUSER_WIDTH   (BFM_AXI_VIP_ARUSER_WIDTH),
  .C_AXI_WUSER_WIDTH    (BFM_AXI_VIP_WUSER_WIDTH),
  .C_AXI_RUSER_WIDTH    (BFM_AXI_VIP_RUSER_WIDTH),
  .C_AXI_BUSER_WIDTH    (BFM_AXI_VIP_BUSER_WIDTH),
  .C_AXI_SUPPORTS_NARROW(BFM_AXI_VIP_SUPPORTS_NARROW),
  .C_AXI_HAS_BURST      (BFM_AXI_VIP_HAS_BURST),
  .C_AXI_HAS_LOCK       (BFM_AXI_VIP_HAS_LOCK),
  .C_AXI_HAS_CACHE      (BFM_AXI_VIP_HAS_CACHE),
  .C_AXI_HAS_REGION     (BFM_AXI_VIP_HAS_REGION),
  .C_AXI_HAS_PROT       (BFM_AXI_VIP_HAS_PROT),
  .C_AXI_HAS_QOS        (BFM_AXI_VIP_HAS_QOS),
  .C_AXI_HAS_WSTRB      (BFM_AXI_VIP_HAS_WSTRB),
  .C_AXI_HAS_BRESP      (BFM_AXI_VIP_HAS_BRESP),
  .C_AXI_HAS_RRESP      (BFM_AXI_VIP_HAS_RRESP),
  .C_AXI_HAS_ARESETN    (BFM_AXI_VIP_HAS_ARESETN)
) TOT_CALC_AXI (
  .aclk          (clk),
  .aclken        (1'b1),
  .aresetn       (~rst),
  .s_axi_awid    (),
  .s_axi_awaddr  (),
  .s_axi_awlen   (),
  .s_axi_awsize  (),
  .s_axi_awburst (),
  .s_axi_awlock  (),
  .s_axi_awcache (),
  .s_axi_awprot  (),
  .s_axi_awregion(),
  .s_axi_awqos   (),
  .s_axi_awuser  (),
  .s_axi_awvalid (),
  .s_axi_awready (),
  .s_axi_wid     (),
  .s_axi_wdata   (),
  .s_axi_wstrb   (),
  .s_axi_wlast   (),
  .s_axi_wuser   (),
  .s_axi_wvalid  (),
  .s_axi_wready  (),
  .s_axi_bid     (),
  .s_axi_bresp   (),
  .s_axi_buser   (),
  .s_axi_bvalid  (),
  .s_axi_bready  (),
  .s_axi_arid    (),
  .s_axi_araddr  (),
  .s_axi_arlen   (),
  .s_axi_arsize  (),
  .s_axi_arburst (),
  .s_axi_arlock  (),
  .s_axi_arcache (),
  .s_axi_arprot  (),
  .s_axi_arregion(),
  .s_axi_arqos   (),
  .s_axi_aruser  (),
  .s_axi_arvalid (),
  .s_axi_arready (),
  .s_axi_rid     (),
  .s_axi_rdata   (),
  .s_axi_rresp   (),
  .s_axi_rlast   (),
  .s_axi_ruser   (),
  .s_axi_rvalid  (),
  .s_axi_rready  (),

  // Master side
  .m_axi_awid    (),
  .m_axi_awaddr  (s01_axi_awaddr),
  .m_axi_awlen   (),
  .m_axi_awsize  (),
  .m_axi_awburst (),
  .m_axi_awlock  (),
  .m_axi_awcache (),
  .m_axi_awprot  (s01_axi_awprot),
  .m_axi_awregion(),
  .m_axi_awqos   (),
  .m_axi_awuser  (),
  .m_axi_awvalid (s01_axi_awvalid),
  .m_axi_awready (s01_axi_awready),
  .m_axi_wid     (),
  .m_axi_wdata   (s01_axi_wdata),
  .m_axi_wstrb   (s01_axi_wstrb),
  .m_axi_wlast   (),
  .m_axi_wuser   (),
  .m_axi_wvalid  (s01_axi_wvalid),
  .m_axi_wready  (s01_axi_wready),
  .m_axi_bid     (),
  .m_axi_bresp   (s01_axi_bresp),
  .m_axi_buser   (1'b0),
  .m_axi_bvalid  (s01_axi_bvalid),
  .m_axi_bready  (s01_axi_bready),
  .m_axi_arid    (),
  .m_axi_araddr  (s01_axi_araddr),
  .m_axi_arlen   (),
  .m_axi_arsize  (),
  .m_axi_arburst (),
  .m_axi_arlock  (),
  .m_axi_arcache (),
  .m_axi_arprot  (s01_axi_arprot),
  .m_axi_arregion(),
  .m_axi_arqos   (),
  .m_axi_aruser  (),
  .m_axi_arvalid (s01_axi_arvalid),
  .m_axi_arready (s01_axi_arready),
  .m_axi_rid     (),
  .m_axi_rdata   (s01_axi_rdata),
  .m_axi_rresp   (s01_axi_rresp),
  .m_axi_rlast   (1'b0),
  .m_axi_ruser   (1'b0),
  .m_axi_rvalid  (s01_axi_rvalid),
  .m_axi_rready  (s01_axi_rready)
);

axi_vip_v1_1_14_top #(
  .C_AXI_PROTOCOL       (BFM_AXI_VIP_PROTOCOL),
  .C_AXI_INTERFACE_MODE (BFM_AXI_VIP_INTERFACE_MODE),
  .C_AXI_ADDR_WIDTH     (BFM_AXI_VIP_ADDR_WIDTH),
  .C_AXI_WDATA_WIDTH    (BFM_AXI_VIP_DATA_WIDTH),
  .C_AXI_RDATA_WIDTH    (BFM_AXI_VIP_DATA_WIDTH),
  .C_AXI_WID_WIDTH      (BFM_AXI_VIP_ID_WIDTH),
  .C_AXI_RID_WIDTH      (BFM_AXI_VIP_ID_WIDTH),
  .C_AXI_AWUSER_WIDTH   (BFM_AXI_VIP_AWUSER_WIDTH),
  .C_AXI_ARUSER_WIDTH   (BFM_AXI_VIP_ARUSER_WIDTH),
  .C_AXI_WUSER_WIDTH    (BFM_AXI_VIP_WUSER_WIDTH),
  .C_AXI_RUSER_WIDTH    (BFM_AXI_VIP_RUSER_WIDTH),
  .C_AXI_BUSER_WIDTH    (BFM_AXI_VIP_BUSER_WIDTH),
  .C_AXI_SUPPORTS_NARROW(BFM_AXI_VIP_SUPPORTS_NARROW),
  .C_AXI_HAS_BURST      (BFM_AXI_VIP_HAS_BURST),
  .C_AXI_HAS_LOCK       (BFM_AXI_VIP_HAS_LOCK),
  .C_AXI_HAS_CACHE      (BFM_AXI_VIP_HAS_CACHE),
  .C_AXI_HAS_REGION     (BFM_AXI_VIP_HAS_REGION),
  .C_AXI_HAS_PROT       (BFM_AXI_VIP_HAS_PROT),
  .C_AXI_HAS_QOS        (BFM_AXI_VIP_HAS_QOS),
  .C_AXI_HAS_WSTRB      (BFM_AXI_VIP_HAS_WSTRB),
  .C_AXI_HAS_BRESP      (BFM_AXI_VIP_HAS_BRESP),
  .C_AXI_HAS_RRESP      (BFM_AXI_VIP_HAS_RRESP),
  .C_AXI_HAS_ARESETN    (BFM_AXI_VIP_HAS_ARESETN)
) MEM_AXI (
  .aclk          (clk),
  .aclken        (1'b1),
  .aresetn       (~rst),
  .s_axi_awid    (),
  .s_axi_awaddr  (),
  .s_axi_awlen   (),
  .s_axi_awsize  (),
  .s_axi_awburst (),
  .s_axi_awlock  (),
  .s_axi_awcache (),
  .s_axi_awprot  (),
  .s_axi_awregion(),
  .s_axi_awqos   (),
  .s_axi_awuser  (),
  .s_axi_awvalid (),
  .s_axi_awready (),
  .s_axi_wid     (),
  .s_axi_wdata   (),
  .s_axi_wstrb   (),
  .s_axi_wlast   (),
  .s_axi_wuser   (),
  .s_axi_wvalid  (),
  .s_axi_wready  (),
  .s_axi_bid     (),
  .s_axi_bresp   (),
  .s_axi_buser   (),
  .s_axi_bvalid  (),
  .s_axi_bready  (),
  .s_axi_arid    (),
  .s_axi_araddr  (),
  .s_axi_arlen   (),
  .s_axi_arsize  (),
  .s_axi_arburst (),
  .s_axi_arlock  (),
  .s_axi_arcache (),
  .s_axi_arprot  (),
  .s_axi_arregion(),
  .s_axi_arqos   (),
  .s_axi_aruser  (),
  .s_axi_arvalid (),
  .s_axi_arready (),
  .s_axi_rid     (),
  .s_axi_rdata   (),
  .s_axi_rresp   (),
  .s_axi_rlast   (),
  .s_axi_ruser   (),
  .s_axi_rvalid  (),
  .s_axi_rready  (),

  // Master side
  .m_axi_awid    (),
  .m_axi_awaddr  (s02_axi_awaddr),
  .m_axi_awlen   (),
  .m_axi_awsize  (),
  .m_axi_awburst (),
  .m_axi_awlock  (),
  .m_axi_awcache (),
  .m_axi_awprot  (s02_axi_awprot),
  .m_axi_awregion(),
  .m_axi_awqos   (),
  .m_axi_awuser  (),
  .m_axi_awvalid (s02_axi_awvalid),
  .m_axi_awready (s02_axi_awready),
  .m_axi_wid     (),
  .m_axi_wdata   (s02_axi_wdata),
  .m_axi_wstrb   (s02_axi_wstrb),
  .m_axi_wlast   (s02_axi_wlast),
  .m_axi_wuser   (),
  .m_axi_wvalid  (s02_axi_wvalid),
  .m_axi_wready  (s02_axi_wready),
  .m_axi_bid     (),
  .m_axi_bresp   (s02_axi_bresp),
  .m_axi_buser   (1'b0),
  .m_axi_bvalid  (s02_axi_bvalid),
  .m_axi_bready  (s02_axi_bready),
  .m_axi_arid    (),
  .m_axi_araddr  (s02_axi_araddr),
  .m_axi_arlen   (),
  .m_axi_arsize  (),
  .m_axi_arburst (),
  .m_axi_arlock  (),
  .m_axi_arcache (),
  .m_axi_arprot  (s02_axi_arprot),
  .m_axi_arregion(),
  .m_axi_arqos   (),
  .m_axi_aruser  (),
  .m_axi_arvalid (s02_axi_arvalid),
  .m_axi_arready (s02_axi_arready),
  .m_axi_rid     (),
  .m_axi_rdata   (s02_axi_rdata),
  .m_axi_rresp   (s02_axi_rresp),
  .m_axi_rlast   (1'b0),
  .m_axi_ruser   (1'b0),
  .m_axi_rvalid  (s02_axi_rvalid),
  .m_axi_rready  (s02_axi_rready)
);

wire rst_n;
assign rst_n = !rst;

memory_wrapper_wrapper u_memory_bfm (
  .ACLK_0(clk),
  .ARESETN_0(rst_n),
  .S00_AXI_0_araddr({24'hC000_00, 2'b0, s02_axi_araddr}),
  .S00_AXI_0_arburst(2'b01),
  .S00_AXI_0_arcache(4'b0011),
  .S00_AXI_0_arid('0),
  .S00_AXI_0_arlen(8'h00),
  .S00_AXI_0_arlock(1'b0),
  .S00_AXI_0_arprot(s02_axi_arprot),
  .S00_AXI_0_arqos(4'b0000),
  .S00_AXI_0_arready(s02_axi_arready),
  .S00_AXI_0_arsize(3'b010),
  .S00_AXI_0_arvalid(s02_axi_arvalid),
  .S00_AXI_0_awaddr({24'hC000_00, 2'b0, s02_axi_awaddr}),
  .S00_AXI_0_awburst(2'b01),
  .S00_AXI_0_awcache(4'b0011),
  .S00_AXI_0_awid('0),
  .S00_AXI_0_awlen(8'h00),
  .S00_AXI_0_awlock(1'b0),
  .S00_AXI_0_awprot(s02_axi_awprot),
  .S00_AXI_0_awqos(4'b0000),
  .S00_AXI_0_awready(s02_axi_awready),
  .S00_AXI_0_awsize(3'b010),
  .S00_AXI_0_awvalid(s02_axi_awvalid),
  .S00_AXI_0_bid(),
  .S00_AXI_0_bready(s02_axi_bready),
  .S00_AXI_0_bresp(s02_axi_bresp),
  .S00_AXI_0_bvalid(s02_axi_bvalid),
  .S00_AXI_0_rdata(s02_axi_rdata),
  .S00_AXI_0_rid(),
  .S00_AXI_0_rlast(),
  .S00_AXI_0_rready(s02_axi_rready),
  .S00_AXI_0_rresp(s02_axi_rresp),
  .S00_AXI_0_rvalid(s02_axi_rvalid),
  .S00_AXI_0_wdata(s02_axi_wdata),
  .S00_AXI_0_wlast(s02_axi_wvalid),
  .S00_AXI_0_wready(s02_axi_wready),
  .S00_AXI_0_wstrb(s02_axi_wstrb),
  .S00_AXI_0_wvalid(s02_axi_wvalid),

  .S01_AXI_0_araddr(m00_axi_araddr),
  .S01_AXI_0_arburst(2'b01),
  .S01_AXI_0_arcache(4'b0011),
  .S01_AXI_0_arid('0),
  .S01_AXI_0_arlen(8'h00),
  .S01_AXI_0_arlock(1'b0),
  .S01_AXI_0_arprot(m00_axi_arprot),
  .S01_AXI_0_arqos(4'b0000),
  .S01_AXI_0_arready(m00_axi_arready),
  .S01_AXI_0_arsize(3'b010),
  .S01_AXI_0_arvalid(m00_axi_arvalid),
  .S01_AXI_0_awaddr(m00_axi_awaddr),
  .S01_AXI_0_awburst(2'b01),
  .S01_AXI_0_awcache(4'b0011),
  .S01_AXI_0_awid('0),
  .S01_AXI_0_awlen(8'h00),
  .S01_AXI_0_awlock(1'b0),
  .S01_AXI_0_awprot(m00_axi_awprot),
  .S01_AXI_0_awqos(4'b0000),
  .S01_AXI_0_awready(m00_axi_awready),
  .S01_AXI_0_awsize(3'b010),
  .S01_AXI_0_awvalid(m00_axi_awvalid),
  .S01_AXI_0_bid(),
  .S01_AXI_0_bready(m00_axi_bready),
  .S01_AXI_0_bresp(m00_axi_bresp),
  .S01_AXI_0_bvalid(m00_axi_bvalid),
  .S01_AXI_0_rdata(m00_axi_rdata),
  .S01_AXI_0_rid(),
  .S01_AXI_0_rlast(),
  .S01_AXI_0_rready(m00_axi_rready),
  .S01_AXI_0_rresp(m00_axi_rresp),
  .S01_AXI_0_rvalid(m00_axi_rvalid),
  .S01_AXI_0_wdata(m00_axi_wdata),
  .S01_AXI_0_wlast(),
  .S01_AXI_0_wready(m00_axi_wready),
  .S01_AXI_0_wstrb(m00_axi_wstrb),
  .S01_AXI_0_wvalid(m00_axi_wvalid)
);

typedef logic [SAMPLE_NUM_PER_CYCLE-1:0][11:0] adc_sample_vector_t;

// ----- Local variables -----
adc_sample_vector_t adc_samples_q;

assign adc_samples_q = { >> { samples } };




logic [31:0] tot;
logic [63:0] t_lead;
wire [11:0] adc_data_peek;
wire adc_valid_peek;
reg [11:0] adc_queue [$];
int queue_size;

adc_csv_streamer #(
  .CSV_FILE("C:/AGH_archive/Semestr_MI/SDUP/Project/tot_final_sim/sim/python/data/shaper_output2.csv"),
  .V_MIN   (0.0),
  .V_MAX   (1.0)
)
u_adc_csv_streamer (
  .adc_data  (adc_data_peek),
  .adc_valid (adc_valid_peek),
  .rst_n     (!rst),
  .sample_clk(clk)
);

initial begin
  axi_master_calc.init(TOT_CALC_AXI.IF, "axi_master_calc");
  axi_master_bram.init(BRAM_AXI.IF, "axi_master_bram");
  axi_master_mem.init(MEM_AXI.IF, "axi_master_mem");

  rst = 1'b1;
  #1us;
  rst = 1'b0;

  // queue_size = adc_queue.size();
  // $display("[AXI MASTER] Starting ehh write of %0d samples to BRAM...", queue_size);

  // for (int i = 0; i < 24; i++) begin
  //   // Calculate address offset.
  //   // Multiplying by 4 assumes a 32-bit wide BRAM interface (4 bytes per word).
  //   automatic bit [31:0] target_addr = BRAM_BASE_ADDR + (i * 4);

  //   // Pop the oldest data from the front of the queue (FIFO behavior)
  //   // automatic bit [11:0] data_sample = adc_queue.pop_front();

  //   // Trigger the AXI master verification/simulation task
  //   // Zero-extending the 12-bit sample to fit the 32-bit data bus
  //   axi_master_mem.write(target_addr, 32'(adc_data_peek), 32);
  // end

  for (int i=BRAM_BASE_ADDR; i<BRAM_BASE_ADDR + 32'h1FF; i=i+4) begin
    axi_master_mem.write(i, (i-BRAM_BASE_ADDR), 32);
  end
  
  $display("Writing data done");
  axi_master_bram.write(32'h04, BRAM_BASE_ADDR + 32'h4, 32); // ADDR_START
  axi_master_bram.write(32'h08, BRAM_BASE_ADDR + 32'h1FF, 32); // ADDR_STOP
  axi_master_calc.write(32'h00, 32'h7FF, 32); // THRESHOLD

  axi_master_bram.write(32'h00, 32'h1, 32); // START
  // #700ns;

  repeat(16) begin
    #250ns;
    axi_master_calc.read(32'h04, tot, 32);
    axi_master_calc.read(32'h08, t_lead[31:0], 32);
    axi_master_calc.read(32'h0C, t_lead[63:32], 32);

    $display("TOT = %dps  |  T_LEAD = %dns", tot, t_lead / 1000);
  end

  axi_master_bram.write(32'h00, 32'h0, 32);
  #1us;
  $finish(0);
end



// Append to the queue on the rising edge of the clock when data is valid
always @(posedge clk) begin
  if (!rst) begin
    adc_queue.delete(); // Clear the queue on reset
  end else if (adc_valid_peek) begin
    $display("Pushing data");
    adc_queue.push_back(adc_data_peek[11:0]); // Append the 12-bit data
  end
end


endmodule
