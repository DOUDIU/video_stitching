module video_stiching_top#(
        //hdmi parameters
        parameter  H_SYNC   =  12'd40   
    ,   parameter  H_BACK   =  12'd220  
    ,   parameter  H_DISP   =  12'd1280 
    ,   parameter  H_FRONT  =  12'd110   
    ,   parameter  H_TOTAL  =  H_SYNC + H_BACK + H_DISP + H_FRONT
    ,   parameter  V_SYNC   =  12'd5   
    ,   parameter  V_BACK   =  12'd20  
    ,   parameter  V_DISP   =  12'd720
    ,   parameter  V_FRONT  =  12'd5   
    ,   parameter  V_TOTAL  =  V_SYNC + V_BACK + V_DISP + V_FRONT

        // Horizontal resolution
    ,   parameter Cmos0_H   =   H_DISP
        // Vertical resolution
    ,   parameter Cmos0_V   =   V_DISP

        //the max depth of the fifo: 2^FIFO_AW
    ,   parameter FIFO_AW = 10
		// AXI4 sink: Data Width as same as the data depth of the fifo
    ,   parameter AXI4_DATA_WIDTH = 128

		// Base address of targeted slave
	,   parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h10000000
		// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
	,   parameter integer C_M_AXI_BURST_LEN	= 16
		// Thread ID Width
	,   parameter integer C_M_AXI_ID_WIDTH	= 1
		// Width of Address Bus
	,   parameter integer C_M_AXI_ADDR_WIDTH	= 32
		// Width of Data Bus
	,   parameter integer C_M_AXI_DATA_WIDTH	= AXI4_DATA_WIDTH
		// Width of User Write Address Bus
	,   parameter integer C_M_AXI_AWUSER_WIDTH	= 0
		// Width of User Read Address Bus
	,   parameter integer C_M_AXI_ARUSER_WIDTH	= 0
		// Width of User Write Data Bus
	,   parameter integer C_M_AXI_WUSER_WIDTH	= 0
		// Width of User Read Data Bus
	,   parameter integer C_M_AXI_RUSER_WIDTH	= 0
		// Width of User Response Bus
	,   parameter integer C_M_AXI_BUSER_WIDTH	= 0
)(
//----------------------------------------------------
// Cmos port
        input           cmos_clk        
    ,   input           cmos_vsync          
    ,   input           cmos_href           
    ,   input           cmos_clken          
    ,   input   [23:0]  cmos_data           

//----------------------------------------------------
// Video port
    ,   input           video_clk
    ,   output          video_vsync
    ,   output          video_href
    ,   output          video_de
    ,   output  [23:0]  video_data

//----------------------------------------------------
// AXI-FULL master port
    //----------------Write Address Channel----------------//
    // Master Interface Write Address ID
    ,   output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_AWID
    // Master Interface Write Address
    ,   output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR
    // Burst length. The burst length gives the exact number of transfers in a burst
    ,   output wire [7 : 0] M_AXI_AWLEN
    // Burst size. This signal indicates the size of each transfer in the burst
    ,   output wire [2 : 0] M_AXI_AWSIZE
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
    ,   output wire [1 : 0] M_AXI_AWBURST
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    ,   output wire  M_AXI_AWLOCK
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    ,   output wire [3 : 0] M_AXI_AWCACHE
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    ,   output wire [2 : 0] M_AXI_AWPROT
    // Quality of Service, QoS identifier sent for each write transaction.
    ,   output wire [3 : 0] M_AXI_AWQOS
    // Optional User-defined signal in the write address channel.
    ,   output wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER
    // Write address valid. This signal indicates that
    // the channel is signaling valid write address and control information.
    ,   output wire  M_AXI_AWVALID
    // Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
    ,   input wire  M_AXI_AWREADY

    //----------------Write Data Channel----------------//
    // Master Interface Write Data.
    ,   output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA
    // Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
    ,   output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB
    // Write last. This signal indicates the last transfer in a write burst.
    ,   output wire  M_AXI_WLAST
    // Optional User-defined signal in the write data channel.
    ,   output wire [C_M_AXI_WUSER_WIDTH-1 : 0] M_AXI_WUSER
    // Write valid. This signal indicates that valid write
    // data and strobes are available
    ,   output wire  M_AXI_WVALID
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    ,   input wire  M_AXI_WREADY

    //----------------Write Response Channel----------------//
    // Master Interface Write Response.
    ,   input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID
    // Write response. This signal indicates the status of the write transaction.
    ,   input wire [1 : 0] M_AXI_BRESP
    // Optional User-defined signal in the write response channel
    ,   input wire [C_M_AXI_BUSER_WIDTH-1 : 0] M_AXI_BUSER
    // Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
    ,   input wire  M_AXI_BVALID
    // Response ready. This signal indicates that the master
    // can accept a write response.
    ,   output wire  M_AXI_BREADY

    //----------------Read Address Channel----------------//
    // Master Interface Read Address.
    ,   output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_ARID
    // Read address. This signal indicates the initial
    // address of a read burst transaction.
    ,   output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR
    // Burst length. The burst length gives the exact number of transfers in a burst
    ,   output wire [7 : 0] M_AXI_ARLEN
    // Burst size. This signal indicates the size of each transfer in the burst
    ,   output wire [2 : 0] M_AXI_ARSIZE
    // Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
    ,   output wire [1 : 0] M_AXI_ARBURST
    // Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
    ,   output wire  M_AXI_ARLOCK
    // Memory type. This signal indicates how transactions
    // are required to progress through a system.
    ,   output wire [3 : 0] M_AXI_ARCACHE
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    ,   output wire [2 : 0] M_AXI_ARPROT
    // Quality of Service, QoS identifier sent for each read transaction
    ,   output wire [3 : 0] M_AXI_ARQOS
    // Optional User-defined signal in the read address channel.
    ,   output wire [C_M_AXI_ARUSER_WIDTH-1 : 0] M_AXI_ARUSER
    // Write address valid. This signal indicates that
    // the channel is signaling valid read address and control information
    ,   output wire  M_AXI_ARVALID
    // Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
    ,   input wire  M_AXI_ARREADY

    //----------------Read Data Channel----------------//
    // Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
    ,   input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_RID
    // Master Read Data
    ,   input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA
    // Read response. This signal indicates the status of the read transfer
    ,   input wire [1 : 0] M_AXI_RRESP
    // Read last. This signal indicates the last transfer in a read burst
    ,   input wire  M_AXI_RLAST
    // Optional User-defined signal in the read address channel.
    ,   input wire [C_M_AXI_RUSER_WIDTH-1 : 0] M_AXI_RUSER
    // Read valid. This signal indicates that the channel
    // is signaling the required read data.
    ,   input wire  M_AXI_RVALID
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    ,   output wire  M_AXI_RREADY

//----------------------------------------------------
// DDR native port
    ,   input           sys_rst               
    ,   input           c0_sys_clk_p           
    ,   input           c0_sys_clk_n           
	,   output          c0_ddr4_act_n   
	,   output  [16:0]  c0_ddr4_adr     
	,   output  [1 :0]  c0_ddr4_ba      
	,   output  [0 :0]  c0_ddr4_bg      
	,   output  [0 :0]  c0_ddr4_cke     
	,   output  [0 :0]  c0_ddr4_odt     
	,   output  [0 :0]  c0_ddr4_cs_n    
	,   output  [0 :0]  c0_ddr4_ck_t    
	,   output  [0 :0]  c0_ddr4_ck_c    
	,   output          c0_ddr4_reset_n 
	,   inout   [1 :0]  c0_ddr4_dm_dbi_n
	,   inout   [15:0]  c0_ddr4_dq      
	,   inout   [1 :0]  c0_ddr4_dqs_c   
	,   inout   [1 :0]  c0_ddr4_dqs_t   
);

