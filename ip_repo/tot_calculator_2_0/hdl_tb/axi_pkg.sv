`include "xil_common_vip_macros.svh"

package axi_pkg;
    import axi_vip_pkg::*;
    import axi_master_bfm_pkg::*;

    parameter BFM_AXI_VIP_PROTOCOL           = 2;
    parameter BFM_AXI_VIP_INTERFACE_MODE     = 0;
    parameter BFM_AXI_VIP_ADDR_WIDTH         = 6;
    parameter BFM_AXI_VIP_DATA_WIDTH         = 32;
    parameter BFM_AXI_VIP_ID_WIDTH           = 0;
    parameter BFM_AXI_VIP_AWUSER_WIDTH       = 0;
    parameter BFM_AXI_VIP_ARUSER_WIDTH       = 0;
    parameter BFM_AXI_VIP_RUSER_WIDTH        = 0;
    parameter BFM_AXI_VIP_WUSER_WIDTH        = 0;
    parameter BFM_AXI_VIP_BUSER_WIDTH        = 0;
    parameter BFM_AXI_VIP_SUPPORTS_NARROW    = 0;
    parameter BFM_AXI_VIP_HAS_BURST          = 0;
    parameter BFM_AXI_VIP_HAS_LOCK           = 0;
    parameter BFM_AXI_VIP_HAS_CACHE          = 0;
    parameter BFM_AXI_VIP_HAS_REGION         = 0;
    parameter BFM_AXI_VIP_HAS_QOS            = 0;
    parameter BFM_AXI_VIP_HAS_PROT           = 1;
    parameter BFM_AXI_VIP_HAS_WSTRB          = 1;
    parameter BFM_AXI_VIP_HAS_BRESP          = 1;
    parameter BFM_AXI_VIP_HAS_RRESP          = 1;
    parameter BFM_AXI_VIP_HAS_ACLKEN         = 0;
    parameter BFM_AXI_VIP_HAS_ARESETN        = 1;
    ///////////////////////////////////////////////////////////////////////////

    typedef axi_master_bfm_driver #(BFM_AXI_VIP_PROTOCOL,
                                    BFM_AXI_VIP_ADDR_WIDTH,
                                    BFM_AXI_VIP_DATA_WIDTH,
                                    BFM_AXI_VIP_DATA_WIDTH,
                                    BFM_AXI_VIP_ID_WIDTH,
                                    BFM_AXI_VIP_ID_WIDTH,
                                    BFM_AXI_VIP_AWUSER_WIDTH,
                                    BFM_AXI_VIP_WUSER_WIDTH,
                                    BFM_AXI_VIP_BUSER_WIDTH,
                                    BFM_AXI_VIP_ARUSER_WIDTH,
                                    BFM_AXI_VIP_RUSER_WIDTH,
                                    BFM_AXI_VIP_SUPPORTS_NARROW,
                                    BFM_AXI_VIP_HAS_BURST,
                                    BFM_AXI_VIP_HAS_LOCK,
                                    BFM_AXI_VIP_HAS_CACHE,
                                    BFM_AXI_VIP_HAS_REGION,
                                    BFM_AXI_VIP_HAS_PROT,
                                    BFM_AXI_VIP_HAS_QOS,
                                    BFM_AXI_VIP_HAS_WSTRB,
                                    BFM_AXI_VIP_HAS_BRESP,
                                    BFM_AXI_VIP_HAS_RRESP,
                                    BFM_AXI_VIP_HAS_ARESETN) axi_master_t;
endpackage