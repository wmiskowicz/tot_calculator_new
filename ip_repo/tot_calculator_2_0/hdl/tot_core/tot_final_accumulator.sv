module tot_final_accumulator #(
  parameter WIDTH = 32,
  parameter FRAC  = 8
)(
  input wire clk,
  input wire rst_n,

  input wire rise_valid,
  input wire fall_valid,

  input wire [WIDTH-1:0] rise_coarse_time,
  input wire [WIDTH-1:0] fall_coarse_time,

  input wire [FRAC-1:0] rise_frac,
  input wire [FRAC-1:0] fall_frac,

  output logic [WIDTH-1:0] tot,
  output logic [WIDTH-1:0] t_leading_edge,

  output logic data_valid
);

logic [WIDTH-1:0] rise_timestamp;
logic [WIDTH-1:0] rise_timestamp_q;
logic [WIDTH-1:0] fall_timestamp, fall_timestamp_q;


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
    tot <= '0;
    t_leading_edge <= '0;
    data_valid <= 1'b0;

    rise_timestamp <= '0;
    fall_timestamp <= '0;
    rise_timestamp_q <= '0;
    fall_timestamp_q <= '0;
  end
  else begin
    rise_timestamp_q <= rise_timestamp;
    fall_timestamp_q <= fall_timestamp;

    data_valid <= 1'b0;

    if (rise_valid_q) begin
      rise_timestamp <= (rise_coarse_time_q << FRAC) | rise_frac_q;
    end

    if (fall_valid_q) begin
      fall_timestamp <= (fall_coarse_time_q << FRAC) | fall_frac_q;
    end

    if (fall_valid_3q) begin
      tot <= fall_timestamp_q - rise_timestamp_q;
      t_leading_edge <= rise_timestamp_q;
      data_valid <= 1'b1;
    end
    
  end
end

endmodule
