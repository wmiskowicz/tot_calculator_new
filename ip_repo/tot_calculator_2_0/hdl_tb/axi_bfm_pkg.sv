
`include "xil_common_vip_macros.svh"

package axi_master_bfm_pkg;
  import axi_vip_pkg::*;

  `define AXI_PARAM_DECL #(int C_AXI_PROTOCOL=0, C_AXI_ADDR_WIDTH=32, C_AXI_WDATA_WIDTH=32, C_AXI_RDATA_WIDTH=32, C_AXI_WID_WIDTH = 0,C_AXI_RID_WIDTH = 0, C_AXI_AWUSER_WIDTH=0, C_AXI_WUSER_WIDTH=0, C_AXI_BUSER_WIDTH=0, C_AXI_ARUSER_WIDTH=0, C_AXI_RUSER_WIDTH=0,     C_AXI_SUPPORTS_NARROW = 1, C_AXI_HAS_BURST = 1,C_AXI_HAS_LOCK = 1,C_AXI_HAS_CACHE= 1,C_AXI_HAS_REGION = 1,C_AXI_HAS_PROT= 1,C_AXI_HAS_QOS= 1, C_AXI_HAS_WSTRB= 1, C_AXI_HAS_BRESP= 1,C_AXI_HAS_RRESP= 1,C_AXI_HAS_ARESETN = 1)
  `define AXI_PARAM_ORDER #(C_AXI_PROTOCOL,C_AXI_ADDR_WIDTH, C_AXI_WDATA_WIDTH, C_AXI_RDATA_WIDTH, C_AXI_WID_WIDTH,C_AXI_RID_WIDTH, C_AXI_AWUSER_WIDTH, C_AXI_WUSER_WIDTH, C_AXI_BUSER_WIDTH, C_AXI_ARUSER_WIDTH, C_AXI_RUSER_WIDTH, C_AXI_SUPPORTS_NARROW, C_AXI_HAS_BURST,C_AXI_HAS_LOCK,C_AXI_HAS_CACHE,C_AXI_HAS_REGION,C_AXI_HAS_PROT,C_AXI_HAS_QOS, C_AXI_HAS_WSTRB, C_AXI_HAS_BRESP,C_AXI_HAS_RRESP,C_AXI_HAS_ARESETN)


  class axi_master_bfm_driver `AXI_PARAM_DECL;
    axi_mst_agent `AXI_PARAM_ORDER mst_agent;
    axi_transaction           wr_trans;            // Write transaction
    axi_transaction           rd_trans;            // Read transaction
    xil_axi_uint              mtestWID;            // Write ID
    xil_axi_ulong             mtestWADDR;          // Write ADDR
    xil_axi_len_t             mtestWBurstLength = 0;   // Write Burst Length
    xil_axi_size_t            mtestWDataSize;      // Write SIZE
    xil_axi_burst_t           mtestWBurstType = XIL_AXI_BURST_TYPE_INCR;     // Write Burst Type
    xil_axi_uint              mtestRID;            // Read ID
    xil_axi_ulong             mtestRADDR;          // Read ADDR
    xil_axi_len_t             mtestRBurstLength = 0;   // Read Burst Length
    xil_axi_size_t            mtestRDataSize;      // Read SIZE
    xil_axi_burst_t           mtestRBurstType = XIL_AXI_BURST_TYPE_INCR;     // Read Burst Type
    xil_axi_data_beat [255:0] mtestWUSER;         // Write user
    xil_axi_data_beat         mtestAWUSER;        // Write Awuser
    xil_axi_data_beat         mtestARUSER;        // Read Aruser
    bit [63:0]                mtestWData;         // Write Data
    bit[8*4096-1:0]           Rdatablock;        // Read data block
    xil_axi_data_beat         Rdatabeat[];       // Read data beats
    bit[8*4096-1:0]           Wdatablock;        // Write data block
    xil_axi_data_beat         Wdatabeat[];       // Write data beats
    axi_transaction           result;

    xil_axi_uint              addr_delay = 2;
    xil_axi_uint              data_insertion_delay = 5;
    xil_axi_uint              response_delay = 4;
    xil_axi_uint              allow_data_before_cmd = 1;
    xil_axi_boolean_t         adjust_addr_delay_enabled = XIL_AXI_TRUE;
    xil_axi_boolean_t         adjust_data_beat_delay_enabled = XIL_AXI_TRUE;
    xil_axi_boolean_t         adjust_response_delay_enabled = XIL_AXI_TRUE;

    string name = "";
    bit display_debug = 0;
    virtual interface axi_vip_if `AXI_PARAM_ORDER vif;

    task init;
      input virtual interface axi_vip_if `AXI_PARAM_ORDER new_vif;
      input string new_name;
      begin
        mst_agent = new(new_name, new_vif);
        mst_agent.start_master();
        this.name = new_name;
        this.vif = new_vif;
      end
    endtask

    task write;
      input xil_axi_ulong address;
      input bit [63:0] data;
      input xil_axi_ulong data_len;
      begin
        string fmtstr_address;
        string fmtstr_data;
        this.mtestWID = $urandom_range(0,(1<<(0)-1));
        this.mtestWADDR = address;
        this.mtestWDataSize = xil_axi_size_t'(xil_clog2((data_len)/8));
        this.mtestWData = data;

        this.wr_trans = this.mst_agent.wr_driver.create_transaction({"write: ", this.name});
        this.wr_trans.set_write_cmd(this.mtestWADDR,
          this.mtestWBurstType,
          this.mtestWID,
          this.mtestWBurstLength,
          this.mtestWDataSize);
        this.wr_trans.set_data_block(this.mtestWData);
        this.wr_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);

        this.wr_trans.data_insertion_delay =             this.data_insertion_delay;
        this.wr_trans.addr_delay =                       this.addr_delay;
        this.wr_trans.response_delay =                   this.response_delay;
        this.wr_trans.allow_data_before_cmd =            this.allow_data_before_cmd;
        this.wr_trans.set_adjust_addr_delay_enabled(     this.adjust_addr_delay_enabled);
        this.wr_trans.set_adjust_data_beat_delay_enabled(this.adjust_data_beat_delay_enabled);
        this.wr_trans.set_adjust_response_delay_enabled( this.adjust_response_delay_enabled);

        this.mst_agent.wr_driver.send(this.wr_trans);

        this.mst_agent.wr_driver.wait_rsp(this.result);

        this.mst_agent.wait_drivers_idle();

        if (this.display_debug) begin
          fmtstr_address = $sformatf("0x%08h", address);
          fmtstr_data = $sformatf("0x%08h", data);
          $display({this.name, ".write:  ADDR: ", fmtstr_address, " --> ", fmtstr_data});
        end
      end
    endtask

    task read;
      input xil_axi_ulong address;
      output bit[8*4096-1:0] data;
      input xil_axi_ulong data_len;
      begin
        string fmtstr_address;
        string fmtstr_data;
        this.mtestRID = $urandom_range(0,(1<<(0)-1));
        this.mtestRADDR = address;
        this.mtestRDataSize = xil_axi_size_t'(xil_clog2((data_len)/8));

        this.rd_trans = this.mst_agent.rd_driver.create_transaction({"read: ", this.name});
        this.rd_trans.set_read_cmd(mtestRADDR,mtestRBurstType,mtestRID,
          mtestRBurstLength,mtestRDataSize);
        this.rd_trans.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);

        this.rd_trans.data_insertion_delay =             this.data_insertion_delay;
        this.rd_trans.addr_delay =                       this.addr_delay;
        this.rd_trans.response_delay =                   this.response_delay;
        this.rd_trans.allow_data_before_cmd =            this.allow_data_before_cmd;
        this.rd_trans.set_adjust_addr_delay_enabled(     this.adjust_addr_delay_enabled);
        this.rd_trans.set_adjust_data_beat_delay_enabled(this.adjust_data_beat_delay_enabled);
        this.rd_trans.set_adjust_response_delay_enabled( this.adjust_response_delay_enabled);

        this.mst_agent.rd_driver.send(this.rd_trans);

        this.mst_agent.rd_driver.wait_rsp(this.result);

        this.mst_agent.wait_drivers_idle();

        this.Rdatablock = this.result.get_data_block();

        data = this.Rdatablock;

        if (this.display_debug) begin
          fmtstr_address = $sformatf("0x%08h", address);
          fmtstr_data = $sformatf("0x%08h", this.Rdatablock);
          $display({this.name, ".read:  ADDR: ", fmtstr_address, " --> ", fmtstr_data});
        end
      end
    endtask
    
  endclass

endpackage
