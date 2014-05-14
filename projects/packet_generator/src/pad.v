///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: pad.v 5883 2010-01-06 22:11:39Z grg $
//
// Module: pad.v
// Project: packet generator
// Description: pads a packet with data to a certain length. Allows headers to
//              be placed in SRAM and their content padded on the way out.
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "udp_defines.v"

module pad #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2,
      parameter STAGE_NUM = `PAD_CTRL_VAL
   )
   (
      output reg [DATA_WIDTH-1:0]         out_data,
      output reg [CTRL_WIDTH-1:0]         out_ctrl,
      output reg                          out_wr,
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
      output  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_out,
      output  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_out,
      output  [UDP_REG_SRC_WIDTH-1:0]     reg_src_out,

      // --- Misc
      input                               clk,
      input                               reset
   );


   //----------------------- local parameters --------------------------
   localparam IN_PROCESS_HDR  = 0;
   localparam IN_WAIT_FOR_EOP = 1;

   localparam OUT_WAIT_FOR_PKT   = 0;
   localparam OUT_PROCESS_HDRS   = 1;
   localparam OUT_PROCESS_NONPAD = 2;
   localparam OUT_PROCESS_PAD    = 3;


   //----------------------- wires/regs---------------------------------
   wire [CTRL_WIDTH-1:0]   in_fifo_out_ctrl;
   wire [DATA_WIDTH-1:0]   in_fifo_out_data;

   reg                     in_fifo_rd_en;
   wire                    in_fifo_nearly_full;
   wire                    in_fifo_empty;

   reg                     in_state;
   reg [15:0]              in_nonpad_byte_len;
   reg [15:0]              in_nonpad_word_len;
   reg [15:0]              in_pad_byte_len;
   reg [15:0]              in_pad_word_len;

   reg                     wait_for_len_copy;

   reg [1:0]               out_state;
   reg [1:0]               out_state_nxt;

   reg                     out_wr_nxt;
   reg [CTRL_WIDTH-1:0]    out_ctrl_nxt;
   reg [DATA_WIDTH-1:0]    out_data_nxt;

   reg [15:0]              out_nonpad_byte_len;
   reg [15:0]              out_nonpad_byte_len_nxt;
   reg [15:0]              out_nonpad_word_len;
   reg [15:0]              out_nonpad_word_len_nxt;

   reg [15:0]              out_pad_byte_len;
   reg [15:0]              out_pad_byte_len_nxt;
   reg [15:0]              out_pad_word_len;
   reg [15:0]              out_pad_word_len_nxt;


   //------------------------ Modules ----------------------------------
   fallthrough_small_fifo #(
      .WIDTH(CTRL_WIDTH+DATA_WIDTH),
      .MAX_DEPTH_BITS(2),
      .PROG_FULL_THRESHOLD(3)
   ) input_fifo (
      .din              ({in_ctrl, in_data}),   // Data in
      .wr_en            (in_wr),                // Write enable
      .rd_en            (in_fifo_rd_en),       // Read the nxt word
      .dout             ({in_fifo_out_ctrl, in_fifo_out_data}),
      .full             (),
      .nearly_full      (in_fifo_nearly_full),
      .empty            (in_fifo_empty),
      .reset            (reset),
      .clk              (clk)
   );


   //----------------------- pad logic -----------------------

   assign in_rdy = !in_fifo_nearly_full && !wait_for_len_copy;

   /*
    * Incoming state machine:
    * Extract the two sets of lengths from the packet. The two lengths are:
    *   - length of packet in memory excluding padding
    *   - length of packet including padding
    */
   always @(posedge clk) begin
      if (reset) begin
         in_state <= IN_PROCESS_HDR;

         in_nonpad_byte_len   <= 'h0;
         in_nonpad_word_len   <= 'h0;

         in_pad_byte_len      <= 'h0;
         in_pad_word_len      <= 'h0;
      end
      else begin
         // FIXME: Add synchronization b/w state machines

         case (in_state)
            IN_PROCESS_HDR: begin
               if (in_wr) begin
                  if (in_ctrl == 'h0) begin
                     in_state <= IN_WAIT_FOR_EOP;
                  end
                  else if (in_ctrl == `IO_QUEUE_STAGE_NUM) begin
                     in_nonpad_byte_len <= in_data[`IOQ_BYTE_LEN_POS +: 16];
                     in_nonpad_word_len <= in_data[`IOQ_WORD_LEN_POS +: 16];
                  end
                  else if (in_ctrl == STAGE_NUM) begin
                     in_pad_byte_len <= in_data[`IOQ_BYTE_LEN_POS +: 16];
                     in_pad_word_len <= in_data[`IOQ_WORD_LEN_POS +: 16];
                  end
               end
            end // case: IN_PROCESS_HDR

            IN_WAIT_FOR_EOP: begin
               if (in_wr) begin
                  if (in_ctrl != 'h0) begin
                     in_state <= IN_PROCESS_HDR;

                     in_nonpad_byte_len   <= 'h0;
                     in_nonpad_word_len   <= 'h0;

                     in_pad_byte_len      <= 'h0;
                     in_pad_word_len      <= 'h0;
                  end
               end
            end // case: IN_WAIT_FOR_EOP
         endcase
      end
   end

   /*
    * Outgoing state machine:
    *
    * Copy data words from input to output. Pad the packet to the length
    * specified by the pad length if it exists, otherwise leave as it is.
    */
   always @(*) begin
      out_state_nxt           = out_state;

      out_wr_nxt              = 0;
      out_ctrl_nxt            = in_fifo_out_ctrl;
      out_data_nxt            = in_fifo_out_data;

      in_fifo_rd_en           = 0;

      out_nonpad_byte_len_nxt = out_nonpad_byte_len;
      out_nonpad_word_len_nxt = out_nonpad_word_len;

      out_pad_byte_len_nxt = out_pad_byte_len;
      out_pad_word_len_nxt = out_pad_word_len;

      case(out_state)
         OUT_WAIT_FOR_PKT: begin
            // Wait until the input state machine has processed the header of
            // the packet
            if (in_state != IN_PROCESS_HDR && !in_fifo_empty) begin
               out_nonpad_byte_len_nxt = in_nonpad_byte_len;
               out_nonpad_word_len_nxt = in_nonpad_word_len;

               // Work out what the padded lengths should be
               // Note: No sanity checking done on values
               if (in_pad_word_len != 'h0) begin
                  out_pad_byte_len_nxt = in_pad_byte_len;
                  out_pad_word_len_nxt = in_pad_word_len;
               end
               else begin
                  out_pad_byte_len_nxt = in_nonpad_byte_len;
                  out_pad_word_len_nxt = in_nonpad_word_len;
               end

               out_state_nxt = OUT_PROCESS_HDRS;
            end
         end // case: OUT_WAIT_FOR_PKT

         OUT_PROCESS_HDRS: begin
            if (out_rdy && !in_fifo_empty) begin
               in_fifo_rd_en = 1;

               // Update the length header as it passes by
               if (in_fifo_out_ctrl == `IO_QUEUE_STAGE_NUM) begin
                  out_ctrl_nxt   = in_fifo_out_ctrl;
                  out_data_nxt   = {
                        in_fifo_out_data[`IOQ_DST_PORT_POS +: 16],
                        out_pad_word_len,
                        in_fifo_out_data[`IOQ_SRC_PORT_POS +: 16],
                        out_pad_byte_len
                     };
                  out_wr_nxt     = 1;
               end
               else begin
                  // Don't write the pad header
                  out_wr_nxt     = in_fifo_out_ctrl != STAGE_NUM;

                  // Identify the first word of the packet body
                  if (in_fifo_out_ctrl == 'h0) begin
                     out_nonpad_byte_len_nxt = out_nonpad_byte_len - 'h8;
                     out_nonpad_word_len_nxt = out_nonpad_word_len_nxt - 'h1;

                     out_pad_byte_len_nxt = out_pad_byte_len - 'h8;
                     out_pad_word_len_nxt = out_pad_word_len_nxt - 'h1;

                     out_state_nxt = OUT_PROCESS_NONPAD;
                  end
               end
            end
         end // case: OUT_PROCESS_HDRS

         OUT_PROCESS_NONPAD: begin
            if (out_rdy && !in_fifo_empty) begin
               in_fifo_rd_en = 1;
               out_wr_nxt    = 1;

               // Forward all data verbatim. When we hit the last word of the
               // non-pad data we need to add zeros to the data.
               if (out_nonpad_word_len == 'h1) begin
                  // If the pad and non-pad word lengths are the same then
                  // we'd better update the ctrl word.
                  if (out_nonpad_word_len == out_pad_word_len) begin
                     out_state_nxt = OUT_WAIT_FOR_PKT;

                     case (out_pad_byte_len[2:0])
                        'h1 : out_ctrl_nxt = 'h80;
                        'h2 : out_ctrl_nxt = 'h40;
                        'h3 : out_ctrl_nxt = 'h20;
                        'h4 : out_ctrl_nxt = 'h10;
                        'h5 : out_ctrl_nxt = 'h08;
                        'h6 : out_ctrl_nxt = 'h04;
                        'h7 : out_ctrl_nxt = 'h02;
                        default : out_ctrl_nxt = 'h01;
                     endcase
                  end
                  else begin
                     out_state_nxt = OUT_PROCESS_PAD;
                     out_ctrl_nxt  = 'h0;
                  end

                  // Copy the correct number of non-pad bytes and then pad
                  // with zeros.
                  case (out_nonpad_byte_len[2:0])
                     'h1 : out_data_nxt = {in_fifo_out_data[63:56], 56'h0};
                     'h2 : out_data_nxt = {in_fifo_out_data[63:48], 48'h0};
                     'h3 : out_data_nxt = {in_fifo_out_data[63:40], 40'h0};
                     'h4 : out_data_nxt = {in_fifo_out_data[63:32], 32'h0};
                     'h5 : out_data_nxt = {in_fifo_out_data[63:24], 24'h0};
                     'h6 : out_data_nxt = {in_fifo_out_data[63:16], 16'h0};
                     'h7 : out_data_nxt = {in_fifo_out_data[63:8],  8'h0};
                     default : out_data_nxt = in_fifo_out_data;
                  endcase
               end

               // Update the counters
               out_nonpad_byte_len_nxt = out_nonpad_byte_len - 'h8;
               out_nonpad_word_len_nxt = out_nonpad_word_len_nxt - 'h1;

               out_pad_byte_len_nxt = out_pad_byte_len - 'h8;
               out_pad_word_len_nxt = out_pad_word_len_nxt - 'h1;
            end
         end // case: OUT_PROCESS_HDRS

         OUT_PROCESS_PAD: begin
            if (out_rdy) begin
               out_wr_nxt  = 1;
               out_data_nxt= 'h0;

               // Set the ctrl word appropriately depending on whether we've
               // reached the end of the pad
               if (out_pad_word_len != 'h1) begin
                  out_ctrl_nxt= 'h0;
               end
               else begin
                  out_state_nxt = OUT_WAIT_FOR_PKT;

                  case (out_pad_byte_len[2:0])
                     'h1 : out_ctrl_nxt = 'h80;
                     'h2 : out_ctrl_nxt = 'h40;
                     'h3 : out_ctrl_nxt = 'h20;
                     'h4 : out_ctrl_nxt = 'h10;
                     'h5 : out_ctrl_nxt = 'h08;
                     'h6 : out_ctrl_nxt = 'h04;
                     'h7 : out_ctrl_nxt = 'h02;
                     default : out_ctrl_nxt = 'h01;
                  endcase
               end

               // Update the counters
               out_pad_byte_len_nxt = out_pad_byte_len - 'h8;
               out_pad_word_len_nxt = out_pad_word_len_nxt - 'h1;
            end
         end // case: OUT_PROCESS_PAD

      endcase // case(out_state)
   end // always @ (*)

   always @(posedge clk) begin
      if(reset) begin
         out_state            <= OUT_WAIT_FOR_PKT;

         out_wr               <= 1'b0;
         out_ctrl             <= 'h0;
         out_data             <= 'h0;

         out_nonpad_byte_len  <= 'h0;
         out_nonpad_word_len  <= 'h0;

         out_pad_byte_len     <= 'h0;
         out_pad_word_len     <= 'h0;
      end
      else begin
         out_state            <= out_state_nxt;

         out_wr               <= out_wr_nxt;
         out_ctrl             <= out_ctrl_nxt;
         out_data             <= out_data_nxt;

         out_nonpad_byte_len  <= out_nonpad_byte_len_nxt;
         out_nonpad_word_len  <= out_nonpad_word_len_nxt;

         out_pad_byte_len     <= out_pad_byte_len_nxt;
         out_pad_word_len     <= out_pad_word_len_nxt;
      end // else: !if(reset)
   end

   /*
    * State machine to track whether the lengths have been copied from the
    * input to the output state machine
    */
   always @(posedge clk) begin
      if (reset) begin
         wait_for_len_copy <= 1'b0;
      end
      else begin
         // Has the input state machine just stored the length?
         if (in_state == IN_PROCESS_HDR && in_wr && in_ctrl == 'h0)
            wait_for_len_copy <= 1'b1;
         // Is the output state machine in a position to copy the lengths?
         else if (out_state == OUT_WAIT_FOR_PKT && in_state != IN_PROCESS_HDR && !in_fifo_empty)
            wait_for_len_copy <= 1'b0;
      end
   end

   // --- Registers ---
   assign reg_req_out      = reg_req_in;
   assign reg_ack_out      = reg_ack_in;
   assign reg_rd_wr_L_out  = reg_rd_wr_L_in;
   assign reg_addr_out     = reg_addr_in;
   assign reg_data_out     = reg_data_in;
   assign reg_src_out      = reg_src_in;

endmodule // pad
