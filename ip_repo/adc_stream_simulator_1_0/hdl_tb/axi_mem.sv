`timescale 1ns / 1ps

module axi_bram_bfm (
  input  logic         s_axi_aclk,
  input  logic         s_axi_aresetn,

  // AXI Write Address Channel
  input  logic [14:0]  s_axi_awaddr,
  input  logic [7:0]   s_axi_awlen,
  input  logic [2:0]   s_axi_awsize,
  input  logic [1:0]   s_axi_awburst,
  input  logic         s_axi_awlock,
  input  logic [3:0]   s_axi_awcache,
  input  logic [2:0]   s_axi_awprot,
  input  logic         s_axi_awvalid,
  output logic         s_axi_awready,

  // AXI Write Data Channel
  input  logic [31:0]  s_axi_wdata,
  input  logic [3:0]   s_axi_wstrb,
  input  logic         s_axi_wlast,
  input  logic         s_axi_wvalid,
  output logic         s_axi_wready,

  // AXI Write Response Channel
  output logic [1:0]   s_axi_bresp,
  output logic         s_axi_bvalid,
  input  logic         s_axi_bready,

  // AXI Read Address Channel
  input  logic [14:0]  s_axi_araddr,
  input  logic [7:0]   s_axi_arlen,
  input  logic [2:0]   s_axi_arsize,
  input  logic [1:0]   s_axi_arburst,
  input  logic         s_axi_arlock,
  input  logic [3:0]   s_axi_arcache,
  input  logic [2:0]   s_axi_arprot,
  input  logic         s_axi_arvalid,
  output logic         s_axi_arready,

  // AXI Read Data Channel
  output logic [31:0]  s_axi_rdata,
  output logic [1:0]   s_axi_rresp,
  output logic         s_axi_rlast,
  output logic         s_axi_rvalid,
  input  logic         s_axi_rready
);

  // -------------------------------------------------------------------------
  // Internal Interconnect Wires
  // -------------------------------------------------------------------------
  // Port A Wires
  wire        bram_rst_a;
  wire        bram_clk_a;
  wire        bram_en_a;
  wire [3:0]  bram_we_a;
  wire [14:0] bram_addr_a;
  wire [31:0] bram_wrdata_a;
  wire [31:0] bram_rddata_a;

  // Port B Wires
  wire        bram_rst_b;
  wire        bram_clk_b;
  wire        bram_en_b;
  wire [3:0]  bram_we_b;
  wire [14:0] bram_addr_b;
  wire [31:0] bram_wrdata_b;
  wire [31:0] bram_rddata_b;

  // -------------------------------------------------------------------------
  // AXI BRAM Controller IP Instance
  // -------------------------------------------------------------------------
  axi_bram_ctrl_0 u_axi_bram_ctrl_0 (
    // Port A Interface
    .bram_rst_a    (bram_rst_a),
    .bram_clk_a    (bram_clk_a),
    .bram_en_a     (bram_en_a),
    .bram_we_a     (bram_we_a),
    .bram_addr_a   (bram_addr_a),
    .bram_wrdata_a (bram_wrdata_a),
    .bram_rddata_a (bram_rddata_a),
    
    // Port B Interface
    .bram_rst_b    (bram_rst_b),
    .bram_clk_b    (bram_clk_b),
    .bram_en_b     (bram_en_b),
    .bram_we_b     (bram_we_b),
    .bram_addr_b   (bram_addr_b),
    .bram_wrdata_b (bram_wrdata_b),
    .bram_rddata_b (bram_rddata_b),
    
    // AXI System Signals
    .s_axi_aclk    (s_axi_aclk),
    .s_axi_aresetn (s_axi_aresetn),
    
    // AXI AR Channel
    .s_axi_araddr  (s_axi_araddr),
    .s_axi_arburst (s_axi_arburst),
    .s_axi_arcache (s_axi_arcache),
    .s_axi_arlen   (s_axi_arlen),
    .s_axi_arlock  (s_axi_arlock),
    .s_axi_arprot  (s_axi_arprot),
    .s_axi_arready (s_axi_arready),
    .s_axi_arsize  (s_axi_arsize),
    .s_axi_arvalid (s_axi_arvalid),
    
    // AXI AW Channel
    .s_axi_awaddr  (s_axi_awaddr),
    .s_axi_awburst (s_axi_awburst),
    .s_axi_awcache (s_axi_awcache),
    .s_axi_awlen   (s_axi_awlen),
    .s_axi_awlock  (s_axi_awlock),
    .s_axi_awprot  (s_axi_awprot),
    .s_axi_awready (s_axi_awready),
    .s_axi_awsize  (s_axi_awsize),
    .s_axi_awvalid (s_axi_awvalid),
    
    // AXI B Channel
    .s_axi_bready  (s_axi_bready),
    .s_axi_bresp   (s_axi_bresp),
    .s_axi_bvalid  (s_axi_bvalid),
    
    // AXI R Channel
    .s_axi_rdata   (s_axi_rdata),
    .s_axi_rlast   (s_axi_rlast),
    .s_axi_rready  (s_axi_rready),
    .s_axi_rresp   (s_axi_rresp),
    .s_axi_rvalid  (s_axi_rvalid),
    
    // AXI W Channel
    .s_axi_wdata   (s_axi_wdata),
    .s_axi_wlast   (s_axi_wlast),
    .s_axi_wready  (s_axi_wready),
    .s_axi_wstrb   (s_axi_wstrb),
    .s_axi_wvalid  (s_axi_wvalid)
  );

  // -------------------------------------------------------------------------
  // Single-Port Block RAM Memory Instances
  // -------------------------------------------------------------------------
  
  // Instance 0: Connected straight to Port A
  blk_mem_gen_0 RAM_INST_A (
    .clka  (bram_clk_a),
    .ena   (bram_en_a),
    .wea   (bram_we_a),
    .addra (bram_addr_a),
    .dina  (bram_wrdata_a),
    .douta (bram_rddata_a)
  );

  // Instance 1: Connected straight to Port B
  blk_mem_gen_0 RAM_INST_B (
    .clka  (bram_clk_b),
    .ena   (bram_en_b),
    .wea   (bram_we_b),
    .addra (bram_addr_b),
    .dina  (bram_wrdata_b),
    .douta (bram_rddata_b)
  );

endmodule