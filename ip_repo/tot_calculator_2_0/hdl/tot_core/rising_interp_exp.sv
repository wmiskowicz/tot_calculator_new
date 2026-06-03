module rising_interp_exp #(
  parameter FRAC = 8
)(
  input wire [11:0] prev_sample,
  input wire [11:0] curr_sample,
  input wire [11:0] thr,

  output logic [FRAC-1:0] frac
);

function automatic [15:0]
log2_lut(input logic [11:0] x);

begin

  casez(x)

    12'b1???????????: log2_lut = 16'd2816;
    12'b01??????????: log2_lut = 16'd2560;
    12'b001?????????: log2_lut = 16'd2304;

    default: log2_lut = 16'd0;

  endcase

end

endfunction

logic signed [16:0] numerator;
logic signed [16:0] denominator;

logic [31:0] temp;

always_comb
begin

  numerator =
    log2_lut(thr)
    -
    log2_lut(prev_sample);

  denominator =
    log2_lut(curr_sample)
    -
    log2_lut(prev_sample);

  if (denominator != 0)
    temp = (numerator <<< FRAC) / denominator;
  else
    temp = '0;

  frac = temp[FRAC-1:0];

end

endmodule