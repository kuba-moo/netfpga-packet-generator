///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: pkt_capture.v 5904 2010-02-10 04:20:29Z grg $
//
// Module: pkt_capture.v
// Project: Packet generator
// Description: Perform "packet capture" processing
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module pkt_capture
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2,
      parameter IO_QUEUE_STAGE_NUM = `IO_QUEUE_STAGE_NUM,
      parameter TIMESTAMP_CTRL  = 'hfe,
      parameter BYTE_CNT_WIDTH = 40,
      parameter TIME_WIDTH = 64
   )
   (
      // --- data path interface
      output     [DATA_WIDTH-1:0]         out_data,
      output     [CTRL_WIDTH-1:0]         out_ctrl,
      output                              out_wr,
      input                               out_rdy,

      input  [DATA_WIDTH-1:0]             in_data,
      input  [CTRL_WIDTH-1:0]             in_ctrl,
      input                               in_wr,
      output                              in_rdy,

      // --- Register interface
      input                               reg_req_in,
      input                               reg_ack_in,
      input                               reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

      output                              reg_req_out,
      output                              reg_ack_out,
      output                              reg_rd_wr_L_out,
      output [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_out,
      output [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_out,
      output [UDP_REG_SRC_WIDTH-1:0]      reg_src_out,

      // --- Misc
      input                               clk,
      input                               reset
   );

   //--------------------- Internal Parameters -----------------------
   localparam NUM_MACS        = 4;

   //---------------------- Wires/Regs -------------------------------

wire [3:0] enable;
wire [3:0] drop;

wire [`CPCI_NF2_DATA_WIDTH - 1:0]   pkt_cnt_0;
wire [BYTE_CNT_WIDTH - 1:0]         byte_cnt_0;
wire [TIME_WIDTH - 1:0]             time_first_0;
wire [TIME_WIDTH - 1:0]             time_last_0;

wire [`CPCI_NF2_DATA_WIDTH - 1:0]   pkt_cnt_1;
wire [BYTE_CNT_WIDTH - 1:0]         byte_cnt_1;
wire [TIME_WIDTH - 1:0]             time_first_1;
wire [TIME_WIDTH - 1:0]             time_last_1;

wire [`CPCI_NF2_DATA_WIDTH - 1:0]   pkt_cnt_2;
wire [BYTE_CNT_WIDTH - 1:0]         byte_cnt_2;
wire [TIME_WIDTH - 1:0]             time_first_2;
wire [TIME_WIDTH - 1:0]             time_last_2;

wire [`CPCI_NF2_DATA_WIDTH - 1:0]   pkt_cnt_3;
wire [BYTE_CNT_WIDTH - 1:0]         byte_cnt_3;
wire [TIME_WIDTH - 1:0]             time_first_3;
wire [TIME_WIDTH - 1:0]             time_last_3;

wire                                rx_stats_reg_req_in;
wire                                rx_stats_reg_ack_in;
wire                                rx_stats_reg_rd_wr_L_in;
wire [`UDP_REG_ADDR_WIDTH-1:0]      rx_stats_reg_addr_in;
wire [`CPCI_NF2_DATA_WIDTH-1:0]     rx_stats_reg_data_in;
wire [UDP_REG_SRC_WIDTH-1:0]        rx_stats_reg_src_in;

wire [`CPCI_NF2_DATA_WIDTH - 1:0]   pkt_gen_ctrl;

// --- Modules

pkt_capture_main
   #(
      .DATA_WIDTH                (DATA_WIDTH),
      .CTRL_WIDTH                (CTRL_WIDTH),
      .IO_QUEUE_STAGE_NUM        (IO_QUEUE_STAGE_NUM),
      .TIMESTAMP_CTRL            (TIMESTAMP_CTRL),
      .BYTE_CNT_WIDTH            (BYTE_CNT_WIDTH),
      .TIME_WIDTH                (TIME_WIDTH)
   ) pkt_capture_main (
      // --- data path interface
      .out_data                           (out_data),
      .out_ctrl                           (out_ctrl),
      .out_wr                             (out_wr),
      .out_rdy                            (out_rdy),

      .in_data                            (in_data),
      .in_ctrl                            (in_ctrl),
      .in_wr                              (in_wr),
      .in_rdy                             (in_rdy),

      // --- Register interface
      .enable                             (enable),
      .drop                               (drop),

      .pkt_cnt_0                          (pkt_cnt_0),
      .byte_cnt_0                         (byte_cnt_0),
      .time_first_0                       (time_first_0),
      .time_last_0                        (time_last_0),

      .pkt_cnt_1                          (pkt_cnt_1),
      .byte_cnt_1                         (byte_cnt_1),
      .time_first_1                       (time_first_1),
      .time_last_1                        (time_last_1),

      .pkt_cnt_2                          (pkt_cnt_2),
      .byte_cnt_2                         (byte_cnt_2),
      .time_first_2                       (time_first_2),
      .time_last_2                        (time_last_2),

      .pkt_cnt_3                          (pkt_cnt_3),
      .byte_cnt_3                         (byte_cnt_3),
      .time_first_3                       (time_first_3),
      .time_last_3                        (time_last_3),


      // --- Misc
      .clk                                (clk),
      .reset                              (reset)
   );


