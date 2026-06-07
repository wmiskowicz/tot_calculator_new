
`timescale 1 ns / 1 ps

	module adc_bram_simulator_v1_2 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4,

		// Parameters of Axi Master Bus Interface M00_AXI
		parameter  C_M00_AXI_START_DATA_VALUE	= 32'hAA000000,
		parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M00_AXI_DATA_WIDTH	= 32,
		parameter integer C_M00_AXI_TRANSACTIONS_NUM	= 4
	)
	(
		// ----- Sample stream -----
		output wire [287:0] samples,
		output wire         samples_valid,
		input  wire         samples_ready,

		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,

		// Ports of Axi Master Bus Interface M00_AXI
		output wire [1:0] m00_axi_arburst,
		output wire [3:0] m00_axi_arcache,
		output wire [2:0] m00_axi_arid,
		output wire [7:0] m00_axi_arlen,
		output wire       m00_axi_arlock,
		output wire [3:0] m00_axi_arqos,
		output wire [2:0] m00_axi_arsize,
		output wire [1:0] m00_axi_awburst,
		output wire [3:0] m00_axi_awcache,
		output wire [2:0] m00_axi_awid,
		output wire [7:0] m00_axi_awlen,
		output wire       m00_axi_awlock,
		output wire [3:0] m00_axi_awqos,
		output wire [2:0] m00_axi_awsize,
		// output wire       m00_axi_wlast,


		output wire  m00_axi_txn_done,
		input wire  m00_axi_aclk,
		input wire  m00_axi_aresetn,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
		output wire [2 : 0] m00_axi_awprot,
		output wire  m00_axi_awvalid,
		input wire  m00_axi_awready,
		output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
		output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
		output wire  m00_axi_wvalid,
		input wire  m00_axi_wready,
		input wire [1 : 0] m00_axi_bresp,
		input wire  m00_axi_bvalid,
		output wire  m00_axi_bready,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
		output wire [2 : 0] m00_axi_arprot,
		output wire  m00_axi_arvalid,
		input wire  m00_axi_arready,
		input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
		input wire [1 : 0] m00_axi_rresp,
		input wire  m00_axi_rvalid,
		output wire  m00_axi_rready
	);

	// --- Connection to AXI master ---
  wire [31:0] bram_addr;
  wire bram_rd_en;
  wire [31:0] bram_rdata;
  wire bram_rvalid;

	// --- Setup from AXI slave ---
	wire start;
  wire [31:0] addr_start;
  wire [31:0] addr_stop;


assign m00_axi_arburst = 2'b01;
assign m00_axi_arcache = 4'b0011;
assign m00_axi_arid = 3'b0;
assign m00_axi_arlen = 8'h00;
assign m00_axi_arlock = 1'b0;
assign m00_axi_arqos = 4'b0000;
assign m00_axi_arsize = 3'b010;

assign m00_axi_awburst = 2'b01;
assign m00_axi_awcache = 4'b0011;
assign m00_axi_awid = 3'b0;
assign m00_axi_awlen = 8'h00;
assign m00_axi_awlock = 1'b0;
assign m00_axi_awqos = 4'b0000;
assign m00_axi_awsize = 3'b010;
// assign m00_axi_wlast = m00_axi_wvalid;


// Instantiation of Axi Bus Interface S00_AXI
	adc_bram_simulator_v1_2_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) adc_bram_simulator_v1_2_S00_AXI_inst (
		.start(start),
		.addr_start(addr_start),
		.addr_stop(addr_stop),
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready)
	);

// Instantiation of Axi Bus Interface M00_AXI
	adc_bram_simulator_v1_2_M00_AXI # ( 
		.C_M_START_DATA_VALUE(C_M00_AXI_START_DATA_VALUE),
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
		.C_M_TRANSACTIONS_NUM(C_M00_AXI_TRANSACTIONS_NUM)
	) adc_bram_simulator_v1_2_M00_AXI_inst (
		.rd_en(bram_rd_en),
		.addr_in(bram_addr),
		.read_data(bram_rdata),
		.read_valid(bram_rvalid),


		.INIT_AXI_TXN(),
		.ERROR(),
		.TXN_DONE(m00_axi_txn_done),
		.M_AXI_ACLK(m00_axi_aclk),
		.M_AXI_ARESETN(m00_axi_aresetn),
		.M_AXI_AWADDR(m00_axi_awaddr),
		.M_AXI_AWPROT(m00_axi_awprot),
		.M_AXI_AWVALID(m00_axi_awvalid),
		.M_AXI_AWREADY(m00_axi_awready),
		.M_AXI_WDATA(m00_axi_wdata),
		.M_AXI_WSTRB(m00_axi_wstrb),
		.M_AXI_WVALID(m00_axi_wvalid),
		.M_AXI_WREADY(m00_axi_wready),
		.M_AXI_BRESP(m00_axi_bresp),
		.M_AXI_BVALID(m00_axi_bvalid),
		.M_AXI_BREADY(m00_axi_bready),
		.M_AXI_ARADDR(m00_axi_araddr),
		.M_AXI_ARPROT(m00_axi_arprot),
		.M_AXI_ARVALID(m00_axi_arvalid),
		.M_AXI_ARREADY(m00_axi_arready),
		.M_AXI_RDATA(m00_axi_rdata),
		.M_AXI_RRESP(m00_axi_rresp),
		.M_AXI_RVALID(m00_axi_rvalid),
		.M_AXI_RREADY(m00_axi_rready)
	);


  bram_controller_core u_bram_controller_core (
    .clk          (m00_axi_aclk),
    .rst          (!m00_axi_aresetn),

    // Control inputs
    .start        (start),
    .addr_start   (addr_start),
    .addr_stop    (addr_stop),

    // BRAM Physical Interface
    .bram_addr    (bram_addr),
    .bram_rd_en   (bram_rd_en),
    .bram_rdata   (bram_rdata),
    .bram_rvalid  (bram_rvalid),

    // Downstream Stream Interface (288-bit Packets)
    .samples      (samples),
    .samples_ready(samples_ready),
    .samples_valid(samples_valid)
  );

	endmodule
