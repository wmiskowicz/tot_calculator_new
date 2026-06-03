module bram_controller (
  input  logic         clk,
  input  logic         rst,

  // Control inputs
  input  logic         start,
  input  logic [31:0]  addr_start,
  input  logic [31:0]  addr_stop,

  // BRAM Physical Interface
  output logic [31:0]  bram_addr,
  output logic         bram_arvalid,
  input  logic [31:0]  bram_rdata,
  input  logic         bram_rvalid,

  // Downstream Stream Interface (288-bit Packets)
  output logic [287:0] samples,
  output logic         samples_valid,
  input  logic         samples_ready
);

// FSM States
typedef enum logic [2:0] {
  IDLE,
  ACQUIRE,
  FLUSH,
  STREAM,
  FINISH
} state_t;

state_t state;

// Internal Address & Pipeline Tracking
logic [31:0] current_addr;
logic [31:0] addr_stop_q;

// Packing Shift Register
logic [4:0]  pack_count;
logic [23:0][11:0] pack_reg;

// FIFO Signals
logic         fifo_wr_en;
logic [287:0] fifo_din;
logic         fifo_rd_en;
logic [287:0] fifo_dout;
logic         fifo_empty;
logic         fifo_full;

// Extract the single 12-bit sample from BRAM (Python only writes 1 sample per word)
logic [11:0] sample_a;
assign sample_a = bram_rdata[11:0];

assign samples = fifo_dout;

// -------------------------------------------------------------------------
// 1. Core FSM & BRAM Control Logic
// -------------------------------------------------------------------------
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    state           <= IDLE;
    current_addr    <= 32'd0;
    bram_arvalid    <= 1'b0;
    bram_addr       <= 32'd0;
    addr_stop_q     <= 32'd0;
  end 
  else begin

    case (state)
      IDLE: begin
        bram_arvalid <= 1'b0;
        if (start) begin
          addr_stop_q     <= addr_stop;
          current_addr    <= addr_start;
          state           <= ACQUIRE;
        end
      end

      ACQUIRE: begin
        if (current_addr > addr_stop_q) begin
          bram_arvalid <= 1'b0;
          state <= FLUSH;
        end 
        else if (!fifo_full) begin
          bram_arvalid <= 1'b1;
          bram_addr    <= current_addr;
          current_addr <= current_addr + 32'd4;
        end 
        else begin
          bram_arvalid <= 1'b0; // Throttle read commands if FIFO fills
        end
      end

      FLUSH: begin
        state <= STREAM;
      end

      STREAM: begin
          state <= fifo_empty ? FINISH : STREAM;
      end

      FINISH: begin
        state <= !start ? IDLE : FINISH;
      end

      default: state <= IDLE;
      
    endcase
  end
end

// -------------------------------------------------------------------------
// 2. Safe Sample Packing Engine (Adapted for 1 Sample / Word)
// -------------------------------------------------------------------------
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    pack_count <= 5'd0;
    pack_reg   <= '0;
    fifo_wr_en <= 1'b0;
    fifo_din   <= '0;
  end else begin
    fifo_wr_en <= 1'b0;

    if (bram_rvalid && (state == ACQUIRE)) begin
      pack_reg[pack_count] <= sample_a;

      if (pack_count == 5'd23) begin // Trigger vector push when full (24 samples collected)
        fifo_din   <= {sample_a, pack_reg[22:0]};
        fifo_wr_en <= 1'b1;
        pack_count <= 5'd0;
      end else begin
        pack_count <= pack_count + 5'd1; // Increment step changed to 1
      end
    end 
    // Handle the final remainder data flushing safely
    else if (state == FLUSH) begin
      if (pack_count != 5'd0) begin // Only write if there are un-flushed elements
        fifo_din   <= pack_reg; 
        fifo_wr_en <= 1'b1;
      end
      pack_count <= 5'd0;
    end
  end
end

// -------------------------------------------------------------------------
// 3. Streaming Output Control
// -------------------------------------------------------------------------
assign samples_valid = (state == STREAM) && !fifo_empty;
assign fifo_rd_en    = samples_valid && samples_ready;

// -------------------------------------------------------------------------
// 4. Synchronous FIFO Model
// -------------------------------------------------------------------------
logic [287:0] fifo_mem[0:15];
logic [3:0]   wr_ptr = 0;
logic [3:0]   rd_ptr = 0;
logic [4:0]   fifo_count = 0;

assign fifo_empty = (fifo_count == 0);
assign fifo_full  = (fifo_count == 16);

always_ff @(posedge clk) begin
  if (rst) begin
    wr_ptr     <= 0;
    rd_ptr     <= 0;
    fifo_count <= 0;
  end else begin
    if (fifo_wr_en && !fifo_full) begin
      fifo_mem[wr_ptr] <= fifo_din;
      wr_ptr           <= wr_ptr + 1;
    end
    if (fifo_rd_en && !fifo_empty) begin
      rd_ptr <= rd_ptr + 1;
    end

    case ({fifo_wr_en && !fifo_full, fifo_rd_en && !fifo_empty})
      2'b10: fifo_count <= fifo_count + 1;
      2'b01: fifo_count <= fifo_count - 1;
      default: ;
    endcase
  end
end

assign fifo_dout = fifo_mem[rd_ptr];

endmodule