generic_sw_regs #(
      .UDP_REG_SRC_WIDTH     (UDP_REG_SRC_WIDTH),
      .TAG                   ({`PKT_GEN_BLOCK_ADDR, {(`PKT_GEN_CTRL_GROUP_BLOCK_ADDR_WIDTH){1'b0}}}),
      .REG_ADDR_WIDTH        (`PKT_GEN_REG_ADDR_WIDTH - `PKT_GEN_CTRL_GROUP_BLOCK_ADDR_WIDTH),
      .NUM_REGS_USED         (1)
   ) ctrl_reg (
      .reg_req_in                            (reg_req_in),
      .reg_ack_in                            (reg_ack_in),
      .reg_rd_wr_L_in                        (reg_rd_wr_L_in),
      .reg_addr_in                           (reg_addr_in),
      .reg_data_in                           (reg_data_in),
      .reg_src_in                            (reg_src_in),

      .reg_req_out                           (rx_stats_reg_req_in),
      .reg_ack_out                           (rx_stats_reg_ack_in),
      .reg_rd_wr_L_out                       (rx_stats_reg_rd_wr_L_in),
      .reg_addr_out                          (rx_stats_reg_addr_in),
      .reg_data_out                          (rx_stats_reg_data_in),
      .reg_src_out                           (rx_stats_reg_src_in),

      // --- SW regs interface
      .software_regs                         ({pkt_gen_ctrl}), // signals from the software

      .clk                                 (clk),
      .reset                               (reset)
    );

generic_regs #(
      .UDP_REG_SRC_WIDTH     (UDP_REG_SRC_WIDTH),
      .TAG                   ({`PKT_GEN_BLOCK_ADDR, `PKT_GEN_CTRL_GROUP_BLOCK_ADDR}),
      .REG_ADDR_WIDTH        (`PKT_GEN_CTRL_GROUP_REG_ADDR_WIDTH),
      .NUM_COUNTERS          (0),
      .NUM_SOFTWARE_REGS     (0),
      .NUM_HARDWARE_REGS     (7),
      .NUM_INSTANCES         (NUM_MACS)
   ) rx_stats_regs (
      .reg_req_in                            (rx_stats_reg_req_in),
      .reg_ack_in                            (rx_stats_reg_ack_in),
      .reg_rd_wr_L_in                        (rx_stats_reg_rd_wr_L_in),
      .reg_addr_in                           (rx_stats_reg_addr_in),
      .reg_data_in                           (rx_stats_reg_data_in),
      .reg_src_in                            (rx_stats_reg_src_in),

      .reg_req_out                           (reg_req_out),
      .reg_ack_out                           (reg_ack_out),
      .reg_rd_wr_L_out                       (reg_rd_wr_L_out),
      .reg_addr_out                          (reg_addr_out),
      .reg_data_out                          (reg_data_out),
      .reg_src_out                           (reg_src_out),

      // --- counters interface
      .counter_updates                       ('h0),
      .counter_decrement                     ('h0),

      // --- SW regs interface
      .software_regs                         (),

      // --- HW regs interface
      .hardware_regs                         ({
                     time_last_3[31:0],
                     time_last_2[31:0],
                     time_last_1[31:0],
                     time_last_0[31:0],
                     time_last_3[TIME_WIDTH-1:32],
                     time_last_2[TIME_WIDTH-1:32],
                     time_last_1[TIME_WIDTH-1:32],
                     time_last_0[TIME_WIDTH-1:32],

                     time_first_3[31:0],
                     time_first_2[31:0],
                     time_first_1[31:0],
                     time_first_0[31:0],
                     time_first_3[TIME_WIDTH-1:32],
                     time_first_2[TIME_WIDTH-1:32],
                     time_first_1[TIME_WIDTH-1:32],
                     time_first_0[TIME_WIDTH-1:32],

                     byte_cnt_3[31:0],
                     byte_cnt_2[31:0],
                     byte_cnt_1[31:0],
                     byte_cnt_0[31:0],
                     {(64 - BYTE_CNT_WIDTH){1'b0}}, byte_cnt_3[BYTE_CNT_WIDTH-1:32],
                     {(64 - BYTE_CNT_WIDTH){1'b0}}, byte_cnt_2[BYTE_CNT_WIDTH-1:32],
                     {(64 - BYTE_CNT_WIDTH){1'b0}}, byte_cnt_1[BYTE_CNT_WIDTH-1:32],
                     {(64 - BYTE_CNT_WIDTH){1'b0}}, byte_cnt_0[BYTE_CNT_WIDTH-1:32],

                     pkt_cnt_3,
                     pkt_cnt_2,
                     pkt_cnt_1,
                     pkt_cnt_0
                  }),

      .clk                                 (clk),
      .reset                               (reset)
    );

assign enable = pkt_gen_ctrl[3:0];
assign drop = pkt_gen_ctrl[11:8];

endmodule
