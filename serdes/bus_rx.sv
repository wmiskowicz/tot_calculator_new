module adc_bus_rx #(
  parameter DATA_IN_WIDTH = 13,
  parameter SERIALISATION_FACTOR = 6
)(
  input  logic        rst_n,
  adc_bus_if.in       bus_in,

  output logic [77:0] rx_data,      // Deserialized 12-bit sample
  output logic        clk_data
);

localparam DEV_W = SERIALISATION_FACTOR * DATA_IN_WIDTH;

selectio_wiz_1 #(
  .SYS_W(DATA_IN_WIDTH),
  .DEV_W(DEV_W)
)
u_selectio_wiz_1 (
  .clk_in_n            (bus_in.clk_n),
  .clk_in_p            (bus_in.clk_p),
  .clk_reset           (0),
  .io_reset            (!rst_n),

  .bitslip             (13'd0),
  .clk_to_pins_n       (),
  .clk_to_pins_p       (),
  .data_in_from_pins_n ({bus_in.dat_n, bus_in.str_n}),
  .data_in_from_pins_p ({bus_in.dat_p, bus_in.str_p}),
  .data_in_to_device   (rx_data),

  .clk_div_out         (clk_data), //slow output clk
  .data_out_from_device(78'd0),
  .data_out_to_pins_n  (),
  .data_out_to_pins_p  ()
);

endmodule
