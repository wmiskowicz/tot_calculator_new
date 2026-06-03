module output_sum #(
  parameter PORTS_WIDTH = 32,
  parameter FRAC = 8,
  parameter bit [15:0] SAMPLING_CLK_PERIOD_PS = 15'd625,
  parameter bit [31:0] TIMESTAMP_CLK_PERIOD_PS = 32'd25_000
)(
  input wire clk_data,
  input wire rst_n,

  input logic                     data_valid_in,
  input logic [PORTS_WIDTH-1:0]   tot_in,
  input logic [PORTS_WIDTH-1:0]   t_leading_edge_in, // format: [31-FRAC:FRAC]
  input logic [63:0]              master_timestamp_in,

  output logic                    data_valid_out,
  output logic [PORTS_WIDTH-1:0]  tot_out,
  output logic [63:0]             t_leading_edge_out // Picosecond master timestamp
);

// ----- Local variables -----

logic [2:0]  vld_pipe;
logic [PORTS_WIDTH-1:0] tot_pipe [2:0];

logic [63:0] t_leading_edge_q;
logic [63:0] t_leading_edge_2q;



// --- Math & Output Pipeline ---
always_ff @(posedge clk_data) begin
  if (!rst_n) begin
    vld_pipe           <= '0;
    data_valid_out     <= 1'b0;
    tot_out            <= '0;
    t_leading_edge_q   <= '0;
    t_leading_edge_2q  <= '0;
    t_leading_edge_out <= '0;
    for(int i=0; i<3; i++) tot_pipe[i] <= '0;
  end else begin
    vld_pipe    <= {vld_pipe[1:0], data_valid_in};
    tot_pipe[0] <= tot_in;
    tot_pipe[1] <= tot_pipe[0];
    tot_pipe[2] <= tot_pipe[1];

    t_leading_edge_q <= 64'(t_leading_edge_in * SAMPLING_CLK_PERIOD_PS);
    t_leading_edge_2q <= (t_leading_edge_q >> FRAC) + (64'(master_timestamp_in) * TIMESTAMP_CLK_PERIOD_PS);


    data_valid_out     <= vld_pipe[2];
    if (vld_pipe[2]) begin
      tot_out            <= tot_pipe[2];
      t_leading_edge_out <= t_leading_edge_2q;
    end
  end
end

endmodule
