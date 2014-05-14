///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: pkt_gen_output_sel.v 4071 2008-06-13 21:48:37Z grg $
//
// Module: pkt_gen_output_sel.v
// Project: Packet generator
// Description: Selector for the various outputs
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module pkt_gen_output_sel
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2,
      parameter NUM_OUTPUT_QUEUES = 12
   )
   (
      // --- data path interface
      input  [DATA_WIDTH-1:0]             in_data_0,
      input  [CTRL_WIDTH-1:0]             in_ctrl_0,
      output                              in_rdy_0,
      input                               in_wr_0,

      input  [DATA_WIDTH-1:0]             in_data_1,
      input  [CTRL_WIDTH-1:0]             in_ctrl_1,
      output                              in_rdy_1,
      input                               in_wr_1,

      input  [DATA_WIDTH-1:0]             in_data_2,
      input  [CTRL_WIDTH-1:0]             in_ctrl_2,
      output                              in_rdy_2,
      input                               in_wr_2,

      input  [DATA_WIDTH-1:0]             in_data_3,
      input  [CTRL_WIDTH-1:0]             in_ctrl_3,
      output                              in_rdy_3,
      input                               in_wr_3,

      input  [DATA_WIDTH-1:0]             in_data_4,
      input  [CTRL_WIDTH-1:0]             in_ctrl_4,
      output                              in_rdy_4,
      input                               in_wr_4,

      input  [DATA_WIDTH-1:0]             in_data_5,
      input  [CTRL_WIDTH-1:0]             in_ctrl_5,
      input                               in_wr_5,
      output                              in_rdy_5,

      input  [DATA_WIDTH-1:0]             in_data_6,
      input  [CTRL_WIDTH-1:0]             in_ctrl_6,
      input                               in_wr_6,
      output                              in_rdy_6,

      input  [DATA_WIDTH-1:0]             in_data_7,
      input  [CTRL_WIDTH-1:0]             in_ctrl_7,
      input                               in_wr_7,
      output                              in_rdy_7,

      input  [DATA_WIDTH-1:0]             in_data_8,
      input  [CTRL_WIDTH-1:0]             in_ctrl_8,
      input                               in_wr_8,
      output                              in_rdy_8,

      input  [DATA_WIDTH-1:0]             in_data_9,
      input  [CTRL_WIDTH-1:0]             in_ctrl_9,
      input                               in_wr_9,
      output                              in_rdy_9,

      input  [DATA_WIDTH-1:0]             in_data_10,
      input  [CTRL_WIDTH-1:0]             in_ctrl_10,
      input                               in_wr_10,
      output                              in_rdy_10,

      input  [DATA_WIDTH-1:0]             in_data_11,
      input  [CTRL_WIDTH-1:0]             in_ctrl_11,
      input                               in_wr_11,
      output                              in_rdy_11,

      output  [DATA_WIDTH-1:0]            out_data_0,
      output  [CTRL_WIDTH-1:0]            out_ctrl_0,
      input                               out_rdy_0,
      output                              out_wr_0,

      output  [DATA_WIDTH-1:0]            out_data_1,
      output  [CTRL_WIDTH-1:0]            out_ctrl_1,
      input                               out_rdy_1,
      output                              out_wr_1,

      output  [DATA_WIDTH-1:0]            out_data_2,
      output  [CTRL_WIDTH-1:0]            out_ctrl_2,
      input                               out_rdy_2,
      output                              out_wr_2,

      output  [DATA_WIDTH-1:0]            out_data_3,
      output  [CTRL_WIDTH-1:0]            out_ctrl_3,
      input                               out_rdy_3,
      output                              out_wr_3,

      output  [DATA_WIDTH-1:0]            out_data_4,
      output  [CTRL_WIDTH-1:0]            out_ctrl_4,
      input                               out_rdy_4,
      output                              out_wr_4,

      output  [DATA_WIDTH-1:0]            out_data_5,
      output  [CTRL_WIDTH-1:0]            out_ctrl_5,
      output                              out_wr_5,
      input                               out_rdy_5,

      output  [DATA_WIDTH-1:0]            out_data_6,
      output  [CTRL_WIDTH-1:0]            out_ctrl_6,
      output                              out_wr_6,
      input                               out_rdy_6,

      output  [DATA_WIDTH-1:0]            out_data_7,
      output  [CTRL_WIDTH-1:0]            out_ctrl_7,
      output                              out_wr_7,
      input                               out_rdy_7,

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
      input                                 clk,
      input                                 reset
   );

//---------------------- Wires/Regs -------------------------------

wire [3:0] enable;


//----------------------- Modules ---------------------------------

