`timescale 1ns / 1ps

module tot_core_top_tb;


// ----- Local parameters -----
parameter SAMPLE_NUM_PER_CYCLE = 1;
parameter WIDTH = 32;
parameter FRAC = 8;
parameter CLK_PERIOD = 10;
parameter V_MIN = -0.1;
parameter V_MAX = 1.0;




// ----- Local variables -----
logic clk;
logic rst_n;
logic [WIDTH-1:0] thr;
logic [SAMPLE_NUM_PER_CYCLE*12-1:0] sample;
wire [11:0] adc_data;
wire adc_valid;

// --- Outputs ---
wire [WIDTH-1:0] tot;
wire [63:0] t_leading_edge;
wire data_valid;

// --- DUT ---
tot_core_top #(
  .SAMPLE_NUM_PER_CYCLE(SAMPLE_NUM_PER_CYCLE),
  .WIDTH(WIDTH),
  .FRAC(FRAC)
)
dut
(
  .clk(clk),
  .rst_n(rst_n),
  .thr(thr),
  .sample(adc_data),

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


// ============================================================
// Event display
// ============================================================

always @(posedge data_valid) begin
  $display("Leading edge = %0dps, | ToT = %0dps", t_leading_edge, tot);
end

// ============================================================
// Main stimulus
// ============================================================

initial begin

  rst_n = 1'b0;
  thr = 32'd1000;
  sample = '0;

  wait_clk_cycles(10);
  rst_n = 1'b1;
  wait_clk_cycles(10);


  wait(adc_valid==1);
  wait(adc_valid==0);
  wait_clk_cycles(400);

  $finish;

end


adc_csv_streamer #(
  .CSV_FILE("C:/AGH_archive/Semestr_MI/SDUP/Project/tot_final_sim/sim/python/data/shaper_output.csv"),
  .V_MIN   (V_MIN),
  .V_MAX   (V_MAX)
)
u_adc_csv_streamer (
  .adc_data  (adc_data),
  .adc_valid (adc_valid),
  .rst_n     (rst_n),
  .sample_clk(clk)
);



// ============================================================
// Wait clocks
// ============================================================

task automatic wait_clk_cycles
(
  input int clk_num
);

  begin

    repeat(clk_num)
      @(posedge clk);

  end

endtask

endmodule
