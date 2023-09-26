`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/24 16:45:44
// Design Name: 
// Module Name: video_to_fifo_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module video_to_fifo_ctrl(
    
        input           video_clk
    ,   input           video_rst_n

    ,   input           M_AXI_ACLK
    ,   input           M_AXI_ARESETN

	,   input           video_vs_out    
	,   input           video_hs_out    
	,   input           video_de_out    
	,   input   [23:0]  video_data_out  

    ,   output  [127:0] fifo_data_out
    ,   output  reg     fifo_enable

    ,   output          AXI_FULL_BURST
);


// ila_0 u_ila_0 (
// 	.clk(M_AXI_ACLK), // input wire clk


// 	.probe0(video_vs_out    ), // input wire [0:0]  probe0  
// 	.probe1(video_hs_out    ), // input wire [0:0]  probe1 
// 	.probe2(video_de_out    ), // input wire [0:0]  probe2 
// 	.probe3(video_data_out  ), // input wire [23:0]  probe3 
// 	.probe4(AXI_FULL_BURST  ) // input wire [0:0]  probe4
// );



reg [127:0] fifo_data_out_buffer;
reg [1:0]   buf_cnt;
reg     video_hs_out_d1;
reg     video_hs_out_d2;

assign  fifo_data_out   =   fifo_data_out_buffer;
assign  AXI_FULL_BURST = !video_hs_out_d2 & video_hs_out_d1;

always@(posedge video_clk or negedge video_rst_n) begin
    if(!video_rst_n) begin
        fifo_data_out_buffer    <=  0;
    end
    else if(video_de_out) begin
        fifo_data_out_buffer    <=  {fifo_data_out_buffer[95:0],8'hff,video_data_out};
    end
end

always@(posedge video_clk or negedge video_rst_n) begin
    if(!video_rst_n) begin
        buf_cnt    <=  0;
    end
    else if(video_de_out) begin
        buf_cnt    <=  buf_cnt + 1;
    end
end

always@(posedge video_clk or negedge video_rst_n) begin
    if(!video_rst_n) begin
        fifo_enable    <=  0;
    end
    else if(video_de_out & (buf_cnt == 2'b11)) begin
        fifo_enable    <=  1;
    end
    else begin
        fifo_enable    <=  0;
    end
end

always@(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
    if(!M_AXI_ARESETN) begin
        video_hs_out_d1 <=  0;
        video_hs_out_d2 <=  0;
    end 
    else begin
        video_hs_out_d1 <=  video_hs_out;
        video_hs_out_d2 <=  video_hs_out_d1;
    end
end
















endmodule
