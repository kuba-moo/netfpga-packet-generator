///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: oq_regs_eval_empty.v 5803 2009-08-04 21:23:10Z g9coving $
//
// Module: oq_regs_eval_empty.v
// Project: NF2.1
// Description: Evaluates whether a queue is empty
//
// Currently looks at the number of packets in the queue
// Added support for a maximum number of iterations (useful for the packet
// generator application)
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module oq_regs_eval_empty
  #(
      parameter SRAM_ADDR_WIDTH     = 19,
      parameter CTRL_WIDTH          = 8,
      parameter UDP_REG_SRC_WIDTH   = 2,
      parameter NUM_OUTPUT_QUEUES   = 8,
      parameter NUM_OQ_WIDTH        = log2(NUM_OUTPUT_QUEUES),
      parameter ITER_WIDTH          = `OQ_PKT_GEN_ITER_WIDTH,
      parameter PKT_LEN_WIDTH       = 11,
      parameter PKT_WORDS_WIDTH     = PKT_LEN_WIDTH-log2(CTRL_WIDTH),
      parameter MAX_PKT             = 2048/CTRL_WIDTH,   // allow for 2K bytes,
      parameter MIN_PKT             = 60/CTRL_WIDTH + 1,
      parameter PKTS_IN_RAM_WIDTH   = log2((2**SRAM_ADDR_WIDTH)/MIN_PKT)
   )

   (
      // --- Inputs from dst update ---
      input                               dst_update,
      input [NUM_OQ_WIDTH-1:0]            dst_oq,
      input [PKTS_IN_RAM_WIDTH-1:0]       dst_num_pkts_in_q,
      input                               dst_num_pkts_in_q_done,

      // --- Inputs from src update ---
      input                               src_update,
      input [NUM_OQ_WIDTH-1:0]            src_oq,
      input [PKTS_IN_RAM_WIDTH-1:0]       src_num_pkts_in_q,
      input                               src_num_pkts_in_q_done,

      input [ITER_WIDTH-1:0]              src_max_iter,
      input [ITER_WIDTH-1:0]              src_curr_iter,
      input                               src_curr_iter_done,

      // --- Inputs from reg writes update ---
      input                               max_iter_reg_req,
      input                               max_iter_reg_wr,
      input [NUM_OQ_WIDTH-1:0]            max_iter_reg_wr_addr,
      input [ITER_WIDTH-1:0]              max_iter_reg_wr_data,

      // --- Clear the flag ---
      input                               initialize,
      input [NUM_OQ_WIDTH-1:0]            initialize_oq,

      output     [NUM_OUTPUT_QUEUES-1:0]  empty,


      // --- Misc
      input                               clk,
      input                               reset
   );

   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2


   // ------------- Internal parameters --------------


   // ------------- Wires/reg ------------------

   reg [NUM_OUTPUT_QUEUES-1:0]   empty_pkts_in_q;
   reg [NUM_OUTPUT_QUEUES-1:0]   empty_iter;

   wire                    src_empty_pkts_in_q;
   wire                    src_empty_iter;
   wire                    dst_empty_pkts_in_q;
   wire                    dst_empty_iter;
   reg                     dst_empty_pkts_in_q_held;
   reg                     dst_empty_iter_held;

   reg                     src_update_d1;

   reg [NUM_OQ_WIDTH-1:0]  dst_oq_held;
   reg [NUM_OQ_WIDTH-1:0]  src_oq_held;

   reg                     dst_num_pkts_in_q_done_held;

   reg [ITER_WIDTH-1:0]    src_max_iter_held;

   reg                     reset_max_iter;
   reg [NUM_OQ_WIDTH-1:0]  max_iter_cnt;

   reg                     max_iter_reg_req_held;
   reg                     max_iter_reg_wr_held;
   reg [NUM_OQ_WIDTH-1:0]  max_iter_reg_wr_addr_held;
   reg [ITER_WIDTH-1:0]    max_iter_reg_wr_data_held;

   // ------------- Logic ------------------
   assign empty = empty_pkts_in_q & empty_iter;

   // If we have a non-zero max-iter then set the pkts empty to 1 as we want
   // to use the iter empty
   assign src_empty_pkts_in_q = src_num_pkts_in_q == 'h0 ||
                                src_max_iter_held != 'h0;
   assign dst_empty_pkts_in_q = dst_num_pkts_in_q == 'h0;

   assign src_empty_iter = src_curr_iter >= src_max_iter_held ||
                           src_max_iter_held == 'h0;

   always @(posedge clk)
   begin
      src_update_d1 <= src_update;

      if (reset) begin
         empty_pkts_in_q <= {NUM_OUTPUT_QUEUES{1'b1}};
         empty_iter <= {NUM_OUTPUT_QUEUES{1'b1}};

         max_iter_reg_req_held <= 1'b0;
         max_iter_reg_wr_held <= 1'b0;
      end
      else begin
         if (dst_update) begin
            dst_oq_held <= dst_oq;
         end

         if (src_update) begin
            src_oq_held <= src_oq;
         end

         // Latch the maximums the cycle immediately following the update
         // notifications. The update notifications are linked to the read
         // ports of the appropriate registers so the read value will always
         // be returned in the next cycle.
         if (src_update_d1) begin
            src_max_iter_held <= src_max_iter;
         end

         // Update the empty status giving preference to removes over stores
         // since we don't want to accidentally try removing from an empty
         // queue
         if (src_num_pkts_in_q_done) begin
            empty_pkts_in_q[src_oq_held] <= src_empty_pkts_in_q;

            dst_num_pkts_in_q_done_held <= dst_num_pkts_in_q_done;
            dst_empty_pkts_in_q_held <= dst_empty_pkts_in_q;
         end
         else if (dst_num_pkts_in_q_done) begin
            empty_pkts_in_q[dst_oq_held] <= dst_empty_pkts_in_q;
         end
         else if (dst_num_pkts_in_q_done_held) begin
            empty_pkts_in_q[dst_oq_held] <= dst_empty_pkts_in_q_held;
         end
         else if (initialize) begin
            empty_pkts_in_q[initialize_oq] <= 1'b1;
         end

         if (src_curr_iter_done) begin
            empty_iter[src_oq_held] <= src_empty_iter;

            max_iter_reg_req_held      <= max_iter_reg_req;
            max_iter_reg_wr_held       <= max_iter_reg_wr;
            max_iter_reg_wr_addr_held  <= max_iter_reg_wr_addr;
            max_iter_reg_wr_data_held  <= max_iter_reg_wr_data;
         end
         else if (max_iter_reg_wr && max_iter_reg_req) begin
            empty_iter[max_iter_reg_wr_addr] <= max_iter_reg_wr_data == 'h0;
         end
         else if (max_iter_reg_wr_held && max_iter_reg_req_held) begin
            empty_iter[max_iter_reg_wr_addr_held] <= max_iter_reg_wr_data_held == 'h0;

            max_iter_reg_req_held <= 1'b0;
            max_iter_reg_wr_held <= 1'b0;
         end
         else if (initialize) begin
            empty_iter[initialize_oq] <= 1'b1;
         end
      end
   end

endmodule // oq_regs_eval_empty
