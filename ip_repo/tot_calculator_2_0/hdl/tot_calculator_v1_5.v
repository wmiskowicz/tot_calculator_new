
// ---------------------------------------
// ------- ToT Calculator AXI IP ---------
// ---------------------------------------

// Module analyses input pulse passed via 'samples' input.
// Using mathematical model it estimates time over threshhold of the input pulse.
// This IP can process multiple samples per clock samples. Designed for recieving from adc12dl3200.

// User can read recieved values from registers 1 and 2.
// These registers are connected to FIFO.
// In order to read consecutive measured values user has to read from the same address multiple times.

// Register 0 - R/W - Threshold
// Register 1 - R   - Time over threshold
// Register 2 - R   - Time of leading edge [31:0]
// Register 3 - R   - Time of leading edge [63:32]

`timescale 1 ns / 1 ps


module tot_calculator_v1_5 #
(
	// ToT calculator parameters
  parameter [15:0] SAMPLING_CLK_PERIOD_PS = 16'd416, // 1.6 GHz sampling clock
  parameter [31:0] TIMESTAMP_CLK_PERIOD_PS = 32'd25_000, // 40 MHz timestamp clock
	parameter SAMPLE_NUM_PER_CYCLE = 24,
	parameter WIDTH = 32,
	parameter FRAC = 8,
	parameter ID = 32'h0000_CA7C,

	// Parameters of Axi Slave Bus Interface S00_AXI
	parameter integer C_S00_AXI_DATA_WIDTH  = 32,
	parameter integer C_S00_AXI_ADDR_WIDTH  = 6
)
(
	// ToT calculator ports
	input wire [SAMPLE_NUM_PER_CYCLE*12-1:0] sample,
	input wire sample_valid,
	output wire sample_ready,
	input  wire clk_timestamp, 

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
// Instantiation of Axi Bus Interface S00_AXI
tot_calculator_v1_5_S00_AXI # (
	.SAMPLING_CLK_PERIOD_PS(SAMPLING_CLK_PERIOD_PS),
  .TIMESTAMP_CLK_PERIOD_PS(TIMESTAMP_CLK_PERIOD_PS),
	.SAMPLE_NUM_PER_CYCLE(SAMPLE_NUM_PER_CYCLE),
	.WIDTH(WIDTH),
	.FRAC(FRAC),
	.ID(ID),
	.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
	.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
) tot_calculator_v1_5_S00_AXI_inst (
	.sample        (sample),
	.sample_valid	 (sample_valid),
	.sample_ready  (sample_ready),
	.clk_timestamp (clk_timestamp),
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

endmodule
