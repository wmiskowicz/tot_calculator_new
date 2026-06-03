module rising_interp_exp #(
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
    numerator <= log2_lut(thr) - log2_lut(prev_sample);
    denominator <= log2_lut(curr_sample) - log2_lut(prev_sample);
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
            12'b1???????????: log2_lut = 16'd2816 + x[10:3]; 
            12'b01??????????: log2_lut = 16'd2560 + x[9:2];  
            12'b001?????????: log2_lut = 16'd2304 + x[8:1];
            12'b0001????????: log2_lut = 16'd2048 + x[7:0];  
            12'b00001???????: log2_lut = 16'd1792 + {x[6:0], 1'b0}; 
            12'b000001??????: log2_lut = 16'd1536 + {x[5:0], 2'b0}; 
            12'b0000001?????: log2_lut = 16'd1280 + {x[4:0], 3'b0}; 
            12'b00000001????: log2_lut = 16'd1024 + {x[3:0], 4'b0}; 
            12'b000000001???: log2_lut = 16'd768  + {x[2:0], 5'b0}; 
            12'b0000000001??: log2_lut = 16'd512  + {x[1:0], 6'b0}; 
            12'b00000000001?: log2_lut = 16'd256  + {x[0],   7'b0}; 
            12'b000000000001: log2_lut = 16'd0;    
            default:          log2_lut = 16'd0;    
        endcase
    end
endfunction

endmodule