localparam nCK_PER_CLK          = 4;
localparam ADDR_WIDTH           = 28;
localparam MEM_IF_ADDR_BITS     = 29;
localparam PAYLOAD_WIDTH        = 16;
localparam APP_DATA_WIDTH       = 2 * nCK_PER_CLK * PAYLOAD_WIDTH;
localparam APP_MASK_WIDTH       = APP_DATA_WIDTH / 8;
// DDR native app port
wire                                init_calib_complete     ;
wire                                app_clk                 ;
wire                                app_rst                 ;
wire    [MEM_IF_ADDR_BITS-1:0]      app_addr                ;
wire    [2:0]                       app_cmd                 ;
wire                                app_en                  ;
wire                                app_rdy                 ;
wire    [APP_DATA_WIDTH-1:0]        app_rd_data             ;
wire                                app_rd_data_end         ;
wire                                app_rd_data_valid       ;
wire    [APP_DATA_WIDTH-1:0]        app_wdf_data            ;
wire                                app_wdf_end             ;
wire    [APP_MASK_WIDTH-1:0]        app_wdf_mask            ;
wire                                app_wdf_rdy             ;
wire                                app_wdf_wren            ;

wire                                rst_n                   ;

wire                                cmos_burst_valid        ;
wire                                cmos_burst_ready        ;
wire                                cmos_fifo_wr_enable     ;
wire    [AXI4_DATA_WIDTH-1 : 0]     cmos_fifo_wr_data_out   ;
wire                                cmos_fifo_rd_enable     ;
wire    [AXI4_DATA_WIDTH-1 : 0]     cmos_fifo_rd_data_out   ;

