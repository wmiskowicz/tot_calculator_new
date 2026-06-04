module tot_core_top #(
  parameter SAMPLE_NUM_PER_CYCLE = 1,
  parameter WIDTH = 32,
  parameter FRAC = 8,
  parameter bit [15:0] SAMPLING_CLK_PERIOD_PS = 16'd416, // 1.6 GHz sampling clock
  parameter bit [31:0] TIMESTAMP_CLK_PERIOD_PS = 32'd25_000 // 40 MHz timestamp clock
)(
  input wire clk,
  input wire clk_40MHz,
  input wire rst_n,

  input wire [WIDTH-1:0] thr,
  input wire [SAMPLE_NUM_PER_CYCLE*12-1:0] sample,

  output logic [WIDTH-1:0] tot,
  output logic [63:0] t_leading_edge,

  output logic data_valid
);

// ============================================================
// Internal signals
// ============================================================

wire data_valid_in;
wire data_valid_out;

wire [WIDTH-1:0] t_trailing_edge;
wire [WIDTH-1:0] tot_out;

wire [WIDTH-1:0] t_leading_edge_in;
wire [63:0] t_leading_edge_out;
wire [31:0] master_timestamp_rise, master_timestamp_fall;

// Edge detection

logic rise_detected;
logic fall_detected;
logic fall_frac_valid;
logic raise_frac_valid;

// ADC samples around threshold crossing

logic [11:0] rise_prev_sample;
logic [11:0] rise_curr_sample;

logic [11:0] fall_prev_sample;
logic [11:0] fall_curr_sample;

// Coarse timestamps

logic [WIDTH-1:0] rise_coarse_time;
logic [WIDTH-1:0] rise_time;
logic [WIDTH-1:0] fall_coarse_time;
logic [WIDTH-1:0] fall_time;

// Fractional timestamps

logic [FRAC-1:0] rise_frac;
logic [FRAC-1:0] fall_frac;


assign data_valid = data_valid_out;
assign t_leading_edge = t_leading_edge_out;
assign tot = tot_out;

// ============================================================
// Coarse ToT core
// ============================================================

coarse_tot_core #(
  .SAMPLE_NUM_PER_CYCLE(SAMPLE_NUM_PER_CYCLE),
  .WIDTH(WIDTH)
)
u_coarse_tot_core
(
  .clk(clk),
  .clk_timestamp     (clk_40MHz),
  .rst_n(rst_n),

  .thr(thr),

  .sample(sample),

  .rise_detected(rise_detected),
  .fall_detected(fall_detected),

  .rise_prev_sample(rise_prev_sample),
  .rise_curr_sample(rise_curr_sample),

  .fall_prev_sample(fall_prev_sample),
  .fall_curr_sample(fall_curr_sample),

  .rise_coarse_time(rise_coarse_time),
  .fall_coarse_time(fall_coarse_time),
  .master_timestamp_rise(master_timestamp_rise),
  .master_timestamp_fall(master_timestamp_fall)
);



interp_exp #(
  .FRAC(FRAC),
  .IS_FALLING(0)
)
u_rising_interp_exp
(
  .clk(clk),
  .rst(!rst_n),
  .prev_sample(rise_prev_sample),
  .curr_sample(rise_curr_sample),
  .event_time_in(rise_coarse_time),
  .sample_valid_in(rise_detected),
  .thr(thr[11:0]),

  .event_time_out(rise_time),
  .sample_valid_out(raise_frac_valid),
  .frac(rise_frac)
);

interp_exp #(
  .FRAC(FRAC),
  .IS_FALLING(1)
)
u_falling_interp_exp
(
  .clk(clk),
  .rst(!rst_n),
  .prev_sample(fall_prev_sample),
  .curr_sample(fall_curr_sample),
  .event_time_in(fall_coarse_time),
  .sample_valid_in(fall_detected),
  .thr(thr[11:0]),

  .event_time_out(fall_time),
  .sample_valid_out(fall_frac_valid),
  .frac(fall_frac)
);


tot_final_accumulator #(
  .WIDTH(WIDTH),
  .FRAC(FRAC)
)
u_tot_final_accumulator
(
  .clk(clk),
  .rst_n(rst_n),

  .rise_valid(raise_frac_valid),
  .fall_valid(fall_frac_valid),

  .rise_coarse_time(rise_time),
  .fall_coarse_time(fall_time),

  .rise_frac(rise_frac),
  .fall_frac(fall_frac),

  .t_trailing_edge(t_trailing_edge),
  .t_leading_edge(t_leading_edge_in),
  .data_valid(data_valid_in)
);



output_sum #(
  .PORTS_WIDTH(WIDTH),
  .SAMPLE_NUM_PER_CYCLE(SAMPLE_NUM_PER_CYCLE),
  .SAMPLING_CLK_PERIOD_PS(SAMPLING_CLK_PERIOD_PS),
  .TIMESTAMP_CLK_PERIOD_PS(TIMESTAMP_CLK_PERIOD_PS)
)
u_output_sum (
  .clk_data          (clk),
  .rst_n             (rst_n),

  .data_valid_in     (data_valid_in),
  .data_valid_out    (data_valid_out),
  .master_timestamp_rise(master_timestamp_rise),
  .master_timestamp_fall(master_timestamp_fall),
  .t_leading_edge_in (t_leading_edge_in),
  .t_leading_edge_out(t_leading_edge_out), //Picosecond master timestamp
  .t_trailing_edge_in(t_trailing_edge),
  .tot_out           (tot_out)
);

endmodule
