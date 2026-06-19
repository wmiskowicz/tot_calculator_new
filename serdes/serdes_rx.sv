
// This is a SerDes module for recieving data from ADC12DL3200.
// The data is coming via 4 buses (A-D), each 12-bit wide.
// Data is being sent on both clk_p and clk_n.
// 
// This module recieves 6 samples from each of 4 buses on each clock cycle therefore 24 samples.


module serdes_rx#(
    parameter SAMPLE_NUM_PER_CYCLE = 24
)(
  input wire rst_n,
  adc_bus_if.in bus_a,
  adc_bus_if.in bus_b,
  adc_bus_if.in bus_c,
  adc_bus_if.in bus_d,

  output logic clk_data,
  output logic [(SAMPLE_NUM_PER_CYCLE*12)-1:0] rx_data
);

// TBD: Add clock synchronisation, offset compsensation, stobe verification


// ----- Local parameters -----
localparam SERIALISATION_FACTOR = 6; // Forced by Vivado IP - don't change
localparam DATA_IN_WIDTH = 13;       // 12-bit data + strobe

// ----- Local variables -----
wire [DATA_IN_WIDTH*SERIALISATION_FACTOR-1:0] rx_dat_a, rx_dat_b, rx_dat_c, rx_dat_d;

// ----- Signal assignments -----
assign clk_data = clk_dat_a;


adc_bus_rx #(
  .DATA_IN_WIDTH(DATA_IN_WIDTH),
  .SERIALISATION_FACTOR(SERIALISATION_FACTOR)
) bus_a_rx (
  .rst_n    (rst_n),
  .bus_in   (bus_a),
  .clk_data (clk_dat_a),
  .rx_data  (rx_dat_a)
);

adc_bus_rx #(
  .DATA_IN_WIDTH(DATA_IN_WIDTH),
  .SERIALISATION_FACTOR(SERIALISATION_FACTOR)
) bus_b_rx (
  .rst_n    (rst_n),
  .bus_in   (bus_b),
  .clk_data (clk_dat_b),
  .rx_data  (rx_dat_b)
);

adc_bus_rx #(
  .DATA_IN_WIDTH(DATA_IN_WIDTH),
  .SERIALISATION_FACTOR(SERIALISATION_FACTOR)
) bus_c_rx (
  .rst_n    (rst_n),
  .bus_in   (bus_c),
  .clk_data (clk_dat_c),
  .rx_data  (rx_dat_c)
);

adc_bus_rx #(
  .DATA_IN_WIDTH(DATA_IN_WIDTH),
  .SERIALISATION_FACTOR(SERIALISATION_FACTOR)
) bus_d_rx (
  .rst_n    (rst_n),
  .bus_in   (bus_d),
  .clk_data (clk_dat_d),
  .rx_data  (rx_dat_d)
);


always_ff @(posedge clk_data) begin
  if (!rst_n) begin
    rx_data <= '0;
  end else begin
    for (int i = 0; i < 6; i++) begin

      // Bank A: Samples 0, 4, 8, 12
      rx_data[(i*48 + 0)  +: 12] <= rx_dat_a[(i*13 + 1) +: 12];

      // Bank B: Samples 1, 5, 9, 13
      rx_data[(i*48 + 12) +: 12] <= rx_dat_b[(i*13 + 1) +: 12];

      // Bank C: Samples 2, 6, 10, 14
      rx_data[(i*48 + 24) +: 12] <= rx_dat_c[(i*13 + 1) +: 12];

      // Bank D: Samples 3, 7, 11, 15
      rx_data[(i*48 + 36) +: 12] <= rx_dat_d[(i*13 + 1) +: 12];
    end
  end
end


endmodule