wire                                video_burst_valid       ;
wire                                video_burst_ready       ;
wire                                video_fifo_wr_enable    ;
wire    [AXI4_DATA_WIDTH-1 : 0]     video_fifo_wr_data_out  ;
wire                                video_fifo_rd_enable    ;
wire                                video_fifo_rd_empty     ;
wire    [AXI4_DATA_WIDTH-1 : 0]     video_fifo_rd_data_out  ;
wire                                video_fifo_rst_n        ;

assign M_AXI_ACLK = app_clk;
assign M_AXI_ARESETN = !(app_rst | (!init_calib_complete));
assign rst_n  = M_AXI_ARESETN;


video_to_fifo_ctrl #(
        .AXI4_DATA_WIDTH        (AXI4_DATA_WIDTH        )
)u_cmos_to_fifo_ctrl(
        .video_rst_n            (rst_n                  )
    ,   .video_clk              (cmos_clk               )
    ,   .video_vs_out           (cmos_vsync             )
    ,   .video_hs_out           (cmos_href              )
    ,   .video_de_out           (cmos_clken             )
    ,   .video_data_out         (cmos_data              )

    ,   .M_AXI_ACLK             (M_AXI_ACLK             )
    ,   .M_AXI_ARESETN          (M_AXI_ARESETN          )

    ,   .fifo_enable            (cmos_fifo_wr_enable    )
    ,   .fifo_data_out          (cmos_fifo_wr_data_out  )

    ,   .AXI_FULL_BURST_VALID   (cmos_burst_valid       )
    ,   .AXI_FULL_BURST_READY   (cmos_burst_ready       )
);


fifo_generator_0 u_async_forward_fifo (
    .rst          (!cmos_vsync | !M_AXI_ARESETN ),
    .wr_clk       (cmos_clk                     ),
    .rd_clk       (M_AXI_ACLK                   ),
    .din          (cmos_fifo_wr_data_out        ),
    .wr_en        (cmos_fifo_wr_enable          ),
    .rd_en        (cmos_fifo_rd_enable          ),
    .dout         (cmos_fifo_rd_data_out        ),
    .full         (),
    .empty        (),
    .wr_rst_busy  (),
    .rd_rst_busy  () 
);


