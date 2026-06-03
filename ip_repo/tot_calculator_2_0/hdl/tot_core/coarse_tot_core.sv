module coarse_tot_core #(
  parameter SAMPLE_NUM_PER_CYCLE = 24,
  parameter WIDTH = 32
)(
  input  wire clk,
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
  output logic [WIDTH-1:0] fall_coarse_time
);


// ----- Typedefs -----
typedef logic [SAMPLE_NUM_PER_CYCLE-1:0][11:0] adc_sample_vector_t;

// ----- Local variables -----
adc_sample_vector_t adc_samples_q, adc_samples_2q;

logic pulse_active, pulse_active_nxt, pulse_active_q;
logic [WIDTH-1:0] coarse_counter;

logic [11:0] rise_curr_sample_nxt, rise_curr_sample_q;
logic [11:0] rise_prev_sample_nxt, rise_prev_sample_q;
logic [11:0] fall_curr_sample_nxt, fall_curr_sample_q;
logic [11:0] fall_prev_sample_nxt, fall_prev_sample_q;

logic rise_detected_nxt, rise_detected_q;
logic fall_detected_nxt, fall_detected_q;

logic [WIDTH-1:0] rise_coarse_time_nxt, rise_coarse_time_q;
logic [WIDTH-1:0] fall_coarse_time_nxt, fall_coarse_time_q;

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pulse_active     <= 1'b0;
    coarse_counter   <= '0;
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
    pulse_active_q  <= 1'b0;

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

    coarse_counter <= coarse_counter + 1'b1;
    adc_samples_q <= { >> { sample } };
    adc_samples_2q <= adc_samples_q;


    pulse_active  <= pulse_active_q;
    rise_detected <= rise_detected_q;
    fall_detected <= fall_detected_q;

    rise_curr_sample <= rise_curr_sample_q;
    rise_prev_sample <= rise_prev_sample_q;
    rise_coarse_time <= rise_coarse_time_q;

    fall_curr_sample <= fall_curr_sample_q;
    fall_prev_sample <= fall_prev_sample_q;
    fall_coarse_time <= fall_coarse_time_q;
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
      rise_coarse_time_nxt = (coarse_counter * SAMPLE_NUM_PER_CYCLE) + i;
      pulse_active_nxt     = 1'b1;
    end

    // --- Falling edge ---
    if ((previous_sample >= thr[11:0]) && (current_sample < thr[11:0])) begin
      fall_detected_nxt    = 1'b1;
      fall_curr_sample_nxt = current_sample;
      fall_prev_sample_nxt = previous_sample;
      fall_coarse_time_nxt = (coarse_counter * SAMPLE_NUM_PER_CYCLE) + i;
      pulse_active_nxt     = 1'b0;
    end

  end
end


endmodule
