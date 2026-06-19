// Individual Bus Driver (handles the queue and pin driving)
`ifndef ADC_BFM_SV
`define ADC_BFM_SV

  class adc_bus_driver;
    virtual adc_bus_if.out vif;
    int frame_len;
    int id;
    logic [11:0] queue[$];
    int sample_count = 0;

    function new(virtual adc_bus_if.out v, int f, int i);
      this.vif = v;
      this.frame_len = f;
      this.id = i;
    endfunction

    // This replaces the "push_sample" task
    task push(input [11:0] val);
      queue.push_back(val);
    endtask

    // The "Engine" - Run this in a fork
    task run(real bit_clk_period_ps);
      vif.clk_p = 0;
      vif.clk_n = 1;

      #(bit_clk_period_ps/2);

      forever begin
        logic [11:0] current_val;

        if (queue.size() > 0) begin
          current_val = queue.pop_front();
        end else begin
          // Unique fallback per bus so we can identify "empty" states
          current_val = (12'hA00 + (id << 8)) + sample_count;
        end

        // Drive Data
        vif.dat_p = current_val;
        vif.dat_n = ~current_val;

        // Strobe logic
        if (sample_count == (frame_len - 1)) begin
          vif.str_p = 1'b1;
          vif.str_n = 1'b0;
          sample_count = 0;
        end else begin
          vif.str_p = 1'b0;
          vif.str_n = 1'b1;
          sample_count++;
        end

        #(bit_clk_period_ps);
      end
    endtask
  endclass

  // Top Level Driver (Contains all 4 buses)
  class adc_full_driver;
    adc_bus_driver bus[4];

    function new(
        virtual adc_bus_if.out a,
        virtual adc_bus_if.out b,
        virtual adc_bus_if.out c,
        virtual adc_bus_if.out d,
        int frame_len
      );
      bus[0] = new(a, frame_len, 0);
      bus[1] = new(b, frame_len, 1);
      bus[2] = new(c, frame_len, 2);
      bus[3] = new(d, frame_len, 3);
    endfunction

    task run(real bit_clk_period_ps);
      #200ns;
      fork
        bus[0].run(bit_clk_period_ps);
        bus[1].run(bit_clk_period_ps);
        bus[2].run(bit_clk_period_ps);
        bus[3].run(bit_clk_period_ps);

        // Also generate the BUS CLOCKS (Source Synchronous)
        // Shifted by 90 degrees for center-alignment
        forever begin
          #(bit_clk_period_ps/2.0); // 90 deg shift
          forever #(bit_clk_period_ps) begin
            bus[0].vif.clk_p = ~bus[0].vif.clk_p;
            bus[0].vif.clk_n = ~bus[0].vif.clk_p;
            bus[1].vif.clk_p = bus[0].vif.clk_p;
            bus[1].vif.clk_n = bus[0].vif.clk_n;
            bus[2].vif.clk_p = bus[0].vif.clk_p;
            bus[2].vif.clk_n = bus[0].vif.clk_n;
            bus[3].vif.clk_p = bus[0].vif.clk_p;
            bus[3].vif.clk_n = bus[0].vif.clk_n;
          end
        end
      join_none
    endtask
  endclass

`endif

