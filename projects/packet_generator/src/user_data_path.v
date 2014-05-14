///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: user_data_path.v 5881 2010-01-04 19:53:50Z grg $
//
// Module: user_data_path.v
// Project: NF2.1
// Description: contains all the user instantiated modules
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

/******************************************************
 * Even numbered ports are IO sinks/sources
 * Odd numbered ports are CPU ports corresponding to
 * IO sinks/sources to rpovide direct access to them
 ******************************************************/
module user_data_path
  #(parameter DATA_WIDTH = 64,
    parameter CTRL_WIDTH=DATA_WIDTH/8,
    parameter UDP_REG_SRC_WIDTH = 2,
    parameter NUM_OUTPUT_QUEUES = 8,
    parameter NUM_INPUT_QUEUES = 8,
    parameter SRAM_DATA_WIDTH = DATA_WIDTH+CTRL_WIDTH,
    parameter SRAM_ADDR_WIDTH = 19,
    parameter COUNTER_WIDTH = 96,
    parameter COUNTER_FRACTION = 32
   )
   (
    input  [DATA_WIDTH-1:0]            in_data_0,
    input  [CTRL_WIDTH-1:0]            in_ctrl_0,
    input                              in_wr_0,
    output                             in_rdy_0,

    input  [DATA_WIDTH-1:0]            in_data_1,
    input  [CTRL_WIDTH-1:0]            in_ctrl_1,
    input                              in_wr_1,
    output                             in_rdy_1,

    input  [DATA_WIDTH-1:0]            in_data_2,
    input  [CTRL_WIDTH-1:0]            in_ctrl_2,
    input                              in_wr_2,
    output                             in_rdy_2,

    input  [DATA_WIDTH-1:0]            in_data_3,
    input  [CTRL_WIDTH-1:0]            in_ctrl_3,
    input                              in_wr_3,
    output                             in_rdy_3,

    input  [DATA_WIDTH-1:0]            in_data_4,
    input  [CTRL_WIDTH-1:0]            in_ctrl_4,
    input                              in_wr_4,
    output                             in_rdy_4,

    input  [DATA_WIDTH-1:0]            in_data_5,
    input  [CTRL_WIDTH-1:0]            in_ctrl_5,
    input                              in_wr_5,
    output                             in_rdy_5,

    input  [DATA_WIDTH-1:0]            in_data_6,
    input  [CTRL_WIDTH-1:0]            in_ctrl_6,
    input                              in_wr_6,
    output                             in_rdy_6,

    input  [DATA_WIDTH-1:0]            in_data_7,
    input  [CTRL_WIDTH-1:0]            in_ctrl_7,
    input                              in_wr_7,
    output                             in_rdy_7,

/****  not used
    // --- Interface to SATA
    input  [DATA_WIDTH-1:0]            in_data_5,
    input  [CTRL_WIDTH-1:0]            in_ctrl_5,
    input                              in_wr_5,
    output                             in_rdy_5,

    // --- Interface to the loopback queue
    input  [DATA_WIDTH-1:0]            in_data_6,
    input  [CTRL_WIDTH-1:0]            in_ctrl_6,
    input                              in_wr_6,
    output                             in_rdy_6,

    // --- Interface to a user queue
    input  [DATA_WIDTH-1:0]            in_data_7,
    input  [CTRL_WIDTH-1:0]            in_ctrl_7,
    input                              in_wr_7,
    output                             in_rdy_7,
*****/

    output  [DATA_WIDTH-1:0]           out_data_0,
    output  [CTRL_WIDTH-1:0]           out_ctrl_0,
    output                             out_wr_0,
    input                              out_rdy_0,

    output  [DATA_WIDTH-1:0]           out_data_1,
    output  [CTRL_WIDTH-1:0]           out_ctrl_1,
    output                             out_wr_1,
    input                              out_rdy_1,

    output  [DATA_WIDTH-1:0]           out_data_2,
    output  [CTRL_WIDTH-1:0]           out_ctrl_2,
    output                             out_wr_2,
    input                              out_rdy_2,

    output  [DATA_WIDTH-1:0]           out_data_3,
    output  [CTRL_WIDTH-1:0]           out_ctrl_3,
    output                             out_wr_3,
    input                              out_rdy_3,

    output  [DATA_WIDTH-1:0]           out_data_4,
    output  [CTRL_WIDTH-1:0]           out_ctrl_4,
    output                             out_wr_4,
    input                              out_rdy_4,

    output  [DATA_WIDTH-1:0]           out_data_5,
    output  [CTRL_WIDTH-1:0]           out_ctrl_5,
    output                             out_wr_5,
    input                              out_rdy_5,

    output  [DATA_WIDTH-1:0]           out_data_6,
    output  [CTRL_WIDTH-1:0]           out_ctrl_6,
    output                             out_wr_6,
    input                              out_rdy_6,

    output  [DATA_WIDTH-1:0]           out_data_7,
    output  [CTRL_WIDTH-1:0]           out_ctrl_7,
    output                             out_wr_7,
    input                              out_rdy_7,

/****  not used
    // --- Interface to SATA
    output  [DATA_WIDTH-1:0]           out_data_5,
    output  [CTRL_WIDTH-1:0]           out_ctrl_5,
    output                             out_wr_5,
    input                              out_rdy_5,

    // --- Interface to the loopback queue
    output  [DATA_WIDTH-1:0]           out_data_6,
    output  [CTRL_WIDTH-1:0]           out_ctrl_6,
    output                             out_wr_6,
    input                              out_rdy_6,

    // --- Interface to a user queue
    output  [DATA_WIDTH-1:0]           out_data_7,
    output  [CTRL_WIDTH-1:0]           out_ctrl_7,
    output                             out_wr_7,
    input                              out_rdy_7,
*****/

     // interface to SRAM
     output [SRAM_ADDR_WIDTH-1:0]       wr_0_addr,
     output                             wr_0_req,
     input                              wr_0_ack,
     output [SRAM_DATA_WIDTH-1:0]       wr_0_data,

     input                              rd_0_ack,
     input  [SRAM_DATA_WIDTH-1:0]       rd_0_data,
     input                              rd_0_vld,
     output [SRAM_ADDR_WIDTH-1:0]       rd_0_addr,
     output                             rd_0_req,

     // interface to DRAM
     /* TBD */

     // register interface
     input                              reg_req,
     output                             reg_ack,
     input                              reg_rd_wr_L,
     input [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr,
     output [`CPCI_NF2_DATA_WIDTH-1:0]  reg_rd_data,
     input [`CPCI_NF2_DATA_WIDTH-1:0]   reg_wr_data,

     // --- PTP counter
     input [COUNTER_WIDTH-1:COUNTER_FRACTION] counter_val,

     // misc
     input                              reset,
     input                              clk);


   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   //---------- Internal parameters -----------

   localparam NUM_IQ_BITS = log2(NUM_INPUT_QUEUES);

   localparam IN_ARB_STAGE_NUM = 2;
   localparam OP_LUT_STAGE_NUM = 4;
   localparam OQ_STAGE_NUM     = 6;
   localparam DELAY_STAGE_NUM  = 8;

   localparam SIG_VALUE_SIZE = 8; // use the pkt sizes in 64-bit words
   localparam ALL_SIG_VALUES_SIZE = 3*SIG_VALUE_SIZE;
   localparam SIGNAL_ID_SIZE = log2(NUM_OUTPUT_QUEUES);
   localparam ALL_SIGNAL_IDS_SIZE = 3*SIGNAL_ID_SIZE;

   //-------- Output wires -------
   wire [CTRL_WIDTH-1:0]            out_ctrl[NUM_OUTPUT_QUEUES/2-1:0];
   wire [DATA_WIDTH-1:0]            out_data[NUM_OUTPUT_QUEUES/2-1:0];
   wire                             out_wr[NUM_OUTPUT_QUEUES/2-1:0];
   wire                             out_rdy[NUM_OUTPUT_QUEUES/2-1:0];

   //-------- Input arbiter wires/regs -------
   wire                             in_arb_in_reg_req;
   wire                             in_arb_in_reg_ack;
   wire                             in_arb_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   in_arb_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  in_arb_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     in_arb_in_reg_src;

   //------- output port lut wires/regs ------
   wire [CTRL_WIDTH-1:0]            op_lut_in_ctrl;
   wire [DATA_WIDTH-1:0]            op_lut_in_data;
   wire                             op_lut_in_wr;
   wire                             op_lut_in_rdy;

   wire                             op_lut_in_reg_req;
   wire                             op_lut_in_reg_ack;
   wire                             op_lut_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   op_lut_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  op_lut_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     op_lut_in_reg_src;

   //------- packet capture lut wires/regs ------
   wire [CTRL_WIDTH-1:0]            pkt_cap_in_ctrl;
   wire [DATA_WIDTH-1:0]            pkt_cap_in_data;
   wire                             pkt_cap_in_wr;
   wire                             pkt_cap_in_rdy;

   wire                             pkt_cap_in_reg_req;
   wire                             pkt_cap_in_reg_ack;
   wire                             pkt_cap_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   pkt_cap_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  pkt_cap_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     pkt_cap_in_reg_src;

   //------- output queues wires/regs ------
   wire [CTRL_WIDTH-1:0]            oq_in_ctrl;
   wire [DATA_WIDTH-1:0]            oq_in_data;
   wire                             oq_in_wr;
   wire                             oq_in_rdy;

   wire                             oq_in_reg_req;
   wire                             oq_in_reg_ack;
   wire                             oq_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   oq_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  oq_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     oq_in_reg_src;

   wire [2:0]                       oq_signals;
   wire [ALL_SIGNAL_IDS_SIZE-1:0]   oq_signal_ids;
   wire [`CPCI_NF2_DATA_WIDTH*NUM_OUTPUT_QUEUES*2-1:0] oq_abs_regs;
   wire [ALL_SIG_VALUES_SIZE-1:0]   oq_signal_values;

   //-------- UDP register master wires/regs -------
   wire                             udp_reg_req_in;
   wire                             udp_reg_ack_in;
   wire                             udp_reg_rd_wr_L_in;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   udp_reg_addr_in;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  udp_reg_data_in;
   wire [UDP_REG_SRC_WIDTH-1:0]     udp_reg_src_in;

   //------- Pkt gen output sel module wires/regs ------
   wire [CTRL_WIDTH-1:0]            op_sel_in_ctrl[12-1:0];
   wire [DATA_WIDTH-1:0]            op_sel_in_data[12-1:0];
   wire                             op_sel_in_wr[12-1:0];
   wire                             op_sel_in_rdy[12-1:0];

   wire                             op_sel_in_reg_req;
   wire                             op_sel_in_reg_ack;
   wire                             op_sel_in_reg_rd_wr_L;
   wire [`UDP_REG_ADDR_WIDTH-1:0]   op_sel_in_reg_addr;
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  op_sel_in_reg_data;
   wire [UDP_REG_SRC_WIDTH-1:0]     op_sel_in_reg_src;

   //------- Pad module wires/regs ------
   wire [CTRL_WIDTH-1:0]            pad_in_ctrl[NUM_OUTPUT_QUEUES/2-1:0];
   wire [DATA_WIDTH-1:0]            pad_in_data[NUM_OUTPUT_QUEUES/2-1:0];
   wire                             pad_in_wr[NUM_OUTPUT_QUEUES/2-1:0];
   wire                             pad_in_rdy[NUM_OUTPUT_QUEUES/2-1:0];

   wire                             pad_in_reg_req[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire                             pad_in_reg_ack[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire                             pad_in_reg_rd_wr_L[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire [`UDP_REG_ADDR_WIDTH-1:0]   pad_in_reg_addr[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  pad_in_reg_data[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire [UDP_REG_SRC_WIDTH-1:0]     pad_in_reg_src[NUM_OUTPUT_QUEUES/2+1-1:0];

   //------- Delay module wires/regs ------
   wire [CTRL_WIDTH-1:0]            delay_in_ctrl[NUM_OUTPUT_QUEUES/2-1:0];
   wire [DATA_WIDTH-1:0]            delay_in_data[NUM_OUTPUT_QUEUES/2-1:0];
   wire                             delay_in_wr[NUM_OUTPUT_QUEUES/2-1:0];
   wire                             delay_in_rdy[NUM_OUTPUT_QUEUES/2-1:0];

   wire                             delay_in_reg_req[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire                             delay_in_reg_ack[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire                             delay_in_reg_rd_wr_L[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire [`UDP_REG_ADDR_WIDTH-1:0]   delay_in_reg_addr[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  delay_in_reg_data[NUM_OUTPUT_QUEUES/2+1-1:0];
   wire [UDP_REG_SRC_WIDTH-1:0]     delay_in_reg_src[NUM_OUTPUT_QUEUES/2+1-1:0];

   //------- Rate limiter wires/regs ------
   wire [CTRL_WIDTH-1:0]            rate_limiter_in_ctrl[NUM_OUTPUT_QUEUES-1:0];
   wire [DATA_WIDTH-1:0]            rate_limiter_in_data[NUM_OUTPUT_QUEUES-1:0];
   wire                             rate_limiter_in_wr[NUM_OUTPUT_QUEUES-1:0];
   wire                             rate_limiter_in_rdy[NUM_OUTPUT_QUEUES-1:0];

   wire [CTRL_WIDTH-1:0]            rate_limiter_out_ctrl[NUM_OUTPUT_QUEUES-1:0];
   wire [DATA_WIDTH-1:0]            rate_limiter_out_data[NUM_OUTPUT_QUEUES-1:0];
   wire                             rate_limiter_out_wr[NUM_OUTPUT_QUEUES-1:0];
   wire                             rate_limiter_out_rdy[NUM_OUTPUT_QUEUES-1:0];

   wire                             rate_limiter_in_reg_req[NUM_OUTPUT_QUEUES+1-1:0];
   wire                             rate_limiter_in_reg_ack[NUM_OUTPUT_QUEUES+1-1:0];
   wire                             rate_limiter_in_reg_rd_wr_L[NUM_OUTPUT_QUEUES+1-1:0];
   wire [`UDP_REG_ADDR_WIDTH-1:0]   rate_limiter_in_reg_addr[NUM_OUTPUT_QUEUES+1-1:0];
   wire [`CPCI_NF2_DATA_WIDTH-1:0]  rate_limiter_in_reg_data[NUM_OUTPUT_QUEUES+1-1:0];
   wire [UDP_REG_SRC_WIDTH-1:0]     rate_limiter_in_reg_src[NUM_OUTPUT_QUEUES+1-1:0];


   //--------- Connect the data path -----------

   input_arbiter
     #(.DATA_WIDTH(DATA_WIDTH),
       .CTRL_WIDTH(CTRL_WIDTH),
       .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
       .STAGE_NUMBER(IN_ARB_STAGE_NUM))
   input_arbiter
   (.out_data             (op_lut_in_data),
    .out_ctrl             (op_lut_in_ctrl),
    .out_wr               (op_lut_in_wr),
    .out_rdy              (op_lut_in_rdy),

    // --- Interface to the input queues
    .in_data_0            (in_data_0),
    .in_ctrl_0            (in_ctrl_0),
    .in_wr_0              (in_wr_0),
    .in_rdy_0             (in_rdy_0),

    .in_data_1            (in_data_1),
    .in_ctrl_1            (in_ctrl_1),
    .in_wr_1              (in_wr_1),
    .in_rdy_1             (in_rdy_1),

    .in_data_2            (in_data_2),
    .in_ctrl_2            (in_ctrl_2),
    .in_wr_2              (in_wr_2),
    .in_rdy_2             (in_rdy_2),

    .in_data_3            (in_data_3),
    .in_ctrl_3            (in_ctrl_3),
    .in_wr_3              (in_wr_3),
    .in_rdy_3             (in_rdy_3),

    .in_data_4            (in_data_4),
    .in_ctrl_4            (in_ctrl_4),
    .in_wr_4              (in_wr_4),
    .in_rdy_4             (in_rdy_4),

    .in_data_5            (in_data_5),
    .in_ctrl_5            (in_ctrl_5),
    .in_wr_5              (in_wr_5),
    .in_rdy_5             (in_rdy_5),

    .in_data_6            (in_data_6),
    .in_ctrl_6            (in_ctrl_6),
    .in_wr_6              (in_wr_6),
    .in_rdy_6             (in_rdy_6),

    .in_data_7            (in_data_7),
    .in_ctrl_7            (in_ctrl_7),
    .in_wr_7              (in_wr_7),
    .in_rdy_7             (in_rdy_7),

    // --- Register interface
    .reg_req_in           (in_arb_in_reg_req),
    .reg_ack_in           (in_arb_in_reg_ack),
    .reg_rd_wr_L_in       (in_arb_in_reg_rd_wr_L),
    .reg_addr_in          (in_arb_in_reg_addr),
    .reg_data_in          (in_arb_in_reg_data),
    .reg_src_in           (in_arb_in_reg_src),

    .reg_req_out          (op_lut_in_reg_req),
    .reg_ack_out          (op_lut_in_reg_ack),
    .reg_rd_wr_L_out      (op_lut_in_reg_rd_wr_L),
    .reg_addr_out         (op_lut_in_reg_addr),
    .reg_data_out         (op_lut_in_reg_data),
    .reg_src_out          (op_lut_in_reg_src),

    // --- Misc
    .reset                (reset),
    .clk                  (clk)
    );

   output_port_lookup
     #(.DATA_WIDTH(DATA_WIDTH),
       .CTRL_WIDTH(CTRL_WIDTH),
       .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
       .INPUT_ARBITER_STAGE_NUM(IN_ARB_STAGE_NUM),
       .STAGE_NUM(OP_LUT_STAGE_NUM),
       .NUM_OUTPUT_QUEUES(NUM_OUTPUT_QUEUES),
       .NUM_IQ_BITS(NUM_IQ_BITS))
   output_port_lookup
     (.out_data            (pkt_cap_in_data),
      .out_ctrl            (pkt_cap_in_ctrl),
      .out_wr              (pkt_cap_in_wr),
      .out_rdy             (pkt_cap_in_rdy),

      // --- Interface to the input arbiter
      .in_data             (op_lut_in_data),
      .in_ctrl             (op_lut_in_ctrl),
      .in_wr               (op_lut_in_wr),
      .in_rdy              (op_lut_in_rdy),

      // --- Register interface
      .reg_req_in           (op_lut_in_reg_req),
      .reg_ack_in           (op_lut_in_reg_ack),
      .reg_rd_wr_L_in       (op_lut_in_reg_rd_wr_L),
      .reg_addr_in          (op_lut_in_reg_addr),
      .reg_data_in          (op_lut_in_reg_data),
      .reg_src_in           (op_lut_in_reg_src),

      .reg_req_out          (pkt_cap_in_reg_req),
      .reg_ack_out          (pkt_cap_in_reg_ack),
      .reg_rd_wr_L_out      (pkt_cap_in_reg_rd_wr_L),
      .reg_addr_out         (pkt_cap_in_reg_addr),
      .reg_data_out         (pkt_cap_in_reg_data),
      .reg_src_out          (pkt_cap_in_reg_src),

      // --- Misc
      .clk                 (clk),
      .reset               (reset));

   pkt_capture
   #(
      .DATA_WIDTH          (DATA_WIDTH),
      .CTRL_WIDTH          (CTRL_WIDTH),
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH)
   ) pkt_capture (
      // --- data path interface
      .out_data                           (oq_in_data),
      .out_ctrl                           (oq_in_ctrl),
      .out_wr                             (oq_in_wr),
      .out_rdy                            (oq_in_rdy),

      .in_data                            (pkt_cap_in_data),
      .in_ctrl                            (pkt_cap_in_ctrl),
      .in_wr                              (pkt_cap_in_wr),
      .in_rdy                             (pkt_cap_in_rdy),

      // --- Register interface
      .reg_req_in                         (pkt_cap_in_reg_req),
      .reg_ack_in                         (pkt_cap_in_reg_ack),
      .reg_rd_wr_L_in                     (pkt_cap_in_reg_rd_wr_L),
      .reg_addr_in                        (pkt_cap_in_reg_addr),
      .reg_data_in                        (pkt_cap_in_reg_data),
      .reg_src_in                         (pkt_cap_in_reg_src),

      .reg_req_out                        (oq_in_reg_req),
      .reg_ack_out                        (oq_in_reg_ack),
      .reg_rd_wr_L_out                    (oq_in_reg_rd_wr_L),
      .reg_addr_out                       (oq_in_reg_addr),
      .reg_data_out                       (oq_in_reg_data),
      .reg_src_out                        (oq_in_reg_src),

      // --- Misc
      .clk                                (clk),
      .reset                              (reset)
   );


   output_queues
     #(.DATA_WIDTH(DATA_WIDTH),
       .CTRL_WIDTH(CTRL_WIDTH),
       .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH),
       .OP_LUT_STAGE_NUM(OP_LUT_STAGE_NUM),
       .NUM_OUTPUT_QUEUES(12),
       .STAGE_NUM(OQ_STAGE_NUM),
       .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH))
   output_queues
   (// --- data path interface
    .out_data_0                           (op_sel_in_data[0]),
    .out_ctrl_0                           (op_sel_in_ctrl[0]),
    .out_wr_0                             (op_sel_in_wr[0]),
    .out_rdy_0                            (op_sel_in_rdy[0]),

    .out_data_1                           (op_sel_in_data[1]),
    .out_ctrl_1                           (op_sel_in_ctrl[1]),
    .out_wr_1                             (op_sel_in_wr[1]),
    .out_rdy_1                            (op_sel_in_rdy[1]),

    .out_data_2                           (op_sel_in_data[2]),
    .out_ctrl_2                           (op_sel_in_ctrl[2]),
    .out_wr_2                             (op_sel_in_wr[2]),
    .out_rdy_2                            (op_sel_in_rdy[2]),

    .out_data_3                           (op_sel_in_data[3]),
    .out_ctrl_3                           (op_sel_in_ctrl[3]),
    .out_wr_3                             (op_sel_in_wr[3]),
    .out_rdy_3                            (op_sel_in_rdy[3]),

    .out_data_4                           (op_sel_in_data[4]),
    .out_ctrl_4                           (op_sel_in_ctrl[4]),
    .out_wr_4                             (op_sel_in_wr[4]),
    .out_rdy_4                            (op_sel_in_rdy[4]),

    .out_data_5                           (op_sel_in_data[5]),
    .out_ctrl_5                           (op_sel_in_ctrl[5]),
    .out_wr_5                             (op_sel_in_wr[5]),
    .out_rdy_5                            (op_sel_in_rdy[5]),

    .out_data_6                           (op_sel_in_data[6]),
    .out_ctrl_6                           (op_sel_in_ctrl[6]),
    .out_wr_6                             (op_sel_in_wr[6]),
    .out_rdy_6                            (op_sel_in_rdy[6]),

    .out_data_7                           (op_sel_in_data[7]),
    .out_ctrl_7                           (op_sel_in_ctrl[7]),
    .out_wr_7                             (op_sel_in_wr[7]),
    .out_rdy_7                            (op_sel_in_rdy[7]),

    .out_data_8                           (op_sel_in_data[8]),
    .out_ctrl_8                           (op_sel_in_ctrl[8]),
    .out_wr_8                             (op_sel_in_wr[8]),
    .out_rdy_8                            (op_sel_in_rdy[8]),

    .out_data_9                           (op_sel_in_data[9]),
    .out_ctrl_9                           (op_sel_in_ctrl[9]),
    .out_wr_9                             (op_sel_in_wr[9]),
    .out_rdy_9                            (op_sel_in_rdy[9]),

    .out_data_10                          (op_sel_in_data[10]),
    .out_ctrl_10                          (op_sel_in_ctrl[10]),
    .out_wr_10                            (op_sel_in_wr[10]),
    .out_rdy_10                           (op_sel_in_rdy[10]),

    .out_data_11                          (op_sel_in_data[11]),
    .out_ctrl_11                          (op_sel_in_ctrl[11]),
    .out_wr_11                            (op_sel_in_wr[11]),
    .out_rdy_11                           (op_sel_in_rdy[11]),

    // --- Interface to the previous module
    .in_data                              (oq_in_data),
    .in_ctrl                              (oq_in_ctrl),
    .in_rdy                               (oq_in_rdy),
    .in_wr                                (oq_in_wr),

    // --- Register interface
    .reg_req_in                           (oq_in_reg_req),
    .reg_ack_in                           (oq_in_reg_ack),
    .reg_rd_wr_L_in                       (oq_in_reg_rd_wr_L),
    .reg_addr_in                          (oq_in_reg_addr),
    .reg_data_in                          (oq_in_reg_data),
    .reg_src_in                           (oq_in_reg_src),

    .reg_req_out                          (op_sel_in_reg_req),
    .reg_ack_out                          (op_sel_in_reg_ack),
    .reg_rd_wr_L_out                      (op_sel_in_reg_rd_wr_L),
    .reg_addr_out                         (op_sel_in_reg_addr),
    .reg_data_out                         (op_sel_in_reg_data),
    .reg_src_out                          (op_sel_in_reg_src),

    // --- SRAM sm interface
    .wr_0_addr                            (wr_0_addr),
    .wr_0_req                             (wr_0_req),
    .wr_0_ack                             (wr_0_ack),
    .wr_0_data                            (wr_0_data),
    .rd_0_ack                             (rd_0_ack),
    .rd_0_data                            (rd_0_data),
    .rd_0_vld                             (rd_0_vld),
    .rd_0_addr                            (rd_0_addr),
    .rd_0_req                             (rd_0_req),

    //.oq_abs_regs                          (oq_abs_regs),
    //.oq_signals                           (oq_signals),
    //.oq_signal_ids                        (oq_signal_ids),
    //.oq_signal_values                     (oq_signal_values),

    // --- Misc
    .clk                                  (clk),
    .reset                                (reset));

   pkt_gen_output_sel
   #(
      .DATA_WIDTH          (DATA_WIDTH),
      .CTRL_WIDTH          (CTRL_WIDTH),
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
      .NUM_OUTPUT_QUEUES   (12)
   ) pkt_gen_output_sel (
      // --- data path interface
      .in_data_0                          (op_sel_in_data[0]),
      .in_ctrl_0                          (op_sel_in_ctrl[0]),
      .in_rdy_0                           (op_sel_in_rdy[0]),
      .in_wr_0                            (op_sel_in_wr[0]),

      .in_data_1                          (op_sel_in_data[1]),
      .in_ctrl_1                          (op_sel_in_ctrl[1]),
      .in_rdy_1                           (op_sel_in_rdy[1]),
      .in_wr_1                            (op_sel_in_wr[1]),

      .in_data_2                          (op_sel_in_data[2]),
      .in_ctrl_2                          (op_sel_in_ctrl[2]),
      .in_rdy_2                           (op_sel_in_rdy[2]),
      .in_wr_2                            (op_sel_in_wr[2]),

      .in_data_3                          (op_sel_in_data[3]),
      .in_ctrl_3                          (op_sel_in_ctrl[3]),
      .in_rdy_3                           (op_sel_in_rdy[3]),
      .in_wr_3                            (op_sel_in_wr[3]),

      .in_data_4                          (op_sel_in_data[4]),
      .in_ctrl_4                          (op_sel_in_ctrl[4]),
      .in_rdy_4                           (op_sel_in_rdy[4]),
      .in_wr_4                            (op_sel_in_wr[4]),

      .in_data_5                          (op_sel_in_data[5]),
      .in_ctrl_5                          (op_sel_in_ctrl[5]),
      .in_wr_5                            (op_sel_in_wr[5]),
      .in_rdy_5                           (op_sel_in_rdy[5]),

      .in_data_6                          (op_sel_in_data[6]),
      .in_ctrl_6                          (op_sel_in_ctrl[6]),
      .in_wr_6                            (op_sel_in_wr[6]),
      .in_rdy_6                           (op_sel_in_rdy[6]),

      .in_data_7                          (op_sel_in_data[7]),
      .in_ctrl_7                          (op_sel_in_ctrl[7]),
      .in_wr_7                            (op_sel_in_wr[7]),
      .in_rdy_7                           (op_sel_in_rdy[7]),

      .in_data_8                          (op_sel_in_data[8]),
      .in_ctrl_8                          (op_sel_in_ctrl[8]),
      .in_wr_8                            (op_sel_in_wr[8]),
      .in_rdy_8                           (op_sel_in_rdy[8]),

      .in_data_9                          (op_sel_in_data[9]),
      .in_ctrl_9                          (op_sel_in_ctrl[9]),
      .in_wr_9                            (op_sel_in_wr[9]),
      .in_rdy_9                           (op_sel_in_rdy[9]),

      .in_data_10                         (op_sel_in_data[10]),
      .in_ctrl_10                         (op_sel_in_ctrl[10]),
      .in_wr_10                           (op_sel_in_wr[10]),
      .in_rdy_10                          (op_sel_in_rdy[10]),

      .in_data_11                         (op_sel_in_data[11]),
      .in_ctrl_11                         (op_sel_in_ctrl[11]),
      .in_wr_11                           (op_sel_in_wr[11]),
      .in_rdy_11                          (op_sel_in_rdy[11]),

      .out_data_0                         (pad_in_data[0]),
      .out_ctrl_0                         (pad_in_ctrl[0]),
      .out_rdy_0                          (pad_in_rdy[0]),
      .out_wr_0                           (pad_in_wr[0]),

      .out_data_1                         (rate_limiter_in_data[1]),
      .out_ctrl_1                         (rate_limiter_in_ctrl[1]),
      .out_rdy_1                          (rate_limiter_in_rdy[1]),
      .out_wr_1                           (rate_limiter_in_wr[1]),

      .out_data_2                         (pad_in_data[1]),
      .out_ctrl_2                         (pad_in_ctrl[1]),
      .out_rdy_2                          (pad_in_rdy[1]),
      .out_wr_2                           (pad_in_wr[1]),

      .out_data_3                         (rate_limiter_in_data[3]),
      .out_ctrl_3                         (rate_limiter_in_ctrl[3]),
      .out_rdy_3                          (rate_limiter_in_rdy[3]),
      .out_wr_3                           (rate_limiter_in_wr[3]),

      .out_data_4                         (pad_in_data[2]),
      .out_ctrl_4                         (pad_in_ctrl[2]),
      .out_rdy_4                          (pad_in_rdy[2]),
      .out_wr_4                           (pad_in_wr[2]),

      .out_data_5                         (rate_limiter_in_data[5]),
      .out_ctrl_5                         (rate_limiter_in_ctrl[5]),
      .out_wr_5                           (rate_limiter_in_wr[5]),
      .out_rdy_5                          (rate_limiter_in_rdy[5]),

      .out_data_6                         (pad_in_data[3]),
      .out_ctrl_6                         (pad_in_ctrl[3]),
      .out_wr_6                           (pad_in_wr[3]),
      .out_rdy_6                          (pad_in_rdy[3]),

      .out_data_7                         (rate_limiter_in_data[7]),
      .out_ctrl_7                         (rate_limiter_in_ctrl[7]),
      .out_wr_7                           (rate_limiter_in_wr[7]),
      .out_rdy_7                          (rate_limiter_in_rdy[7]),

      // --- Register interface
      .reg_req_in                         (op_sel_in_reg_req),
      .reg_ack_in                         (op_sel_in_reg_ack),
      .reg_rd_wr_L_in                     (op_sel_in_reg_rd_wr_L),
      .reg_addr_in                        (op_sel_in_reg_addr),
      .reg_data_in                        (op_sel_in_reg_data),
      .reg_src_in                         (op_sel_in_reg_src),

      .reg_req_out                        (pad_in_reg_req[0]),
      .reg_ack_out                        (pad_in_reg_ack[0]),
      .reg_rd_wr_L_out                    (pad_in_reg_rd_wr_L[0]),
      .reg_addr_out                       (pad_in_reg_addr[0]),
      .reg_data_out                       (pad_in_reg_data[0]),
      .reg_src_out                        (pad_in_reg_src[0]),

      // --- Misc
      .clk                                  (clk),
      .reset                                (reset)
   );

   generate
      genvar i;
      for (i = 0; i < NUM_OUTPUT_QUEUES/2; i = i + 1) begin : pad_modules
         pad #(
            .DATA_WIDTH (DATA_WIDTH),
            .CTRL_WIDTH (CTRL_WIDTH)
         ) pad (
            .out_data                           (rate_limiter_in_data[i * 2]),
            .out_ctrl                           (rate_limiter_in_ctrl[i * 2]),
            .out_wr                             (rate_limiter_in_wr[i * 2]),
            .out_rdy                            (rate_limiter_in_rdy[i * 2]),

            .in_data                            (pad_in_data[i]),
            .in_ctrl                            (pad_in_ctrl[i]),
            .in_wr                              (pad_in_wr[i]),
            .in_rdy                             (pad_in_rdy[i]),

            // --- Register interface

            .reg_req_in                         (pad_in_reg_req[i]),
            .reg_ack_in                         (pad_in_reg_ack[i]),
            .reg_rd_wr_L_in                     (pad_in_reg_rd_wr_L[i]),
            .reg_addr_in                        (pad_in_reg_addr[i]),
            .reg_data_in                        (pad_in_reg_data[i]),
            .reg_src_in                         (pad_in_reg_src[i]),

            .reg_req_out                        (pad_in_reg_req[i + 1]),
            .reg_ack_out                        (pad_in_reg_ack[i + 1]),
            .reg_rd_wr_L_out                    (pad_in_reg_rd_wr_L[i + 1]),
            .reg_addr_out                       (pad_in_reg_addr[i + 1]),
            .reg_data_out                       (pad_in_reg_data[i + 1]),
            .reg_src_out                        (pad_in_reg_src[i + 1]),

            // --- Misc
            .clk                                (clk),
            .reset                              (reset)
         );
      end
   endgenerate


   generate
      for (i = 0; i < NUM_OUTPUT_QUEUES; i = i + 1) begin : rate_limiter_modules
         rate_limiter #(
            .DATA_WIDTH                         (DATA_WIDTH),
            .UDP_REG_SRC_WIDTH                  (UDP_REG_SRC_WIDTH)
         ) rate_limiter
           (
            .out_data                           (rate_limiter_out_data[i]),
            .out_ctrl                           (rate_limiter_out_ctrl[i]),
            .out_wr                             (rate_limiter_out_wr[i]),
            .out_rdy                            (rate_limiter_out_rdy[i]),

            .in_data                            (rate_limiter_in_data[i]),
            .in_ctrl                            (rate_limiter_in_ctrl[i]),
            .in_wr                              (rate_limiter_in_wr[i]),
            .in_rdy                             (rate_limiter_in_rdy[i]),

            // --- Register interface
            .reg_req_in                         (rate_limiter_in_reg_req[i]),
            .reg_ack_in                         (rate_limiter_in_reg_ack[i]),
            .reg_rd_wr_L_in                     (rate_limiter_in_reg_rd_wr_L[i]),
            .reg_addr_in                        (rate_limiter_in_reg_addr[i]),
            .reg_data_in                        (rate_limiter_in_reg_data[i]),
            .reg_src_in                         (rate_limiter_in_reg_src[i]),

            .reg_req_out                        (rate_limiter_in_reg_req[i+1]),
            .reg_ack_out                        (rate_limiter_in_reg_ack[i+1]),
            .reg_rd_wr_L_out                    (rate_limiter_in_reg_rd_wr_L[i+1]),
            .reg_addr_out                       (rate_limiter_in_reg_addr[i+1]),
            .reg_data_out                       (rate_limiter_in_reg_data[i+1]),
            .reg_src_out                        (rate_limiter_in_reg_src[i+1]),

            // --- Misc
            .clk                                (clk),
            .reset                              (reset)
         );
      end
   endgenerate


   defparam rate_limiter_modules[0].rate_limiter.RATE_LIMIT_BLOCK_TAG = `RATE_LIMIT_0_BLOCK_ADDR;
   defparam rate_limiter_modules[1].rate_limiter.RATE_LIMIT_BLOCK_TAG = `RATE_LIMIT_1_BLOCK_ADDR;
   defparam rate_limiter_modules[2].rate_limiter.RATE_LIMIT_BLOCK_TAG = `RATE_LIMIT_2_BLOCK_ADDR;
   defparam rate_limiter_modules[3].rate_limiter.RATE_LIMIT_BLOCK_TAG = `RATE_LIMIT_3_BLOCK_ADDR;
   defparam rate_limiter_modules[4].rate_limiter.RATE_LIMIT_BLOCK_TAG = `RATE_LIMIT_4_BLOCK_ADDR;
   defparam rate_limiter_modules[5].rate_limiter.RATE_LIMIT_BLOCK_TAG = `RATE_LIMIT_5_BLOCK_ADDR;
   defparam rate_limiter_modules[6].rate_limiter.RATE_LIMIT_BLOCK_TAG = `RATE_LIMIT_6_BLOCK_ADDR;
   defparam rate_limiter_modules[7].rate_limiter.RATE_LIMIT_BLOCK_TAG = `RATE_LIMIT_7_BLOCK_ADDR;


   generate
      for (i = 0; i < NUM_OUTPUT_QUEUES/2; i = i + 1) begin : delay_modules
         delay #(
            .DATA_WIDTH                         (DATA_WIDTH),
            .UDP_REG_SRC_WIDTH                  (UDP_REG_SRC_WIDTH),
            .COUNTER_WIDTH                      (COUNTER_WIDTH),
            .COUNTER_FRACTION                   (COUNTER_FRACTION)
         ) delay
           (
            .out_data                           (out_data[i]),
            .out_ctrl                           (out_ctrl[i]),
            .out_wr                             (out_wr[i]),
            .out_rdy                            (out_rdy[i]),

            .in_data                            (delay_in_data[i]),
            .in_ctrl                            (delay_in_ctrl[i]),
            .in_wr                              (delay_in_wr[i]),
            .in_rdy                             (delay_in_rdy[i]),

            // --- Register interface
            .reg_req_in                         (delay_in_reg_req[i]),
            .reg_ack_in                         (delay_in_reg_ack[i]),
            .reg_rd_wr_L_in                     (delay_in_reg_rd_wr_L[i]),
            .reg_addr_in                        (delay_in_reg_addr[i]),
            .reg_data_in                        (delay_in_reg_data[i]),
            .reg_src_in                         (delay_in_reg_src[i]),

            .reg_req_out                        (delay_in_reg_req[i+1]),
            .reg_ack_out                        (delay_in_reg_ack[i+1]),
            .reg_rd_wr_L_out                    (delay_in_reg_rd_wr_L[i+1]),
            .reg_addr_out                       (delay_in_reg_addr[i+1]),
            .reg_data_out                       (delay_in_reg_data[i+1]),
            .reg_src_out                        (delay_in_reg_src[i+1]),

            // PTP counter
            .counter_val                        (counter_val),

            // --- Misc
            .clk                                (clk),
            .reset                              (reset)
         );
      end
   endgenerate



   //--------------------------------------------------
   //
   // --- User data path register master
   //
   //     Takes the register accesses from core,
   //     sends them around the User Data Path module
   //     ring and then returns the replies back
   //     to the core
   //
   //--------------------------------------------------

   udp_reg_master #(
      .UDP_REG_SRC_WIDTH                  (UDP_REG_SRC_WIDTH)
   ) udp_reg_master
     (
      // Core register interface signals
      .core_reg_req                       (reg_req),
      .core_reg_ack                       (reg_ack),
      .core_reg_rd_wr_L                   (reg_rd_wr_L),

      .core_reg_addr                      (reg_addr),

      .core_reg_rd_data                   (reg_rd_data),
      .core_reg_wr_data                   (reg_wr_data),

      // UDP register interface signals   (output)
      .reg_req_out                        (in_arb_in_reg_req),
      .reg_ack_out                        (in_arb_in_reg_ack),
      .reg_rd_wr_L_out                    (in_arb_in_reg_rd_wr_L),

      .reg_addr_out                       (in_arb_in_reg_addr),
      .reg_data_out                       (in_arb_in_reg_data),

      .reg_src_out                        (in_arb_in_reg_src),

      // UDP register interface signals   (input)
      .reg_req_in                         (udp_reg_req_in),
      .reg_ack_in                         (udp_reg_ack_in),
      .reg_rd_wr_L_in                     (udp_reg_rd_wr_L_in),

      .reg_addr_in                        (udp_reg_addr_in),
      .reg_data_in                        (udp_reg_data_in),

      .reg_src_in                         (udp_reg_src_in),

      //
      .clk                                (clk),
      .reset                              (reset)
   );


   //--------------------------------------------------
   //
   // --- Mapping from internal signals to output signals
   //
   //--------------------------------------------------
   assign out_ctrl_0 = out_ctrl[0];
   assign out_data_0 = out_data[0];
   assign out_wr_0 = out_wr[0];
   assign out_rdy[0] = out_rdy_0;

   assign out_ctrl_1 = rate_limiter_out_ctrl[1];
   assign out_data_1 = rate_limiter_out_data[1];
   assign out_wr_1 = rate_limiter_out_wr[1];
   assign rate_limiter_out_rdy[1] = out_rdy_1;

   assign out_ctrl_2 = out_ctrl[1];
   assign out_data_2 = out_data[1];
   assign out_wr_2 = out_wr[1];
   assign out_rdy[1] = out_rdy_2;

   assign out_ctrl_3 = rate_limiter_out_ctrl[3];
   assign out_data_3 = rate_limiter_out_data[3];
   assign out_wr_3 = rate_limiter_out_wr[3];
   assign rate_limiter_out_rdy[3] = out_rdy_3;

   assign out_ctrl_4 = out_ctrl[2];
   assign out_data_4 = out_data[2];
   assign out_wr_4 = out_wr[2];
   assign out_rdy[2] = out_rdy_4;

   assign out_ctrl_5 = rate_limiter_out_ctrl[5];
   assign out_data_5 = rate_limiter_out_data[5];
   assign out_wr_5 = rate_limiter_out_wr[5];
   assign rate_limiter_out_rdy[5] = out_rdy_5;

   assign out_ctrl_6 = out_ctrl[3];
   assign out_data_6 = out_data[3];
   assign out_wr_6 = out_wr[3];
   assign out_rdy[3] = out_rdy_6;

   assign out_ctrl_7 = rate_limiter_out_ctrl[7];
   assign out_data_7 = rate_limiter_out_data[7];
   assign out_wr_7 = rate_limiter_out_wr[7];
   assign rate_limiter_out_rdy[7] = out_rdy_7;

   assign udp_reg_req_in      = delay_in_reg_req[NUM_OUTPUT_QUEUES/2];
   assign udp_reg_ack_in      = delay_in_reg_ack[NUM_OUTPUT_QUEUES/2];
   assign udp_reg_rd_wr_L_in  = delay_in_reg_rd_wr_L[NUM_OUTPUT_QUEUES/2];
   assign udp_reg_addr_in     = delay_in_reg_addr[NUM_OUTPUT_QUEUES/2];
   assign udp_reg_data_in     = delay_in_reg_data[NUM_OUTPUT_QUEUES/2];
   assign udp_reg_src_in      = delay_in_reg_src[NUM_OUTPUT_QUEUES/2];

   assign delay_in_reg_req[0]    = rate_limiter_in_reg_req[NUM_OUTPUT_QUEUES];
   assign delay_in_reg_ack[0]    = rate_limiter_in_reg_ack[NUM_OUTPUT_QUEUES];
   assign delay_in_reg_rd_wr_L[0]= rate_limiter_in_reg_rd_wr_L[NUM_OUTPUT_QUEUES];
   assign delay_in_reg_addr[0]   = rate_limiter_in_reg_addr[NUM_OUTPUT_QUEUES];
   assign delay_in_reg_data[0]   = rate_limiter_in_reg_data[NUM_OUTPUT_QUEUES];
   assign delay_in_reg_src[0]    = rate_limiter_in_reg_src[NUM_OUTPUT_QUEUES];

   assign rate_limiter_in_reg_req[0]    = pad_in_reg_req[NUM_OUTPUT_QUEUES/2];
   assign rate_limiter_in_reg_ack[0]    = pad_in_reg_ack[NUM_OUTPUT_QUEUES/2];
   assign rate_limiter_in_reg_rd_wr_L[0]= pad_in_reg_rd_wr_L[NUM_OUTPUT_QUEUES/2];
   assign rate_limiter_in_reg_addr[0]   = pad_in_reg_addr[NUM_OUTPUT_QUEUES/2];
   assign rate_limiter_in_reg_data[0]   = pad_in_reg_data[NUM_OUTPUT_QUEUES/2];
   assign rate_limiter_in_reg_src[0]    = pad_in_reg_src[NUM_OUTPUT_QUEUES/2];

   generate
      for (i = 0; i < NUM_OUTPUT_QUEUES/2; i = i + 1) begin : delay_input
         assign delay_in_ctrl[i] = rate_limiter_out_ctrl[i*2];
         assign delay_in_data[i] = rate_limiter_out_data[i*2];
         assign delay_in_wr[i] = rate_limiter_out_wr[i*2];
         assign rate_limiter_out_rdy[i*2] = delay_in_rdy[i];
      end
   endgenerate

endmodule // user_data_path

