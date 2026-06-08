`timescale 1ps / 1ps

module top_calculator_tb;

import axi_vip_pkg::*;
import axi_pkg::*;

// ----- AXI BFM -----
axi_master_t axi_master = new();

// ----- Local parameters -----
parameter SAMPLE_NUM_PER_CYCLE = 24;
parameter SAMPLING_CLK_PERIOD_PS = 16'd263;
parameter bit [31:0] TIMESTAMP_CLK_PERIOD_PS = 32'd25_000; // 40 MHz
parameter WIDTH = 32;
parameter FRAC = 8;
parameter real CLK_PERIOD = 6.25ns;
parameter ID = 32'h0000_CA7C;
parameter C_S00_AXI_DATA_WIDTH = 32;
parameter C_S00_AXI_ADDR_WIDTH = 8;
parameter V_MIN = 0;
parameter V_MAX = 1.0;


// ----- Memory map -----
localparam bit [31:0] CSR_ADDR = 32'h0;
localparam bit [31:0] TOT_RES_ADDR = 32'h4;
localparam bit [31:0] T_LEAD_RES_LO_ADDR = 32'h8;
localparam bit [31:0] T_LEAD_RES_HI_ADDR = 32'hC;

// ----- Local variables -----
logic clk;
logic rst_n_adc;
logic clk_40MHz;
logic clk_sample;
logic rst_n;
logic [WIDTH-1:0] thr;
logic [11:0] adc_data_peek;
wire adc_valid, adc_valid_peek;

// ----- Samples stream -----
logic [SAMPLE_NUM_PER_CYCLE*12-1:0] samples;

// ----- AXI signals -----
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


initial begin
  clk = 1'b0;
  forever begin
    #(CLK_PERIOD/2) clk = ~clk;
  end
end

initial begin
  clk_40MHz = 1'b0;
  wait(rst_n); // Release synchonously so timestamp is accurate
  forever begin
    clk_40MHz = ~clk_40MHz;
    #(TIMESTAMP_CLK_PERIOD_PS/2);
  end
end

initial begin
  clk_sample = 1'b0;
  wait(rst_n_adc);
  forever begin
    clk_sample = ~clk_sample;
    #(SAMPLING_CLK_PERIOD_PS/2);
  end
end

tot_calculator_v1_5 #(
  .SAMPLING_CLK_PERIOD_PS(SAMPLING_CLK_PERIOD_PS),
  .TIMESTAMP_CLK_PERIOD_PS(TIMESTAMP_CLK_PERIOD_PS),
  .SAMPLE_NUM_PER_CYCLE(SAMPLE_NUM_PER_CYCLE),
  .WIDTH               (WIDTH),
  .FRAC                (FRAC),
  .ID                  (ID),
  .C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
  .C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
)
  dut (
  // Ports of Axi Slave Bus Interface S00_AXI
  .s00_axi_aclk   (clk),
  .clk_timestamp  (clk_40MHz),
  .rst_n_timestamp(rst_n),
  .s00_axi_araddr (s00_axi_araddr),
  .s00_axi_aresetn(rst_n),
  .s00_axi_arprot (s00_axi_arprot),
  .s00_axi_arready(s00_axi_arready),
  .s00_axi_arvalid(s00_axi_arvalid),
  .s00_axi_awaddr (s00_axi_awaddr),
  .s00_axi_awprot (s00_axi_awprot),
  .s00_axi_awready(s00_axi_awready),
  .s00_axi_awvalid(s00_axi_awvalid),
  .s00_axi_bready (s00_axi_bready),
  .s00_axi_bresp  (s00_axi_bresp),
  .s00_axi_bvalid (s00_axi_bvalid),
  .s00_axi_rdata  (s00_axi_rdata),
  .s00_axi_rready (s00_axi_rready),
  .s00_axi_rresp  (s00_axi_rresp),
  .s00_axi_rvalid (s00_axi_rvalid),
  .s00_axi_wdata  (s00_axi_wdata),
  .s00_axi_wready (s00_axi_wready),
  .s00_axi_wstrb  (s00_axi_wstrb),
  .s00_axi_wvalid (s00_axi_wvalid),
  // ToT calculator ports
  .sample         (samples),
  .sample_ready   (),
  .sample_valid   (1'b1)
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
) BFM_AXI (
  .aclk          (clk),
  .aclken        (1'b1),
  .aresetn       (rst_n),
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


// ============================================================
// Event display
// ============================================================
time rise_time_sim, fall_time_sim, start_time;
time tot_sim;
logic [11:0]adc_data_q;
logic [31:0] tot;
logic [63:0] t_lead;



always_comb begin
  if (adc_data_peek > thr && adc_data_q <= thr) rise_time_sim = $time();
  if (adc_data_peek < thr && adc_data_q >= thr) fall_time_sim = $time();
  tot_sim = fall_time_sim - rise_time_sim;
end

// For edge detection
always_ff @ (posedge clk_sample) begin
  adc_data_q <= adc_data_peek;
end

// For debug waveform peek
logic [11:0] adc_data_peek_q [23:0];

always_ff @(posedge clk_sample) begin
  adc_data_peek_q[0] <= adc_data_peek;
  
  // Shift all remaining elements down by 1 position every clock cycle
  for (int i = 1; i < 24; i++) begin
    adc_data_peek_q[i] <= adc_data_peek_q[i-1];
  end
end

time timestamp_queue [$];

always @(posedge clk_sample) begin
  if (adc_data_peek < thr && adc_data_q >= thr) begin
    $display("Sim leading edge = %0dns to %0dns", (rise_time_sim-start_time - SAMPLING_CLK_PERIOD_PS)/1000, ( rise_time_sim-start_time)/1000);
    timestamp_queue.push_back(rise_time_sim-start_time - SAMPLING_CLK_PERIOD_PS);
  end
  
  // $display("--------------------------------------------------------");
  // $display("Sim trailing edge = %0d to %0d", fall_time_sim-start_time - SAMPLING_CLK_PERIOD_PS,  fall_time_sim-start_time);
  // $display("Sim tot edge = %0d to %0d ", tot_sim - SAMPLING_CLK_PERIOD_PS,  tot_sim + SAMPLING_CLK_PERIOD_PS);
  // $display("--------------------------------------------------------");
end

// ============================================================
// Main stimulus
// ============================================================
time time_sim, error1, error2;
initial begin
  axi_master.init(BFM_AXI.IF, "axi_master");
  tot = '0;
  t_lead = '0;

  rst_n_adc = 1'b0;
  rst_n = 1'b0;
  thr = 12'h7FF;

  wait_clk_cycles(10);
  rst_n = 1'b1;
  start_time = $time();
  wait_clk_cycles(10);
  axi_master.write(CSR_ADDR, 12'h7FF, 32);

  wait_clk_cycles(1);
  rst_n_adc = 1'b1;

  #200ns;
  wait_clk_cycles(400);

    repeat(12) begin
      axi_master.read(TOT_RES_ADDR, tot, 32);
      axi_master.read(T_LEAD_RES_LO_ADDR, t_lead[31:0], 32);
      axi_master.read(T_LEAD_RES_HI_ADDR, t_lead[63:32], 32);
      // $display("Leading edge = %0dns | ToT = %0dps", $unsigned(t_lead/1000), $unsigned(tot));
      time_sim = timestamp_queue.pop_front();
      error1 = (t_lead - time_sim);
      error2 = (time_sim - t_lead);
      $display("Meas edge = %0dps | Sim edge = %0dps, error = %0dps", $unsigned(t_lead), $unsigned(time_sim), min(error2, error1));
    end

  $finish;

end


adc_csv_streamer #(
  .CSV_FILE("C:/AGH_archive/Semestr_MI/SDUP/Project/tot_final_sim/sim/python/data/shaper_output3.csv"),
  .V_MIN   (V_MIN),
  .V_MAX   (V_MAX)
)
u_adc_csv_streamer (
  .adc_data  (adc_data_peek),
  .adc_valid (adc_valid_peek),
  .rst_n     (rst_n_adc),
  .sample_clk(clk_sample)
);

adc_csv_streamer2 #(
  .CSV_FILE("C:/AGH_archive/Semestr_MI/SDUP/Project/tot_final_sim/sim/python/data/shaper_output3.csv"),
  .V_MIN   (V_MIN),
  .V_MAX   (V_MAX),
  .SAMPLE_NUM_PER_CYCLE(SAMPLE_NUM_PER_CYCLE)
)
u_adc_csv_streamer_fast (
  .adc_data  (samples),
  .adc_valid (adc_valid),
  .rst_n     (rst_n_adc),
  .sample_clk(clk)
);

// ============================================================
// Wait clocks
// ============================================================

task automatic wait_clk_cycles (input int clk_num);
  begin
    repeat(clk_num) @(posedge clk);
  end
endtask

function automatic logic [63:0] min (input logic [63:0] val1, input logic [63:0] val2);
    // If the number is negative, invert it and add 1 (two's complement)
    return (val1 < val2) ? val1 : val2;
endfunction

endmodule