//---------------------------------------------------
// AXI FULL DATA GENERATOR
maxi_full_v1_0_M00_AXI  #(
    //----------------------------------------------------
    // AXI-FULL parameters
	    .C_M_TARGET_SLAVE_BASE_ADDR	    (C_M_TARGET_SLAVE_BASE_ADDR)   
	,   .C_M_AXI_BURST_LEN	            (C_M_AXI_BURST_LEN	       )   
	,   .C_M_AXI_ID_WIDTH	            (C_M_AXI_ID_WIDTH	       )   
	,   .C_M_AXI_ADDR_WIDTH	            (C_M_AXI_ADDR_WIDTH	       )   
	,   .C_M_AXI_DATA_WIDTH	            (AXI4_DATA_WIDTH	       )   
	,   .C_M_AXI_AWUSER_WIDTH	        (C_M_AXI_AWUSER_WIDTH	   )   
	,   .C_M_AXI_ARUSER_WIDTH	        (C_M_AXI_ARUSER_WIDTH	   )   
	,   .C_M_AXI_WUSER_WIDTH	        (C_M_AXI_WUSER_WIDTH	   )   
	,   .C_M_AXI_RUSER_WIDTH	        (C_M_AXI_RUSER_WIDTH	   )   
	,   .C_M_AXI_BUSER_WIDTH	        (C_M_AXI_BUSER_WIDTH	   ) 
)u_maxi_full_v1_0_M00_AXI(
//----------------------------------------------------
// AXI-FULL master port
        .INIT_AXI_TXN       (0)
    ,   .TXN_DONE           ()
    ,   .ERROR              ()
    ,   .M_AXI_ACLK         (M_AXI_ACLK         )
    ,   .M_AXI_ARESETN      (M_AXI_ARESETN      )

    //----------------Write Address Channel----------------//
    ,   .M_AXI_AWID         (M_AXI_AWID         )
    ,   .M_AXI_AWADDR       (M_AXI_AWADDR       )
    ,   .M_AXI_AWLEN        (M_AXI_AWLEN        )
    ,   .M_AXI_AWSIZE       (M_AXI_AWSIZE       )
    ,   .M_AXI_AWBURST      (M_AXI_AWBURST      )
    ,   .M_AXI_AWLOCK       (M_AXI_AWLOCK       )
    ,   .M_AXI_AWCACHE      (M_AXI_AWCACHE      )
    ,   .M_AXI_AWPROT       (M_AXI_AWPROT       )
    ,   .M_AXI_AWQOS        (M_AXI_AWQOS        )
    ,   .M_AXI_AWUSER       (M_AXI_AWUSER       )
    ,   .M_AXI_AWVALID      (M_AXI_AWVALID      )
    ,   .M_AXI_AWREADY      (M_AXI_AWREADY      )

    //----------------Write Data Channel----------------//
    ,   .M_AXI_WDATA        (M_AXI_WDATA        )
    ,   .M_AXI_WSTRB        (M_AXI_WSTRB        )
    ,   .M_AXI_WLAST        (M_AXI_WLAST        )
    ,   .M_AXI_WUSER        (M_AXI_WUSER        )
    ,   .M_AXI_WVALID       (M_AXI_WVALID       )
    ,   .M_AXI_WREADY       (M_AXI_WREADY       )

    //----------------Write Response Channel----------------//
    ,   .M_AXI_BID          (M_AXI_BID          )
    ,   .M_AXI_BRESP        (M_AXI_BRESP        )
    ,   .M_AXI_BUSER        (M_AXI_BUSER        )
    ,   .M_AXI_BVALID       (M_AXI_BVALID       )
    ,   .M_AXI_BREADY       (M_AXI_BREADY       )

    //----------------Read Address Channel----------------//
    ,   .M_AXI_ARID         (M_AXI_ARID         )
    ,   .M_AXI_ARADDR       (M_AXI_ARADDR       )
    ,   .M_AXI_ARLEN        (M_AXI_ARLEN        )
    ,   .M_AXI_ARSIZE       (M_AXI_ARSIZE       )
    ,   .M_AXI_ARBURST      (M_AXI_ARBURST      )
    ,   .M_AXI_ARLOCK       (M_AXI_ARLOCK       )
    ,   .M_AXI_ARCACHE      (M_AXI_ARCACHE      )
    ,   .M_AXI_ARPROT       (M_AXI_ARPROT       )
    ,   .M_AXI_ARQOS        (M_AXI_ARQOS        )
    ,   .M_AXI_ARUSER       (M_AXI_ARUSER       )
    ,   .M_AXI_ARVALID      (M_AXI_ARVALID      )
    ,   .M_AXI_ARREADY      (M_AXI_ARREADY      )

    //----------------Read Data Channel----------------//
    ,   .M_AXI_RID          (M_AXI_RID          )
    ,   .M_AXI_RDATA        (M_AXI_RDATA        )
    ,   .M_AXI_RRESP        (M_AXI_RRESP        )
    ,   .M_AXI_RLAST        (M_AXI_RLAST        )
    ,   .M_AXI_RUSER        (M_AXI_RUSER        )
    ,   .M_AXI_RVALID       (M_AXI_RVALID       )
    ,   .M_AXI_RREADY       (M_AXI_RREADY       )
);
/*
//---------------------------------------------------
// FIFO TO AXI FULL
axi_full_core #(
    //----------------------------------------------------
    // FIFO parameters
        .FDW                            (AXI4_DATA_WIDTH    )
    ,   .FAW                            (FIFO_AW            )
    ,   .Cmos0_H                        (Cmos0_H            )
    ,   .Cmos0_V                        (Cmos0_V            )

    //----------------------------------------------------
    // AXI-FULL parameters
	,   .C_M_TARGET_SLAVE_BASE_ADDR	    (C_M_TARGET_SLAVE_BASE_ADDR)   
	,   .C_M_AXI_BURST_LEN	            (C_M_AXI_BURST_LEN	       )   
	,   .C_M_AXI_ID_WIDTH	            (C_M_AXI_ID_WIDTH	       )   
	,   .C_M_AXI_ADDR_WIDTH	            (C_M_AXI_ADDR_WIDTH	       )   
	,   .C_M_AXI_DATA_WIDTH	            (AXI4_DATA_WIDTH	       )   
	,   .C_M_AXI_AWUSER_WIDTH	        (C_M_AXI_AWUSER_WIDTH	   )   
	,   .C_M_AXI_ARUSER_WIDTH	        (C_M_AXI_ARUSER_WIDTH	   )   
	,   .C_M_AXI_WUSER_WIDTH	        (C_M_AXI_WUSER_WIDTH	   )   
	,   .C_M_AXI_RUSER_WIDTH	        (C_M_AXI_RUSER_WIDTH	   )   
	,   .C_M_AXI_BUSER_WIDTH	        (C_M_AXI_BUSER_WIDTH	   )   
)u_axi_full_core(

//----------------------------------------------------
// forward FIFO read interface
        .cmos_frd_rdy  	    (cmos_fifo_rd_enable    )
    ,   .cmos_frd_vld  	    ()
    ,   .cmos_frd_din  	    (cmos_fifo_rd_data_out  )
    ,   .cmos_frd_empty	    ()
    ,   .cmos_frd_cnt	    ()

//----------------------------------------------------
// backward FIFO write interface
    ,   .video_bwr_rdy      ()
    ,   .video_bwr_vld      (video_fifo_wr_enable   )
    ,   .video_bwr_din      (video_fifo_wr_data_out )
    ,   .video_bwr_empty    ()
    ,   .video_bwr_cnt	    ()

//----------------------------------------------------
// cmos burst handshake 
	,	.cmos_burst_valid   (cmos_burst_valid       )
	,	.cmos_burst_ready   (cmos_burst_ready       )

//----------------------------------------------------
// video burst handshake 
	,	.video_burst_valid  (video_burst_valid      )
	,	.video_burst_ready  (video_burst_ready      )
    
//----------------------------------------------------
// cmos interface 
	,	.cmos_vsync         (cmos_vsync             )

//----------------------------------------------------
// video interface 
	,	.video_vsync        (video_vsync            )

//----------------------------------------------------
// AXI-FULL master port
    ,   .INIT_AXI_TXN       (AXI_FULL_BURST     )
    ,   .TXN_DONE           (TXN_DONE           )
    ,   .ERROR              ()
    ,   .M_AXI_ACLK         (M_AXI_ACLK         )
    ,   .M_AXI_ARESETN      (M_AXI_ARESETN      )

    //----------------Write Address Channel----------------//
    ,   .M_AXI_AWID         (M_AXI_AWID         )
    ,   .M_AXI_AWADDR       (M_AXI_AWADDR       )
    ,   .M_AXI_AWLEN        (M_AXI_AWLEN        )
    ,   .M_AXI_AWSIZE       (M_AXI_AWSIZE       )
    ,   .M_AXI_AWBURST      (M_AXI_AWBURST      )
    ,   .M_AXI_AWLOCK       (M_AXI_AWLOCK       )
    ,   .M_AXI_AWCACHE      (M_AXI_AWCACHE      )
    ,   .M_AXI_AWPROT       (M_AXI_AWPROT       )
    ,   .M_AXI_AWQOS        (M_AXI_AWQOS        )
    ,   .M_AXI_AWUSER       (M_AXI_AWUSER       )
    ,   .M_AXI_AWVALID      (M_AXI_AWVALID      )
    ,   .M_AXI_AWREADY      (M_AXI_AWREADY      )

    //----------------Write Data Channel----------------//
    ,   .M_AXI_WDATA        (M_AXI_WDATA        )
    ,   .M_AXI_WSTRB        (M_AXI_WSTRB        )
    ,   .M_AXI_WLAST        (M_AXI_WLAST        )
    ,   .M_AXI_WUSER        (M_AXI_WUSER        )
    ,   .M_AXI_WVALID       (M_AXI_WVALID       )
    ,   .M_AXI_WREADY       (M_AXI_WREADY       )

    //----------------Write Response Channel----------------//
    ,   .M_AXI_BID          (M_AXI_BID          )
    ,   .M_AXI_BRESP        (M_AXI_BRESP        )
    ,   .M_AXI_BUSER        (M_AXI_BUSER        )
    ,   .M_AXI_BVALID       (M_AXI_BVALID       )
    ,   .M_AXI_BREADY       (M_AXI_BREADY       )

    //----------------Read Address Channel----------------//
    ,   .M_AXI_ARID         (M_AXI_ARID         )
    ,   .M_AXI_ARADDR       (M_AXI_ARADDR       )
    ,   .M_AXI_ARLEN        (M_AXI_ARLEN        )
    ,   .M_AXI_ARSIZE       (M_AXI_ARSIZE       )
    ,   .M_AXI_ARBURST      (M_AXI_ARBURST      )
    ,   .M_AXI_ARLOCK       (M_AXI_ARLOCK       )
    ,   .M_AXI_ARCACHE      (M_AXI_ARCACHE      )
    ,   .M_AXI_ARPROT       (M_AXI_ARPROT       )
    ,   .M_AXI_ARQOS        (M_AXI_ARQOS        )
    ,   .M_AXI_ARUSER       (M_AXI_ARUSER       )
    ,   .M_AXI_ARVALID      (M_AXI_ARVALID      )
    ,   .M_AXI_ARREADY      (M_AXI_ARREADY      )

    //----------------Read Data Channel----------------//
    ,   .M_AXI_RID          (M_AXI_RID          )
    ,   .M_AXI_RDATA        (M_AXI_RDATA        )
    ,   .M_AXI_RRESP        (M_AXI_RRESP        )
    ,   .M_AXI_RLAST        (M_AXI_RLAST        )
    ,   .M_AXI_RUSER        (M_AXI_RUSER        )
    ,   .M_AXI_RVALID       (M_AXI_RVALID       )
    ,   .M_AXI_RREADY       (M_AXI_RREADY       )
);
*/

