module output_sum #(
  parameter PORTS_WIDTH = 32
)(
  input wire clk_timestamp,      // ~40MHz
  input wire clk_data,
  input wire rst_n,

  input logic                   data_valid_in,
  input logic [PORTS_WIDTH-1:0] tot_in,
  input logic [PORTS_WIDTH-1:0] t_leading_edge_in,

  output logic                   data_valid_out,
  output logic [PORTS_WIDTH-1:0] tot_out,
  output logic [63:0]            t_leading_edge_out // Picosecond master timestamp
);


// ----- Local parameters -----
localparam bit [63:0] PERIOD_40M_PS = 64'd25_000;

// ----- Local veriables -----
logic [63:0] master_timestamp;
logic clk_timestamp_q, clk_timestamp_2q;


// --- Timestamp ---
always_ff @(posedge clk_data) begin
  clk_timestamp_q <= clk_timestamp;
  clk_timestamp_2q <= clk_timestamp_q;

  if (!rst_n) begin
    master_timestamp <= 64'd0;
  end 
  else if (clk_timestamp_q && !clk_timestamp_2q) begin
    master_timestamp <= master_timestamp + PERIOD_40M_PS;
  end
end


// --- Output buffer ---
always_ff @(posedge clk_data) begin
  if (!rst_n) begin
    data_valid_out      <= 1'b0;
    tot_out             <= '0;
    t_leading_edge_out  <= '0;
  end 
  else begin
    data_valid_out <= data_valid_in;

    if (data_valid_in) begin
      tot_out <= tot_in;

      t_leading_edge_out <= t_leading_edge_in + master_timestamp;
    end
  end
end

endmodule
