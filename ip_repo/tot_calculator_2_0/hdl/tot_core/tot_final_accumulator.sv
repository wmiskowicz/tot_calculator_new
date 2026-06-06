module tot_final_accumulator #(
  parameter WIDTH = 32,
  parameter FRAC  = 8
)(
  input wire clk,
  input wire rst_n,

  input wire rise_valid,
  input wire fall_valid,

  input wire [WIDTH-1:0] master_timestamp_rise_in,
  input wire [WIDTH-1:0] master_timestamp_fall_in,

  input wire [WIDTH-1:0] rise_coarse_time,
  input wire [WIDTH-1:0] fall_coarse_time,

  input wire [FRAC-1:0] rise_frac,
  input wire [FRAC-1:0] fall_frac,

  output logic [WIDTH-1:0] t_trailing_edge,
  output logic [WIDTH-1:0] t_leading_edge,

  output logic [WIDTH-1:0] master_timestamp_rise_out,
  output logic [WIDTH-1:0] master_timestamp_fall_out,

  output logic data_valid
);

logic [WIDTH-1:0] t_rising_q, t_rising_2q;
logic [WIDTH-1:0] master_timestamp_rise_q, master_timestamp_rise_2q;
logic [WIDTH-1:0] master_timestamp_fall_q, master_timestamp_fall_2q;
logic [WIDTH-1:0] t_falling_q, t_falling_2q;


logic             rise_valid_q, rise_valid_2q;
logic             fall_valid_q, fall_valid_2q, fall_valid_3q;
logic [WIDTH-1:0] rise_coarse_time_q, rise_coarse_time_2q;
logic [WIDTH-1:0] fall_coarse_time_q, fall_coarse_time_2q;
logic [FRAC-1:0]  rise_frac_q, rise_frac_2q;
logic [FRAC-1:0]  fall_frac_q, fall_frac_2q;


// Input buffer
always_ff @ (posedge clk) begin
  if (!rst_n) begin
    rise_valid_q <= 1'b0;
    fall_valid_q <= 1'b0;

    rise_coarse_time_q <= 32'd0;
    fall_coarse_time_q <= 32'd0;

    rise_frac_q <= 8'd0;
    fall_frac_q <= 8'd0;
  end
  else begin
    rise_valid_q <= rise_valid;
    fall_valid_q <= fall_valid;
    rise_valid_2q <= rise_valid_q;
    fall_valid_2q <= fall_valid_q;
    fall_valid_3q <= fall_valid_2q;

    rise_coarse_time_q <= rise_coarse_time;
    fall_coarse_time_q <= fall_coarse_time;
    rise_coarse_time_2q <= rise_coarse_time_q;
    fall_coarse_time_2q <= fall_coarse_time_q;

    rise_frac_q <= rise_frac;
    fall_frac_q <= fall_frac;
    rise_frac_2q <= rise_frac_q;
    fall_frac_2q <= fall_frac_q;
  end
end




always_ff @(posedge clk) begin
  if (!rst_n) begin
    t_trailing_edge <= '0;
    t_leading_edge <= '0;
    data_valid <= 1'b0;

    t_rising_q <= '0;
    t_falling_q <= '0;
    t_rising_2q <= '0;
    t_falling_2q <= '0;

    master_timestamp_rise_q <= '0;
    master_timestamp_fall_q <= '0;

    master_timestamp_rise_2q <= '0;
    master_timestamp_fall_2q <= '0;

    master_timestamp_rise_out <= '0;
    master_timestamp_fall_out <= '0;
  end
  else begin
    t_rising_2q <= t_rising_q;
    t_falling_2q <= t_falling_q;
    master_timestamp_rise_q <= master_timestamp_rise_in;
    master_timestamp_fall_q <= master_timestamp_fall_in;

    data_valid <= 1'b0;

    if (rise_valid_q) begin
      t_rising_q <= (rise_coarse_time_q << FRAC) | rise_frac_q;
      master_timestamp_rise_2q <= master_timestamp_rise_q;
    end

    if (fall_valid_q) begin
      t_falling_q <= (fall_coarse_time_q << FRAC) | fall_frac_q;
      master_timestamp_fall_2q <= master_timestamp_fall_q;
    end

    if (fall_valid_3q) begin
      master_timestamp_rise_out <= master_timestamp_rise_2q;
      master_timestamp_fall_out <= master_timestamp_fall_2q;
      t_trailing_edge <= t_falling_2q;
      t_leading_edge <= t_rising_2q;
      data_valid <= 1'b1;
    end
    
  end
end

endmodule