wire backward_fifo_full;
wire backward_fifo_empty;
wire [12:0]  rd_data_count;
wire [12:0]  wr_data_count;

fifo_generator_0 u_async_backward_fifo (
    .rst          (!video_fifo_rst_n | !M_AXI_ARESETN   ),
    .wr_clk       (M_AXI_ACLK                           ),
    .rd_clk       (video_clk                            ),
    .din          (video_fifo_wr_data_out               ),
    .wr_en        (video_fifo_wr_enable                 ),
    .rd_en        (video_fifo_rd_enable                 ),
    .dout         (video_fifo_rd_data_out               ),
    .full         (backward_fifo_full                   ),
    .empty        (backward_fifo_empty                  ),

    .rd_data_count(rd_data_count                        ),
    .wr_data_count(wr_data_count                        ),
    .wr_rst_busy  (),
    .rd_rst_busy  () 
);

fifo_to_video_ctrl#(
        .H_SYNC                     (H_SYNC                 )
    ,   .H_BACK                     (H_BACK                 )
    ,   .H_DISP                     (H_DISP                 )
    ,   .H_FRONT                    (H_FRONT                )
    ,   .H_TOTAL                    (H_TOTAL                )

    ,   .V_SYNC                     (V_SYNC                 )
    ,   .V_BACK                     (V_BACK                 )
    ,   .V_DISP                     (V_DISP                 )
    ,   .V_FRONT                    (V_FRONT                )
    ,   .V_TOTAL                    (V_TOTAL                )

    ,   .AXI4_DATA_WIDTH            (AXI4_DATA_WIDTH        )
)u_fifo_to_video_ctrl(  
        .video_clk                  (video_clk              )                          
    ,   .video_rst_n                (rst_n                  )                              

    ,   .M_AXI_ACLK                 (M_AXI_ACLK             )
    ,   .M_AXI_ARESETN              (M_AXI_ARESETN          )   

	,   .video_vs_out               (video_vsync            )                                  
	,   .video_hs_out               (video_href             )                                  
	,   .video_de_out               (video_de               )                                  
	,   .video_data_out             (video_data             )                                  

    ,   .fifo_data_in               (video_fifo_rd_data_out )                              
    ,   .fifo_enable                (video_fifo_rd_enable   )  
    ,   .fifo_rst_n                 (video_fifo_rst_n       )                            

    ,   .AXI_FULL_BURST_VALID       (video_burst_valid      )                                      
    ,   .AXI_FULL_BURST_READY       (video_burst_ready      )                                      
);

