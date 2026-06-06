module output_sum #(
  parameter PORTS_WIDTH = 32,
  parameter FRAC = 8,
  SAMPLE_NUM_PER_CYCLE = 24,
  parameter bit [15:0] SAMPLING_CLK_PERIOD_PS = 16'd616,
  parameter bit [31:0] TIMESTAMP_CLK_PERIOD_PS = 32'd25_000
)(
  input wire clk_data,
  input wire rst_n,

  input logic                     data_valid_in,
  input logic [PORTS_WIDTH-1:0]   t_trailing_edge_in,
  input logic [PORTS_WIDTH-1:0]   t_leading_edge_in, // format: [31-FRAC:FRAC]
  input logic [31:0]              master_timestamp_rise,
  input logic [31:0]              master_timestamp_fall,

  output logic                    data_valid_out,
  output logic [PORTS_WIDTH-1:0]  tot_out,
  output logic [63:0]             t_leading_edge_out // Picosecond master timestamp
);

// ----- Local variables -----

logic [2:0]  vld_pipe;
logic [63:0] tot_q;
logic [63:0] t_leading_edge_q, t_leading_edge_2q;
logic [63:0] t_trailing_edge_q, t_trailing_edge_2q;



// --- Math & Output Pipeline ---
always_ff @(posedge clk_data) begin
  if (!rst_n) begin
    vld_pipe           <= '0;
    data_valid_out     <= 1'b0;
    tot_out            <= '0;
    t_leading_edge_q   <= '0;
    t_leading_edge_2q  <= '0;
    t_trailing_edge_q  <= '0;
    t_trailing_edge_2q <= '0;
    t_leading_edge_out <= '0;
    tot_q <= '0;
  end 
  else begin
    vld_pipe <= {vld_pipe[1:0], data_valid_in};

    t_leading_edge_q <= 64'(t_leading_edge_in * SAMPLING_CLK_PERIOD_PS);
    // because of clock-crossing we reset small counter 2 times less
    t_leading_edge_2q <= (t_leading_edge_q >> FRAC) + 64'(master_timestamp_rise * TIMESTAMP_CLK_PERIOD_PS);
    

    t_trailing_edge_q <= 64'(t_trailing_edge_in * SAMPLING_CLK_PERIOD_PS);
    t_trailing_edge_2q <= (t_trailing_edge_q >> FRAC) + 64'(master_timestamp_fall * TIMESTAMP_CLK_PERIOD_PS); 

    tot_q <= t_trailing_edge_2q - t_leading_edge_2q;
    
    data_valid_out     <= vld_pipe[2];
    if (vld_pipe[2]) begin
      tot_out            <= tot_q[31:0];
      t_leading_edge_out <= t_leading_edge_2q - ((3 * SAMPLE_NUM_PER_CYCLE) * SAMPLING_CLK_PERIOD_PS); // Compensate offset
    end
  end
end

endmodule
