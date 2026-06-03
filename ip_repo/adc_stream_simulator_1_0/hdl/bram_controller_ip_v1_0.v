// ---------------------------------------
// ------- BRAM Controller AXI IP ---------
// ---------------------------------------

// The goal of this IP is to simulate a real-life conditions of ADC12DL3200 SerDes.
// The IP is responsible for reading BRAM data under adresses provided
// in registers 1 and 2. Then in packs the data into 287-bit vectors and streams it
// after Register_0[0] is being set.

// Register 0 - R/W - Control register
	// Bit 0 - R/W - Start
// Register 1 - R   - Address start
// Register 2 - R   - Address stop
// Register 3 - R   - ID register



`timescale 1 ns / 1 ps

	module bram_controller_ip_v1_0 #
	(
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// ----- BRAM AXI -----
		output wire [31:0] bram_addr,
		output wire        bram_arvalid,
		input  wire        bram_arready,
    output wire [7:0]  bram_arlen,
    output wire [2:0]  bram_arsize,
    output wire [1:0]  bram_arburst,

		input  wire [31:0] bram_rdata,
		input  wire        bram_rvalid,
		output wire        bram_rready,
		input  wire        bram_rlast,
    input  wire [1:0]  bram_rresp,
		
		// ----- Sample stream -----
		output wire [287:0] samples,
		output wire         samples_valid,
		input  wire         samples_ready,

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
		input wire  s00_axi_rready
	);

		assign bram_rready = 1'b1;

// Instantiation of Axi Bus Interface S00_AXI
	bram_controller_ip_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) bram_controller_ip_v1_0_S00_AXI_inst (
		.samples(samples),
		.samples_valid(samples_valid),
		.samples_ready(samples_ready),
		.bram_addr(bram_addr),
		.bram_arvalid(bram_arvalid),
		.bram_rdata(bram_rdata),
		.bram_rvalid(bram_rvalid),
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

	assign bram_arlen   = 8'b0000_0000;	// 1 data transfer per address request
	assign bram_arsize  = 3'd4;         // 4 bytes (32-bit) per transfer
	assign bram_arburst = 2'h1;					// Incrementing address mode

	endmodule
