`timescale 1ns/1ps

module adc_csv_streamer #(
  parameter string CSV_FILE = "C:/AGH_archive/Semestr_MI/SDUP/Project/tot_final_sim/sim/python/data/shaper_output.csv",
  parameter real   V_MIN    = -1.0,          // Voltage corresponding to 12'h000
  parameter real   V_MAX    =  1.0           // Voltage corresponding to 12'hFFF
)(
  input  logic        sample_clk,
  input  logic        rst_n,
  output logic [11:0] adc_data,
  output logic        adc_valid
);

// File handling descriptors
int file_handle;
int status;

// Temporary variables for parsing
real dummy_time;
real csv_voltage;
string header_line;

// Internal control
logic file_done;

initial begin
  adc_data   = 12'h0;
  adc_valid  = 1'b0;
  file_done  = 1'b0;

  // Open the CSV file for reading
  file_handle = $fopen(CSV_FILE, "r");
  if (file_handle == 0) begin
    $error("[ADC_STREAM] Failed to open file: %s", CSV_FILE);
    $finish;
  end

  // Skip the header line ("Time_s,Voltage_V")
  status = $fgets(header_line, file_handle);
  if (status == 0) begin
    $error("[ADC_STREAM] CSV file is empty or corrupted.");
    $finish;
  end
end

// Read and stream data on the rising edge of the sampling clock
always @(posedge sample_clk or negedge rst_n) begin
  if (!rst_n) begin
    adc_data  <= 12'h0;
    adc_valid <= 1'b0;
  end else if (!file_done) begin
    // Parse comma-separated real values: %f,%f
    status = $fscanf(file_handle, "%f,%f\n", dummy_time, csv_voltage);

    if (status == 2) begin
      // Clamping the voltage to the ADC's physical limits
      real clamped_v = csv_voltage;
      if (clamped_v < V_MIN) clamped_v = V_MIN;
      if (clamped_v > V_MAX) clamped_v = V_MAX;

      // Scale and quantize: Map [V_MIN, V_MAX] to [0, 4095]
      // Adding 0.5 performs proper rounding instead of truncation
      adc_data  <= $rtoi(((clamped_v - V_MIN) / (V_MAX - V_MIN)) * 4095.0 + 0.5);
      adc_valid <= 1'b1;
    end else begin
      // End of file or parsing error
      $display("[ADC_STREAM] Reached End of CSV File or formatting mismatch.");
      file_done  <= 1'b1;
      adc_valid  <= 1'b0;
      $fclose(file_handle);
    end
  end else begin
    adc_valid <= 1'b0; // No more valid data available
  end
end

endmodule