
interface adc_bus_if;
// Interface for a singular bus of ADC
  
  logic        clk_p;  // DxCLK+
  logic        clk_n;  // DxCLK-
  logic [11:0] dat_p;  // Dx[11:0]+
  logic [11:0] dat_n;  // Dx[11:0]-
  logic        str_p;  // DxSTR+
  logic        str_n;  // DxSTR-

  modport in (
    input  clk_p,
    input  clk_n,
    input  dat_p,
    input  dat_n,
    input  str_p,
    input  str_n
  );

  modport out (
    output  clk_p,
    output  clk_n,
    output  dat_p,
    output  dat_n,
    output  str_p,
    output  str_n
  );

endinterface: adc_bus_if