port_mux
   #(
      .DATA_WIDTH (DATA_WIDTH),
      .CTRL_WIDTH (CTRL_WIDTH)
   ) port_mux_0 (
      // --- data path interface
      .out_data                             (out_data_0),
      .out_ctrl                             (out_ctrl_0),
      .out_wr                               (out_wr_0),
      .out_rdy                              (out_rdy_0),

      .in_data_0                            (in_data_0),
      .in_ctrl_0                            (in_ctrl_0),
      .in_wr_0                              (in_wr_0),
      .in_rdy_0                             (in_rdy_0),

      .in_data_1                            (in_data_8),
      .in_ctrl_1                            (in_ctrl_8),
      .in_wr_1                              (in_wr_8),
      .in_rdy_1                             (in_rdy_8),

      // --- Register interface
      .select                               (enable[0]),

      // --- Misc
      .clk                                  (clk),
      .reset                                (reset)
   );

assign out_data_1 = in_data_1;
assign out_ctrl_1 = in_ctrl_1;
assign out_wr_1 = in_wr_1;
assign in_rdy_1 = out_rdy_1;


port_mux
   #(
      .DATA_WIDTH (DATA_WIDTH),
      .CTRL_WIDTH (CTRL_WIDTH)
   ) port_mux_2 (
      // --- data path interface
      .out_data                             (out_data_2),
      .out_ctrl                             (out_ctrl_2),
      .out_wr                               (out_wr_2),
      .out_rdy                              (out_rdy_2),

      .in_data_0                            (in_data_2),
      .in_ctrl_0                            (in_ctrl_2),
      .in_wr_0                              (in_wr_2),
      .in_rdy_0                             (in_rdy_2),

      .in_data_1                            (in_data_9),
      .in_ctrl_1                            (in_ctrl_9),
      .in_wr_1                              (in_wr_9),
      .in_rdy_1                             (in_rdy_9),

      // --- Register interface
      .select                               (enable[1]),

      // --- Misc
      .clk                                  (clk),
      .reset                                (reset)
   );

assign out_data_3 = in_data_3;
assign out_ctrl_3 = in_ctrl_3;
assign out_wr_3 = in_wr_3;
assign in_rdy_3 = out_rdy_3;


port_mux
   #(
      .DATA_WIDTH (DATA_WIDTH),
      .CTRL_WIDTH (CTRL_WIDTH)
   ) port_mux_4 (
      // --- data path interface
      .out_data                             (out_data_4),
      .out_ctrl                             (out_ctrl_4),
      .out_wr                               (out_wr_4),
      .out_rdy                              (out_rdy_4),

      .in_data_0                            (in_data_4),
      .in_ctrl_0                            (in_ctrl_4),
      .in_wr_0                              (in_wr_4),
      .in_rdy_0                             (in_rdy_4),

      .in_data_1                            (in_data_10),
      .in_ctrl_1                            (in_ctrl_10),
      .in_wr_1                              (in_wr_10),
      .in_rdy_1                             (in_rdy_10),

      // --- Register interface
      .select                               (enable[2]),

      // --- Misc
      .clk                                  (clk),
      .reset                                (reset)
   );

assign out_data_5 = in_data_5;
assign out_ctrl_5 = in_ctrl_5;
assign out_wr_5 = in_wr_5;
assign in_rdy_5 = out_rdy_5;


port_mux
   #(
      .DATA_WIDTH (DATA_WIDTH),
      .CTRL_WIDTH (CTRL_WIDTH)
   ) port_mux_6 (
      // --- data path interface
      .out_data                             (out_data_6),
      .out_ctrl                             (out_ctrl_6),
      .out_wr                               (out_wr_6),
      .out_rdy                              (out_rdy_6),

      .in_data_0                            (in_data_6),
      .in_ctrl_0                            (in_ctrl_6),
      .in_wr_0                              (in_wr_6),
      .in_rdy_0                             (in_rdy_6),

      .in_data_1                            (in_data_11),
      .in_ctrl_1                            (in_ctrl_11),
      .in_wr_1                              (in_wr_11),
      .in_rdy_1                             (in_rdy_11),

      // --- Register interface
      .select                               (enable[3]),

      // --- Misc
      .clk                                  (clk),
      .reset                                (reset)
   );

assign out_data_7 = in_data_7;
assign out_ctrl_7 = in_ctrl_7;
assign out_wr_7 = in_wr_7;
assign in_rdy_7 = out_rdy_7;


pkt_gen_ctrl_reg_min #(
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) pkt_gen_ctrl_reg_min (
      // --- data path interface
      .enable                               (enable),

      // --- Register interface
      .reg_req_in                           (reg_req_in),
      .reg_ack_in                           (reg_ack_in),
      .reg_rd_wr_L_in                       (reg_rd_wr_L_in),
      .reg_addr_in                          (reg_addr_in),
      .reg_data_in                          (reg_data_in),
      .reg_src_in                           (reg_src_in),

      .reg_req_out                          (reg_req_out),
      .reg_ack_out                          (reg_ack_out),
      .reg_rd_wr_L_out                      (reg_rd_wr_L_out),
      .reg_addr_out                         (reg_addr_out),
      .reg_data_out                         (reg_data_out),
      .reg_src_out                          (reg_src_out),

      // --- Misc
      .clk                                  (clk),
      .reset                                (reset)
   );

endmodule
