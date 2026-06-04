module coarse_tot_core #(
  parameter SAMPLE_NUM_PER_CYCLE = 24,
  parameter WIDTH = 32
)(
  input  wire clk,
  input  wire clk_timestamp,      // ~40MHz
  input  wire rst_n,

  input  wire [WIDTH-1:0] thr,
  input  wire [SAMPLE_NUM_PER_CYCLE*12-1:0] sample,

  output logic rise_detected,
  output logic fall_detected,

  output logic [11:0] rise_prev_sample,
  output logic [11:0] rise_curr_sample,

  output logic [11:0] fall_prev_sample,
  output logic [11:0] fall_curr_sample,

  output logic [WIDTH-1:0] rise_coarse_time,
  output logic [WIDTH-1:0] fall_coarse_time,
  output logic [31:0]       master_timestamp_rise,
  output logic [31:0]       master_timestamp_fall
);

// ----- Local parameters -----


// ----- Typedefs -----
typedef logic [SAMPLE_NUM_PER_CYCLE-1:0][11:0] adc_sample_vector_t;

// ----- Local variables -----
adc_sample_vector_t adc_samples_q, adc_samples_2q;

logic pulse_active, pulse_active_nxt, pulse_active_q;
logic [31:0] sampl_clk_ctr;

logic [11:0] rise_curr_sample_nxt, rise_curr_sample_q, rise_curr_sample_2q;
logic [11:0] rise_prev_sample_nxt, rise_prev_sample_q, rise_prev_sample_2q;
logic [11:0] fall_curr_sample_nxt, fall_curr_sample_q, fall_curr_sample_2q;
logic [11:0] fall_prev_sample_nxt, fall_prev_sample_q, fall_prev_sample_2q;

logic rise_detected_nxt, rise_detected_q, rise_detected_2q;
logic fall_detected_nxt, fall_detected_q, fall_detected_2q;

logic [WIDTH-1:0] rise_coarse_time_nxt, rise_coarse_time_q, rise_coarse_time_2q;
logic [WIDTH-1:0] fall_coarse_time_nxt, fall_coarse_time_q, fall_coarse_time_2q;


always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pulse_active     <= 1'b0;
    rise_detected    <= 1'b0;
    fall_detected    <= 1'b0;

    rise_curr_sample <= 12'd0;
    rise_prev_sample <= 12'd0;
    rise_coarse_time <= 32'd0;

    fall_curr_sample <= 12'd0;
    fall_prev_sample <= 12'd0;
    fall_coarse_time <= 32'd0;

    adc_samples_q <= adc_sample_vector_t'(0);
    adc_samples_2q <= adc_sample_vector_t'(0);

    rise_curr_sample_q <= 12'd0;
    rise_prev_sample_q <= 12'd0;
    fall_curr_sample_q <= 12'd0;
    fall_prev_sample_q <= 12'd0;

    rise_detected_q <= 1'b0;
    fall_detected_q <= 1'b0;
    rise_detected_2q <= 1'b0;
    fall_detected_2q <= 1'b0;
    pulse_active_q  <= 1'b0;

    rise_curr_sample_2q <= '0;
    rise_prev_sample_2q <= '0;
    rise_coarse_time_2q <= '0;

    fall_curr_sample_2q <= '0;
    fall_prev_sample_2q <= '0;
    fall_coarse_time_2q <= '0;

    rise_coarse_time_q <= 32'd0;
    fall_coarse_time_q <= 32'd0;
  end
  else begin
    pulse_active_q  <= pulse_active_nxt;
    rise_detected_q <= rise_detected_nxt;
    fall_detected_q <= fall_detected_nxt;

    rise_curr_sample_q <= rise_curr_sample_nxt;
    rise_prev_sample_q <= rise_prev_sample_nxt;
    rise_coarse_time_q <= rise_coarse_time_nxt;

    fall_curr_sample_q <= fall_curr_sample_nxt;
    fall_prev_sample_q <= fall_prev_sample_nxt;
    fall_coarse_time_q <= fall_coarse_time_nxt;

    adc_samples_q <= { >> { sample } };
    adc_samples_2q <= adc_samples_q;


    pulse_active  <= pulse_active_q;
    rise_detected_2q <= rise_detected_q;
    fall_detected_2q <= fall_detected_q;
    rise_detected <= rise_detected_2q;
    fall_detected <= fall_detected_2q;

    rise_curr_sample_2q <= rise_curr_sample_q;
    rise_prev_sample_2q <= rise_prev_sample_q;
    rise_coarse_time_2q <= rise_coarse_time_q;
    rise_curr_sample <= rise_curr_sample_2q;
    rise_prev_sample <= rise_prev_sample_2q;
    rise_coarse_time <= rise_coarse_time_2q;

    fall_curr_sample_2q <= fall_curr_sample_q;
    fall_prev_sample_2q <= fall_prev_sample_q;
    fall_coarse_time_2q <= fall_coarse_time_q;

    fall_curr_sample <= fall_curr_sample_2q;
    fall_prev_sample <= fall_prev_sample_2q;
    fall_coarse_time <= fall_coarse_time_2q;
  end
