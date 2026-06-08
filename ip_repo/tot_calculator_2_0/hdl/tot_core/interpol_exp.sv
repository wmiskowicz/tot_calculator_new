module interp_exp #(
  parameter FRAC = 8,
  parameter IS_FALLING = 0, // Falling edge = 0; Rising edge = 1\
  // This parameters is for compensating underflow
  parameter TIMESTAMP_TO_OP_CLK_FACTOR = 96 // = (FREQ_FPGA_CLK / FREQ_SAMPLING_CLK) * SAMPLE_NUM_PER_CYCLE
)(
  input wire clk,
  input wire rst,

  input wire [11:0] prev_sample,
  input wire [11:0] curr_sample,
  input wire sample_valid_in,
  input wire [31:0] event_time_in,
  input wire [63:0] master_timestamp_in,
  input wire [11:0] thr,

  output logic [31:0] event_time_out,
  output logic [63:0] master_timestamp_out,
  output logic sample_valid_out,
  output logic [FRAC-1:0] frac
);

logic signed [15:0] numerator;
logic signed [15:0] denominator;
logic sample_valid_q;
logic div_valid;

logic [31:0] result;
logic divide_en;

logic [11:0] prev_sample_q;
logic [11:0] curr_sample_q;


always_ff @(posedge clk) begin
  if (rst) begin
    prev_sample_q <= 12'b0;
    curr_sample_q <= 12'b0;
  end
  else if (sample_valid_in) begin

    if (IS_FALLING) begin

      if (curr_sample > prev_sample) begin
        curr_sample_q <= curr_sample;
        prev_sample_q <= prev_sample + TIMESTAMP_TO_OP_CLK_FACTOR;
      end
      else begin
        curr_sample_q <= curr_sample;
        prev_sample_q <= prev_sample;  
      end

    end
    else begin

      if (curr_sample < prev_sample) begin
        curr_sample_q <= curr_sample + TIMESTAMP_TO_OP_CLK_FACTOR;
        prev_sample_q <= prev_sample;
      end
      else begin
        curr_sample_q <= curr_sample;
        prev_sample_q <= prev_sample;  
      end

    end
  end


end

always_ff @(posedge clk) begin
  if (rst) begin
    numerator   <= '0;
    denominator <= '0;
    sample_valid_q <= 1'b0;
    divide_en <= 1'b0;
  end
  else begin
    if (IS_FALLING) begin
      numerator   <= log2_lut(thr) - log2_lut(curr_sample_q);
      denominator <= log2_lut(prev_sample_q) - log2_lut(curr_sample_q);
    end
    else begin
      numerator   <= log2_lut(thr) - log2_lut(prev_sample_q);
      denominator <= log2_lut(curr_sample_q) - log2_lut(prev_sample_q);
    end

    sample_valid_q <= sample_valid_in;
    divide_en <= sample_valid_q;
  end
end


always_ff @ (posedge clk) begin
  if (rst) begin
    sample_valid_out <= 1'b0;
    frac <= '0;
  end
  else begin

    if (div_valid) begin
      sample_valid_out <= 1'b1;
      frac <= result[FRAC-1:0];
    end
    else begin
      sample_valid_out <= 1'b0;
    end

  end
end


fifo_generator_0 fifo_coarse (
	.clk        (clk),
	.srst       (rst),

  .wr_en      (sample_valid_in),
	.din        (event_time_in),
	.empty      (),
	.full       (),
	.rd_en      (div_valid),
	.dout       (event_time_out),
	.rd_rst_busy(),

	.wr_rst_busy()
);

fifo_timestamp fifo_timestamp (
	.clk        (clk),
	.srst       (rst),

  .wr_en      (sample_valid_in),
	.din        (master_timestamp_in),
	.empty      (),
	.full       (),
	.rd_en      (div_valid),
	.dout       (master_timestamp_out),
	.rd_rst_busy(),

	.wr_rst_busy()
);

div_gen_0 u_div_gen_0 (
  .aclk(clk),
  .s_axis_dividend_tvalid(divide_en),
  .s_axis_dividend_tdata(numerator <<< FRAC),
  .s_axis_divisor_tvalid(divide_en),
  .s_axis_divisor_tdata(denominator),
  .m_axis_dout_tvalid(div_valid),
  .m_axis_dout_tdata(result)
);


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
