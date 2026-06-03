`timescale 1ns / 1ps

module tot_core_top_tb;

// ============================================================
// Parameters
// ============================================================

parameter SAMPLE_NUM_PER_CYCLE = 1;

parameter WIDTH = 32;

parameter FRAC = 8;

parameter CLK_PERIOD = 10;

// ============================================================
// Signals
// ============================================================

logic clk;

logic rst_n;

logic [WIDTH-1:0] thr;

logic [SAMPLE_NUM_PER_CYCLE*12-1:0] sample;

// Outputs

wire [WIDTH-1:0] tot;

wire [WIDTH-1:0] t_leading_edge;

wire data_valid;

// ============================================================
// DUT
// ============================================================

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

  .sample(sample),

  .tot(tot),

  .t_leading_edge(t_leading_edge),

  .data_valid(data_valid)
);

// ============================================================
// Clock
// ============================================================

initial
begin

  clk = 1'b0;

  forever #(CLK_PERIOD/2)
    clk = ~clk;

end

// ============================================================
// Dump
// ============================================================

initial
begin

  $dumpfile("tot_core_top_tb.vcd");

  $dumpvars(0, tot_core_top_tb);

end

// ============================================================
// Monitor
// ============================================================

initial
begin

  $display("");
  $display("==========================================================");
  $display("TIME   SAMPLE   THR   VALID   T_LEAD   TOT");
  $display("==========================================================");

  forever
  begin

    @(posedge clk);

    $display(
      "%0t   %0d   %0d   %0b   %0d   %0d",
      $time,
      sample[11:0],
      thr,
      data_valid,
      t_leading_edge,
      tot
    );

  end

end

// ============================================================
// Event display
// ============================================================

always @(posedge data_valid)
begin

  $display("");
  $display("################################################");
  $display("EVENT DETECTED @ %0t ns", $time);
  $display("################################################");

  $display("Leading edge : %0d", t_leading_edge);

  $display("ToT          : %0d", tot);

  $display("################################################");
  $display("");

end

// ============================================================
// Main stimulus
// ============================================================

initial
begin

  //------------------------------------------------------------
  // Init
  //------------------------------------------------------------

  rst_n = 1'b0;

  thr = 32'd500;

  sample = '0;

  //------------------------------------------------------------
  // Reset
  //------------------------------------------------------------

  wait_clk_cycles(10);

  rst_n = 1'b1;

  wait_clk_cycles(10);

  //------------------------------------------------------------
  // Strong pulse
  //------------------------------------------------------------

  $display("");
  $display("Generating STRONG pulse");
  $display("");

  drive_pulse(
    2000,
    40
  );

  wait_clk_cycles(50);

  //------------------------------------------------------------
  // Medium pulse
  //------------------------------------------------------------

  $display("");
  $display("Generating MEDIUM pulse");
  $display("");

  drive_pulse(
    1200,
    25
  );

  wait_clk_cycles(50);

  //------------------------------------------------------------
  // Weak pulse
  //------------------------------------------------------------

  $display("");
  $display("Generating WEAK pulse");
  $display("");

  drive_pulse(
    700,
    15
  );

  wait_clk_cycles(50);

  //------------------------------------------------------------
  // Below threshold
  //------------------------------------------------------------

  $display("");
  $display("Generating BELOW threshold pulse");
  $display("");

  drive_pulse(
    300,
    20
  );

  //------------------------------------------------------------
  // Finish
  //------------------------------------------------------------

  wait_clk_cycles(100);

  $display("");
  $display("Simulation finished");
  $display("");

  $finish;

end

// ============================================================
// Pulse generator
// ============================================================

task automatic drive_pulse
(
  input int peak_amplitude,
  input int duration_cycles
);

  int val;

  begin

    //----------------------------------------------------------
    // Baseline
    //----------------------------------------------------------

    sample[11:0] <= 0;

    @(posedge clk);

    //----------------------------------------------------------
    // Fast rise
    //----------------------------------------------------------

    sample[11:0] <= peak_amplitude / 4;
    @(posedge clk);

    sample[11:0] <= peak_amplitude / 2;
    @(posedge clk);

    sample[11:0] <= peak_amplitude;
    @(posedge clk);

    //----------------------------------------------------------
    // Exponential decay
    //----------------------------------------------------------

    val = peak_amplitude;

    repeat(duration_cycles)
    begin

      val = (val * 92) / 100;

      sample[11:0] <= val[11:0];

      @(posedge clk);

    end

    //----------------------------------------------------------
    // Return to zero
    //----------------------------------------------------------

    sample[11:0] <= 0;

    repeat(10)
      @(posedge clk);

  end

endtask

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