end

always_comb begin
  logic [11:0] current_sample;
  logic [11:0] previous_sample;

  rise_detected_nxt    = 1'b0;
  rise_coarse_time_nxt = '0;
  rise_curr_sample_nxt = rise_curr_sample;
  rise_prev_sample_nxt = rise_prev_sample;

  fall_detected_nxt    = 1'b0;
  fall_coarse_time_nxt = '0;
  fall_curr_sample_nxt = fall_curr_sample;
  fall_prev_sample_nxt = fall_prev_sample;

  pulse_active_nxt     = pulse_active; 

  for (int unsigned i=0; i<SAMPLE_NUM_PER_CYCLE; i++) begin

    current_sample  = adc_samples_q[i];
    previous_sample = (i==0) ? adc_samples_2q[SAMPLE_NUM_PER_CYCLE-1] : adc_samples_q[i-1];

    // --- Rising edge ---
    if ((previous_sample < thr[11:0]) && (current_sample >= thr[11:0])) begin
      rise_detected_nxt    = 1'b1;
      rise_curr_sample_nxt = current_sample;
      rise_prev_sample_nxt = previous_sample;
      // rise_coarse_time_nxt = (sampl_clk_ctr + i) - 1 - (2 * SAMPLE_NUM_PER_CYCLE); // In sampling clk cycles
      rise_coarse_time_nxt = (sampl_clk_ctr + i); // In sampling clk cycles
      pulse_active_nxt     = 1'b1;
      $display("Rise found at i = %d, sampl_clk_ctr=%d", i, sampl_clk_ctr); // compensate input delay*
    end

    // --- Falling edge ---
    if ((previous_sample >= thr[11:0]) && (current_sample < thr[11:0])) begin
      fall_detected_nxt    = 1'b1;
      fall_curr_sample_nxt = current_sample;
      fall_prev_sample_nxt = previous_sample;
      fall_coarse_time_nxt = (sampl_clk_ctr + i); // compensate input delay*
      $display("Rise found at i = %d, sampl_clk_ctr=%d", i, sampl_clk_ctr); // compensate input delay*
      pulse_active_nxt     = 1'b0;
    end

  end
end

// *We compensate 1-clock delay at the input and off-by-1 error of sampl_clk_ctr.
// sampl_clk_ctr start counting inmediatelly after reset but we want it to be 0 at the 1'st cycle 
// - 1 comes from the fact that we need time of a prev_sample for computing (we will add fraction to it later)
// alternatively one could pick curr_sample and then subtract fraction


// ----- Timestamp driven by 40MHz -----
logic [31:0] master_timestamp_40mhz;

always_ff @(posedge clk_timestamp or negedge rst_n) begin
  if (!rst_n) begin
    master_timestamp_40mhz <= 64'd0;
  end 
  else begin
    master_timestamp_40mhz <= master_timestamp_40mhz + 64'd1;
  end
end

// ----- Cross clock -----
// to add xdc_cdc type in tcl console: 
// set_property XPM_LIBRARIES {XPM_CDC} [current_project]
logic [31:0] master_timestamp_160mhz;

xpm_cdc_array_single #(
  .DEST_SYNC_FF(2),
  .INIT_SYNC_FF(0),   
  .SIM_ASSERT_CHK(0), 
  .SRC_INPUT_REG(1),
  .WIDTH(64)
) xpm_cdc_timestamp_inst (
  .src_clk(clk_timestamp),
  .src_in(master_timestamp_40mhz),
  .dest_clk(clk),
  .dest_out(master_timestamp_160mhz)
);


// ----- Timestamp in 160MHz -----
logic [31:0 ] master_timestamp_160mhz_q;
always_ff @(posedge clk) begin
  if (!rst_n) begin
    master_timestamp_rise <= 32'd0;
    master_timestamp_fall <= 32'd0;
    master_timestamp_160mhz_q <= 32'b0;
  end 
  else begin
    master_timestamp_160mhz_q <= master_timestamp_160mhz;
    master_timestamp_rise <= (rise_detected_2q) ? master_timestamp_160mhz : master_timestamp_rise;
    master_timestamp_fall <= (fall_detected_2q) ? master_timestamp_160mhz : master_timestamp_fall;
  end
end



// Count time between samples within 40MHz period
// Note that FPGA clock frequency differs from ADC sampling frequency
always_ff @(posedge clk) begin
  if (!rst_n) begin
    sampl_clk_ctr <= 16'd0;
  end
  else if (master_timestamp_160mhz != master_timestamp_160mhz_q) begin
    sampl_clk_ctr <= 16'd0;
  end
  else begin
    sampl_clk_ctr <= sampl_clk_ctr + SAMPLE_NUM_PER_CYCLE;
  end
end


endmodule
