module falling_interp_exp #(
  parameter FRAC = 8
)(
  input wire clk,
  input wire rst,

  input wire [11:0] prev_sample,
  input wire [11:0] curr_sample,
  input wire sample_valid_in,
  input wire [11:0] thr,

  output logic sample_valid_out,
  output logic [FRAC-1:0] frac
);

logic signed [16:0] numerator;
logic signed [16:0] denominator;
logic sample_valid_q, sample_valid_2q;

logic [31:0] result;

always_ff @(posedge clk) begin
  if (rst) begin
    numerator <= '0;
    denominator <= '0;
    result <= '0;
  end
  else if (sample_valid_in) begin
    numerator <= log2_lut(thr) - log2_lut(curr_sample);
    denominator <= log2_lut(prev_sample) - log2_lut(curr_sample);
  end

  if (denominator != 0)
    result <= (numerator <<< FRAC) / denominator;
  else
    result <= '0;
end

always_ff @ (posedge clk) begin
  if (rst) begin
    sample_valid_q <= 1'b0;
    sample_valid_2q <= 1'b0;
    sample_valid_out <= 1'b0;
    frac <= '0;
  end
  else begin
    sample_valid_q <= sample_valid_in;
    sample_valid_2q <= sample_valid_q;
    sample_valid_out <= sample_valid_2q;
    frac <= result[FRAC-1:0];
  end
end


function automatic [15:0] log2_lut(input logic [11:0] x);
  begin
    casez(x)
      12'b1???????????: log2_lut = 16'd2816; // Bit 11 active: 11 * 256
      12'b01??????????: log2_lut = 16'd2560; // Bit 10 active: 10 * 256
      12'b001?????????: log2_lut = 16'd2304; // Bit 9 active:  9 * 256 (Matches 0x367)
      12'b0001????????: log2_lut = 16'd2048; // Bit 8 active:  8 * 256
      12'b00001???????: log2_lut = 16'd1792; // Bit 7 active:  7 * 256
      12'b000001??????: log2_lut = 16'd1536; // Bit 6 active:  6 * 256
      12'b0000001?????: log2_lut = 16'd1280; // Bit 5 active:  5 * 256
      12'b00000001????: log2_lut = 16'd1024; // Bit 4 active:  4 * 256
      12'b000000001???: log2_lut = 16'd768;  // Bit 3 active:  3 * 256
      12'b0000000001??: log2_lut = 16'd512;  // Bit 2 active:  2 * 256
      12'b00000000001?: log2_lut = 16'd256;  // Bit 1 active:  1 * 256
      12'b000000000001: log2_lut = 16'd0;    // Bit 0 active:  0 * 256

      default:          log2_lut = 16'd0;    // x is exactly 0 (log2(0) is undefined)
    endcase
  end
endfunction

endmodule
