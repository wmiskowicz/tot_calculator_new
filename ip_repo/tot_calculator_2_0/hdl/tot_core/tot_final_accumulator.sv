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
logic [WIDTH-1:0] fall_timestamp;
logic fall_valid_q;

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    tot <= '0;
    t_leading_edge <= '0;
    data_valid <= 1'b0;
    fall_valid_q <= 1'b0;

    rise_timestamp <= '0;
    fall_timestamp <= '0;
  end
  else begin
    fall_valid_q <= fall_valid;
    rise_timestamp_q <= rise_timestamp;
    data_valid <= 1'b0;

    if (rise_valid) begin
      rise_timestamp <= (rise_coarse_time << FRAC) | rise_frac;
    end

    if (fall_valid) begin
      fall_timestamp <= (fall_coarse_time << FRAC) | fall_frac;
    end

    if (fall_valid_q) begin
      tot <= fall_timestamp - rise_timestamp_q;
      t_leading_edge <= rise_timestamp;
      data_valid <= 1'b1;
    end
    

  end
end

endmodule
