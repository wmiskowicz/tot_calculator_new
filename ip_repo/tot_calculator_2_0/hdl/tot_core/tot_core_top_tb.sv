`timescale 1ps / 1ps

module tot_core_top_tb;


// ----- Local parameters -----
parameter SAMPLE_NUM_PER_CYCLE = 24;
parameter real SAMPLING_CLK_PERIOD_PS = 16'd416; //16'd625; // 1.6 GHz
parameter bit [31:0] TIMESTAMP_CLK_PERIOD_PS = 32'd25_000; // 40 MHz
parameter WIDTH = 32;
parameter FRAC = 8;
parameter CLK_PERIOD = 10ns;
parameter CLK_40MHZ_PERIOD = 25;
parameter V_MIN = 0;
parameter V_MAX = 1.0;




// ----- Local variables -----
logic clk;
logic clk_40MHz;
logic clk_sample;
logic rst_n;
logic [WIDTH-1:0] thr;
logic [SAMPLE_NUM_PER_CYCLE*12-1:0] sample;
wire [11:0] adc_data_peek;
wire adc_valid, adc_valid_peek;

// --- Outputs ---
wire [WIDTH-1:0] tot;
wire [63:0] t_leading_edge;
wire data_valid;

typedef logic [SAMPLE_NUM_PER_CYCLE-1:0][11:0] adc_sample_vector_t;
adc_sample_vector_t samples_peek;

assign samples_peek =  { >> { sample } };

// --- DUT ---
tot_core_top #(
  .SAMPLING_CLK_PERIOD_PS(SAMPLING_CLK_PERIOD_PS),
  .TIMESTAMP_CLK_PERIOD_PS(TIMESTAMP_CLK_PERIOD_PS),
  .SAMPLE_NUM_PER_CYCLE(SAMPLE_NUM_PER_CYCLE),
  .WIDTH(WIDTH),
  .FRAC(FRAC)
)
dut
(
  .clk(clk),
  .clk_40MHz(clk_40MHz),
  .rst_n(rst_n),
  .thr(thr),
  .sample(sample),

  .tot(tot),
  .t_leading_edge(t_leading_edge),
  .data_valid(data_valid)
);



initial begin
  clk = 1'b0;
  forever begin
    #(CLK_PERIOD/2);
    clk = ~clk;
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
  forever begin
    clk_sample = ~clk_sample;
    #(SAMPLING_CLK_PERIOD_PS/2);
  end
end


// ============================================================
// Event display
// ============================================================
time rise_time_sim, fall_time_sim, start_time;
time tot_sim;

always_comb begin
  if (dut.rise_detected == 1) rise_time_sim = $time();
  if (dut.fall_detected == 1) fall_time_sim = $time();
  tot_sim = fall_time_sim - rise_time_sim;
end

always @(posedge data_valid) begin
  $display("--------------------------------------------------------");
  $display("Leading edge = %0dps | ToT = %0dps", $unsigned(t_leading_edge), $unsigned(tot));
  $display("--------------------------------------------------------");
end

// ============================================================
// Main stimulus
// ============================================================

initial begin

  rst_n = 1'b0;
  thr = 12'h7FF;
  sample = '0;

  wait_clk_cycles(10);
  rst_n = 1'b1;
  start_time = $time();
  wait_clk_cycles(10);
  


  #1us;
  wait_clk_cycles(400);

  $finish;

end


adc_csv_streamer #(
  .CSV_FILE("C:/AGH_archive/Semestr_MI/SDUP/Project/tot_final_sim/sim/python/data/shaper_output.csv"),
  .V_MIN   (V_MIN),
  .V_MAX   (V_MAX)
)
u_adc_csv_streamer (
  .adc_data  (adc_data_peek),
  .adc_valid (adc_valid_peek),
  .rst_n     (rst_n),
  .sample_clk(clk_sample)
);

adc_csv_streamer2 #(
  .CSV_FILE("C:/AGH_archive/Semestr_MI/SDUP/Project/tot_final_sim/sim/python/data/shaper_output.csv"),
  .V_MIN   (V_MIN),
  .V_MAX   (V_MAX),
  .SAMPLE_NUM_PER_CYCLE(SAMPLE_NUM_PER_CYCLE)
)
u_adc_csv_streamer_fast (
  .adc_data  (sample),
  .adc_valid (adc_valid),
  .rst_n     (rst_n),
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

endmodule