ddr4 u_ddr4(
        .sys_rst                    (sys_rst                )
    ,   .c0_sys_clk_p               (c0_sys_clk_p           )
    ,   .c0_sys_clk_n               (c0_sys_clk_n           )
    ,   .c0_ddr4_act_n              (c0_ddr4_act_n          )
    ,   .c0_ddr4_adr                (c0_ddr4_adr            )
    ,   .c0_ddr4_ba                 (c0_ddr4_ba             )
    ,   .c0_ddr4_bg                 (c0_ddr4_bg             )
    ,   .c0_ddr4_cke                (c0_ddr4_cke            )
    ,   .c0_ddr4_odt                (c0_ddr4_odt            )
    ,   .c0_ddr4_cs_n               (c0_ddr4_cs_n           )
    ,   .c0_ddr4_ck_t               (c0_ddr4_ck_t           )
    ,   .c0_ddr4_ck_c               (c0_ddr4_ck_c           )
    ,   .c0_ddr4_reset_n            (c0_ddr4_reset_n        )
    ,   .c0_ddr4_dm_dbi_n           (c0_ddr4_dm_dbi_n       )
    ,   .c0_ddr4_dq                 (c0_ddr4_dq             )
    ,   .c0_ddr4_dqs_c              (c0_ddr4_dqs_c          )
    ,   .c0_ddr4_dqs_t              (c0_ddr4_dqs_t          )
    ,   .c0_init_calib_complete     (init_calib_complete    )
    ,   .c0_ddr4_ui_clk             (app_clk                )
    ,   .c0_ddr4_ui_clk_sync_rst    (app_rst                )
    ,   .dbg_clk                    (                       )
    ,   .c0_ddr4_app_addr           (app_addr               )
    ,   .c0_ddr4_app_cmd            (app_cmd                )
    ,   .c0_ddr4_app_en             (app_en                 )
    ,   .c0_ddr4_app_hi_pri         (1'b0                   )
    ,   .c0_ddr4_app_wdf_data       (app_wdf_data           )
    ,   .c0_ddr4_app_wdf_end        (app_wdf_end            )
    ,   .c0_ddr4_app_wdf_mask       (app_wdf_mask           )
    ,   .c0_ddr4_app_wdf_wren       (app_wdf_wren           )
    ,   .c0_ddr4_app_rd_data        (app_rd_data            )
    ,   .c0_ddr4_app_rd_data_end    (app_rd_data_end        )
    ,   .c0_ddr4_app_rd_data_valid  (app_rd_data_valid      )
    ,   .c0_ddr4_app_rdy            (app_rdy                )
    ,   .c0_ddr4_app_wdf_rdy        (app_wdf_rdy            )
    ,   .dbg_bus                    (                       )
);

axi_native_transition#(
	    .MEM_DATA_BITS              (APP_DATA_WIDTH         )
	,   .MEM_IF_ADDR_BITS           (MEM_IF_ADDR_BITS       )
	,   .ADDR_BITS                  (ADDR_WIDTH             )

	,   .C_S_AXI_ID_WIDTH	        (C_M_AXI_ID_WIDTH	    )   
	,   .C_S_AXI_ADDR_WIDTH	        (C_M_AXI_ADDR_WIDTH	    )   
	,   .C_S_AXI_DATA_WIDTH	        (AXI4_DATA_WIDTH	    )   
	,   .C_S_AXI_AWUSER_WIDTH	    (C_M_AXI_AWUSER_WIDTH   )   
	,   .C_S_AXI_ARUSER_WIDTH	    (C_M_AXI_ARUSER_WIDTH   )   
	,   .C_S_AXI_WUSER_WIDTH	    (C_M_AXI_WUSER_WIDTH    )   
	,   .C_S_AXI_RUSER_WIDTH	    (C_M_AXI_RUSER_WIDTH    )   
	,   .C_S_AXI_BUSER_WIDTH	    (C_M_AXI_BUSER_WIDTH    )   
)u_axi_native_transition(
//----------------------------------------------------
// DDR native app port
        .app_clk            (app_clk            )
    ,   .app_rst            (app_rst | (!init_calib_complete))
    ,   .app_addr           (app_addr           )
    ,   .app_cmd            (app_cmd            )
    ,   .app_en             (app_en             )
    ,   .app_rdy            (app_rdy            )
    ,   .app_rd_data        (app_rd_data        )
    ,   .app_rd_data_end    (app_rd_data_end    )
    ,   .app_rd_data_valid  (app_rd_data_valid  )
    ,   .app_wdf_data       (app_wdf_data       )
    ,   .app_wdf_end        (app_wdf_end        )
    ,   .app_wdf_mask       (app_wdf_mask       )
    ,   .app_wdf_rdy        (app_wdf_rdy        )
    ,   .app_wdf_wren       (app_wdf_wren       )

//----------------------------------------------------
// AXI-FULL master port
    ,   .S_AXI_ACLK         (M_AXI_ACLK         )
    ,   .S_AXI_ARESETN      (M_AXI_ARESETN      )

    ,   .S_AXI_AWID         (M_AXI_AWID         )
    ,   .S_AXI_AWADDR       (M_AXI_AWADDR       )
    ,   .S_AXI_AWLEN        (M_AXI_AWLEN        )
    ,   .S_AXI_AWSIZE       (M_AXI_AWSIZE       )
    ,   .S_AXI_AWBURST      (M_AXI_AWBURST      )
    ,   .S_AXI_AWLOCK       (M_AXI_AWLOCK       )
    ,   .S_AXI_AWCACHE      (M_AXI_AWCACHE      )
    ,   .S_AXI_AWPROT       (M_AXI_AWPROT       )
    ,   .S_AXI_AWQOS        (M_AXI_AWQOS        )
    ,   .S_AXI_AWREGION     ()
    ,   .S_AXI_AWUSER       (M_AXI_AWUSER       )
    ,   .S_AXI_AWVALID      (M_AXI_AWVALID      )
    ,   .S_AXI_AWREADY      (M_AXI_AWREADY      )

    ,   .S_AXI_WDATA        (M_AXI_WDATA        )
    ,   .S_AXI_WSTRB        (M_AXI_WSTRB        )
    ,   .S_AXI_WLAST        (M_AXI_WLAST        )
    ,   .S_AXI_WUSER        (M_AXI_WUSER        )
    ,   .S_AXI_WVALID       (M_AXI_WVALID       )
    ,   .S_AXI_WREADY       (M_AXI_WREADY       )

    ,   .S_AXI_BID          (M_AXI_BID          )
    ,   .S_AXI_BRESP        (M_AXI_BRESP        )
    ,   .S_AXI_BUSER        (M_AXI_BUSER        )
    ,   .S_AXI_BVALID       (M_AXI_BVALID       )
    ,   .S_AXI_BREADY       (M_AXI_BREADY       )

    ,   .S_AXI_ARID         (M_AXI_ARID         )
    ,   .S_AXI_ARADDR       (M_AXI_ARADDR       )
    ,   .S_AXI_ARLEN        (M_AXI_ARLEN        )
    ,   .S_AXI_ARSIZE       (M_AXI_ARSIZE       )
    ,   .S_AXI_ARBURST      (M_AXI_ARBURST      )
    ,   .S_AXI_ARLOCK       (M_AXI_ARLOCK       )
    ,   .S_AXI_ARCACHE      (M_AXI_ARCACHE      )
    ,   .S_AXI_ARPROT       (M_AXI_ARPROT       )
    ,   .S_AXI_ARQOS        (M_AXI_ARQOS        )
    ,   .S_AXI_ARREGION     ()
    ,   .S_AXI_ARUSER       (M_AXI_ARUSER       )
    ,   .S_AXI_ARVALID      (M_AXI_ARVALID      )
    ,   .S_AXI_ARREADY      (M_AXI_ARREADY      )

    ,   .S_AXI_RID          (M_AXI_RID          )
    ,   .S_AXI_RDATA        (M_AXI_RDATA        )
    ,   .S_AXI_RRESP        (M_AXI_RRESP        )
    ,   .S_AXI_RLAST        (M_AXI_RLAST        )
    ,   .S_AXI_RUSER        (M_AXI_RUSER        )
    ,   .S_AXI_RVALID       (M_AXI_RVALID       )
    ,   .S_AXI_RREADY       (M_AXI_RREADY       )
);


endmodule