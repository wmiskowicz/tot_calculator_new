`timescale 1ns/1ps

module adc_csv_streamer2 #(
  parameter string CSV_FILE = "C:/AGH_archive/Semestr_MI/SDUP/Project/tot_final_sim/sim/python/data/shaper_output.csv",
  parameter real   V_MIN    = -1.0,         // Voltage corresponding to 12'h000
  parameter real   V_MAX    =  1.0,         // Voltage corresponding to 12'hFFF
  parameter int    SAMPLE_NUM_PER_CYCLE = 24 // Number of packed 12-bit samples per clock
)(
  input  logic                                            sample_clk,
  input  logic                                            rst_n,
  output logic [(12*SAMPLE_NUM_PER_CYCLE)-1:0]            adc_data,
  output logic                                            adc_valid
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
  adc_data   = '0;
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
    adc_data  <= '0;
    adc_valid <= 1'b0;
  end else if (!file_done) begin

    // Automatic variables for local loop execution
    automatic bit logic_valid = 1'b1;
    automatic logic [(12*SAMPLE_NUM_PER_CYCLE)-1:0] temp_data = '0;

    // Loop to assemble the multi-sample vector in a single clock cycle
    for (int i = 0; i < SAMPLE_NUM_PER_CYCLE; i++) begin
      status = $fscanf(file_handle, "%f,%f\n", dummy_time, csv_voltage);

      if (status == 2) begin
        real clamped_v = csv_voltage;
        logic [11:0] quantized_val;

        // Clamping the voltage to the ADC's physical limits
        if (clamped_v < V_MIN) clamped_v = V_MIN;
        if (clamped_v > V_MAX) clamped_v = V_MAX;

        // Scale and quantize
        quantized_val = $rtoi(((clamped_v - V_MIN) / (V_MAX - V_MIN)) * 4095.0 + 0.5);

        // Pack into vector: Sample 0 occupies lowest bits, Sample N-1 occupies highest bits.
        // Adjust ordering if your SerDes mapping expects Sample 0 in MSB.
        temp_data[i*12 +: 12] = quantized_val;
        // temp_data[((SAMPLE_NUM_PER_CYCLE - 1 - i) * 12) +: 12] = quantized_val;

      end else begin
        // End of file or parsing error encountered mid-cycle
        $display("[ADC_STREAM] Reached End of CSV File or formatting mismatch.");
        file_done   <= 1'b1;
        logic_valid  = 1'b0; // Flag that this block/subsequent blocks are invalid
        $fclose(file_handle);
        break; // Break out of the loop early
      end
    end

    // Assign the packed vector to the sequential output ports
    adc_data  <= temp_data;
    adc_valid <= logic_valid;

  end else begin
    adc_valid <= 1'b0; // No more valid data available
  end
end

endmodule