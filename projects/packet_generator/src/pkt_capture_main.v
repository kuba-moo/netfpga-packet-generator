///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: pkt_capture_main.v 5900 2010-02-09 20:35:23Z grg $
//
// Module: pkt_capture_main.v
// Project: Packet generator
// Description: Main packet capture module
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module pkt_capture_main
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter IO_QUEUE_STAGE_NUM = `IO_QUEUE_STAGE_NUM,
      parameter TIMESTAMP_CTRL  = 'hfe,
      parameter BYTE_CNT_WIDTH = 40,
      parameter TIME_WIDTH = 64
   )
   (
      // --- data path interface
      output reg [DATA_WIDTH-1:0]         out_data,
      output reg [CTRL_WIDTH-1:0]         out_ctrl,
      output reg                          out_wr,
      input                               out_rdy,

      input  [DATA_WIDTH-1:0]             in_data,
      input  [CTRL_WIDTH-1:0]             in_ctrl,
      input                               in_wr,
      output                              in_rdy,

      // --- Register interface
      input [3:0]                         enable,
      input [3:0]                         drop,

      output [`CPCI_NF2_DATA_WIDTH - 1:0] pkt_cnt_0,
      output [BYTE_CNT_WIDTH - 1:0]       byte_cnt_0,
      output [TIME_WIDTH - 1:0]           time_first_0,
      output [TIME_WIDTH - 1:0]           time_last_0,

      output [`CPCI_NF2_DATA_WIDTH - 1:0] pkt_cnt_1,
      output [BYTE_CNT_WIDTH - 1:0]       byte_cnt_1,
      output [TIME_WIDTH - 1:0]           time_first_1,
      output [TIME_WIDTH - 1:0]           time_last_1,

      output [`CPCI_NF2_DATA_WIDTH - 1:0] pkt_cnt_2,
      output [BYTE_CNT_WIDTH - 1:0]       byte_cnt_2,
      output [TIME_WIDTH - 1:0]           time_first_2,
      output [TIME_WIDTH - 1:0]           time_last_2,

      output [`CPCI_NF2_DATA_WIDTH - 1:0] pkt_cnt_3,
      output [BYTE_CNT_WIDTH - 1:0]       byte_cnt_3,
      output [TIME_WIDTH - 1:0]           time_first_3,
      output [TIME_WIDTH - 1:0]           time_last_3,

      // --- Misc
      input                               clk,
      input                               reset
   );

   // Include the log2 function
   `LOG2_FUNC

   //--------------------- Internal Parameter-------------------------
   localparam IN_MODULE_HDRS  = 0;
   localparam ADD_PKT_HDR     = 1;
   localparam ADD_TIMESTAMP   = 2;
   localparam IN_PACKET       = 3;
   localparam DROP_HDR        = 4;

   localparam DA              = {`PKT_CAP_DA};
   localparam SA              = {`PKT_CAP_SA};
   localparam ETHERTYPE       = `PKT_CAP_ETHERTYPE;

   localparam NUM_MACS        = 4;
   localparam NUM_MACS_WIDTH  = log2(NUM_MACS);

   //---------------------- Wires/Regs -------------------------------
   reg [15:0]           one_hot_src;
   reg [NUM_MACS_WIDTH-1:0] src;
   reg [NUM_MACS_WIDTH-1:0] src_held;
   reg [NUM_MACS_WIDTH-1:0] src_held_nxt;
   reg [2:0]            state, state_nxt;
   reg [2:0]            state_d1;
   wire [15:0]          enable_mapped;
   wire [15:0]          drop_mapped;

   reg [31:0]           pkt_cnt[NUM_MACS-1:0];
   reg [39:0]           byte_cnt[NUM_MACS-1:0];
   reg [63:0]           time_first[NUM_MACS-1:0];
   reg [63:0]           time_last[NUM_MACS-1:0];

   reg [15:0]           pkt_len;

   reg [NUM_MACS-1:0]   first_pkt;
   wire [NUM_MACS-1:0]  want_reset;
   reg [NUM_MACS-1:0]   enable_d1;

   reg                  process_pkt;
   reg                  process_pkt_nxt;
   reg                  capture_pkt;
   reg                  in_pkt;
   reg                  in_pkt_nxt;
   reg                  drop_pkt;
   reg                  drop_pkt_nxt;

   wire [DATA_WIDTH-1:0] fifo_out_data;
   wire [CTRL_WIDTH-1:0] fifo_out_ctrl;
   reg  [CTRL_WIDTH-1:0] fifo_out_ctrl_d1;

   reg [CTRL_WIDTH-1:0] out_ctrl_nxt;
   reg [DATA_WIDTH-1:0] out_data_nxt;
   reg                  out_wr_nxt;

   reg                  in_fifo_rd_en;

   integer              i;

   //----------------------- Modules ---------------------------------
   fallthrough_small_fifo #(.WIDTH(CTRL_WIDTH+DATA_WIDTH), .MAX_DEPTH_BITS(2), .PROG_FULL_THRESHOLD(3))
      input_fifo
        (.din           ({in_ctrl, in_data}),  // Data in
         .wr_en         (in_wr),             // Write enable
         .rd_en         (in_fifo_rd_en),    // Read the next word
         .dout          ({fifo_out_ctrl, fifo_out_data}),
         .full          (),
         .nearly_full   (in_fifo_nearly_full),
         .empty         (in_fifo_empty),
         .reset         (reset),
         .clk           (clk)
         );

   //----------------------- Logic ---------------------------------

   assign in_rdy = !in_fifo_nearly_full;
   assign want_reset = ~enable_d1 & enable;

   /* pkt is from the cpu if it comes in on an odd numbered port */
   assign pkt_is_from_cpu = in_data[`IOQ_SRC_PORT_POS];

   /* Decode the source port */
   always @(*) begin
      one_hot_src = 0;
      one_hot_src[fifo_out_data[`IOQ_SRC_PORT_POS+15:`IOQ_SRC_PORT_POS]] = 1'b1;
      src = fifo_out_data[`IOQ_SRC_PORT_POS+NUM_MACS_WIDTH:`IOQ_SRC_PORT_POS+1];
   end
   assign enable_mapped = {
      8'b0,
      1'b0, enable[3],
      1'b0, enable[2],
      1'b0, enable[1],
      1'b0, enable[0]
      };

   assign drop_mapped = {
      8'b0,
      1'b0, drop[3] & enable[3],
      1'b0, drop[2] & enable[2],
      1'b0, drop[1] & enable[1],
      1'b0, drop[0] & enable[0]
      };

   // Track location and modify packet
   always @* begin
      state_nxt = state;
      in_pkt_nxt = in_pkt;
      drop_pkt_nxt = drop_pkt;
      process_pkt_nxt = process_pkt;
      src_held_nxt = src_held;

      out_ctrl_nxt = fifo_out_ctrl;
      out_data_nxt = fifo_out_data;
      out_wr_nxt = 1'b0;

      in_fifo_rd_en = 1'b0;

      if(reset) begin
         state_nxt = IN_MODULE_HDRS;
         in_pkt_nxt = 1'b0;
         drop_pkt_nxt = 1'b0;

         process_pkt_nxt = 1'b0;
         src_held_nxt = 'h0;
      end
      else begin
         case (state)
            IN_MODULE_HDRS: begin
               if (!in_fifo_empty && out_rdy) begin
                  // By default we want to write out the words that come in
                  in_fifo_rd_en = 1'b1;
                  out_wr_nxt = 1;

                  // Record that we've started processing a packet
                  in_pkt_nxt = 1'b1;

                  // Work out how to modify the data
                  if (fifo_out_ctrl == IO_QUEUE_STAGE_NUM) begin
                     process_pkt_nxt = |(enable_mapped & one_hot_src);
                     if ( |(drop_mapped & one_hot_src) ) begin
                        state_nxt = DROP_HDR;
                        drop_pkt_nxt = 1'b1;
                        out_wr_nxt = 0;
                     end
                     src_held_nxt = src;

                     // Update the length if we're keeping the timestamp header
                     if (enable_mapped & one_hot_src) begin
                        out_data_nxt[`IOQ_BYTE_LEN_POS+15:`IOQ_BYTE_LEN_POS] = fifo_out_data[`IOQ_BYTE_LEN_POS+15:`IOQ_BYTE_LEN_POS] + 'd24;
                        out_data_nxt[`IOQ_WORD_LEN_POS+15:`IOQ_WORD_LEN_POS] = fifo_out_data[`IOQ_WORD_LEN_POS+15:`IOQ_WORD_LEN_POS] + 'd3;
                     end
                  end
                  else if (fifo_out_ctrl == TIMESTAMP_CTRL) begin
                     // Work out if we're adding the timestamp in which case
                     // we need to add a DA/SA and ethertype
                     if (process_pkt) begin
                        state_nxt = ADD_PKT_HDR;
                        out_data_nxt = {DA, SA[47:32]};
                        out_ctrl_nxt = 'h0;

                        // Don't pull out any more words -- we need to write
                        // the timestamp into the packet
                        in_fifo_rd_en = 1'b0;
                     end
                     else begin
                        // Drop the timestamp
                        out_wr_nxt = 'h0;
                     end
                  end
                  else if (fifo_out_ctrl == 0) begin
                     state_nxt = IN_PACKET;
                  end
               end
            end // case: IN_MODULE_HDRS

            ADD_PKT_HDR: begin
               if (out_rdy) begin
                  state_nxt = ADD_TIMESTAMP;
                  out_data_nxt = {SA[31:0], ETHERTYPE, 16'h0};
                  out_ctrl_nxt = 'h0;
                  out_wr_nxt = 'h1;
               end
            end

            ADD_TIMESTAMP: begin
               // Note: assumption is that the timestamp header is the last
               // one in the packet
               if (!in_fifo_empty && out_rdy) begin
                  state_nxt = IN_PACKET;

                  in_fifo_rd_en = 1'b1;

                  out_ctrl_nxt = 'h0;
                  out_wr_nxt = 1'b1;
               end
            end

            IN_PACKET: begin
               if (!in_fifo_empty && (out_rdy || drop_pkt)) begin
                  in_fifo_rd_en = 1'b1;
                  out_wr_nxt = ~drop_pkt;

                  if (fifo_out_ctrl != 0) begin
                     state_nxt = IN_MODULE_HDRS;
                     in_pkt_nxt = 1'b0;
                     process_pkt_nxt = 1'b0;
                     drop_pkt_nxt = 1'b0;
                  end
               end
            end

            DROP_HDR: begin
               // Note: assumption is that the timestamp header is the last
               // one in the packet
               if (!in_fifo_empty) begin
                  if (fifo_out_ctrl == 0)
                     state_nxt = IN_PACKET;

                  in_fifo_rd_en = 1'b1;

                  out_wr_nxt = 1'b0;
               end
            end
         endcase // case(state)
      end
   end // always @ (*)

   always @(posedge clk) begin
      state       <= state_nxt;
      in_pkt      <= in_pkt_nxt;
      drop_pkt    <= drop_pkt_nxt;
      process_pkt <= process_pkt_nxt;
      src_held    <= src_held_nxt;

      out_ctrl    <= out_ctrl_nxt;
      out_data    <= out_data_nxt;
      out_wr      <= out_wr_nxt;
   end

   // Counter/timer management
   always @(posedge clk) begin
      if(reset) begin
         for (i = 0; i < NUM_MACS; i = i + 1) begin
            pkt_cnt[i] <= 32'h0;
            byte_cnt[i] <= 40'h0;
            time_first[i] <= 64'h0;
            time_last[i] <= 64'h0;

            first_pkt[i] <= 1'b1;

            capture_pkt <= 1'b0;
         end

         fifo_out_ctrl_d1 <= 'h0;
         state_d1 <= 'h0;
      end
      else begin
         // Update the registers
         if (|want_reset) begin
            for (i = 0; i < NUM_MACS; i = i + 1) begin
               if (want_reset[i]) begin
                  pkt_cnt[i] <= 32'h0;
                  byte_cnt[i] <= 40'h0;
                  time_first[i] <= 64'h0;
                  time_last[i] <= 64'h0;

                  first_pkt[i] <= 1'b1;

                  capture_pkt <= 1'b0;
               end
            end
         end
         else begin
            if (in_fifo_rd_en) begin
               fifo_out_ctrl_d1 <= fifo_out_ctrl;
               state_d1 <= state;

               // Handle packet length/packet count registers
               if (fifo_out_ctrl == IO_QUEUE_STAGE_NUM && state != IN_PACKET) begin
                  if (enable_mapped & one_hot_src) begin
                     capture_pkt <= 1'b1;
                     pkt_cnt[src] <= pkt_cnt[src] + 'h1;

                     // Add 4 to the byte count for the FCS
                     pkt_len <= fifo_out_data[`IOQ_BYTE_LEN_POS+15:`IOQ_BYTE_LEN_POS] + 'h4;
                  end
               end
               else if (capture_pkt &&
                        fifo_out_ctrl_d1 == IO_QUEUE_STAGE_NUM &&
                        state_d1 != IN_PACKET) begin
                  byte_cnt[src_held] <= byte_cnt[src_held] + pkt_len;
               end

               if (capture_pkt &&
                   fifo_out_ctrl == TIMESTAMP_CTRL &&
                   state != IN_PACKET) begin
                  if (first_pkt[src_held]) begin
                     time_first[src_held] <= fifo_out_data;
                  end
                  time_last[src_held] <= fifo_out_data;
                  first_pkt[src_held] <= 1'b0;
               end
               else if (capture_pkt &&
                        fifo_out_ctrl_d1 == TIMESTAMP_CTRL &&
                        state_d1 != IN_PACKET) begin
                  time_last[src_held] <= time_last[src_held] + (pkt_len * 8);
               end
            end
         end
      end
   end // always @ (*)

   always @(posedge clk)
   begin
      enable_d1 <= enable;
   end

   // Map the counters/timers arrays to the output signals
   assign pkt_cnt_0 = pkt_cnt[0];
   assign byte_cnt_0 = byte_cnt[0];
   assign time_first_0 = time_first[0];
   assign time_last_0 = time_last[0];

   assign pkt_cnt_1 = pkt_cnt[1];
   assign byte_cnt_1 = byte_cnt[1];
   assign time_first_1 = time_first[1];
   assign time_last_1 = time_last[1];

   assign pkt_cnt_2 = pkt_cnt[2];
   assign byte_cnt_2 = byte_cnt[2];
   assign time_first_2 = time_first[2];
   assign time_last_2 = time_last[2];

   assign pkt_cnt_3 = pkt_cnt[3];
   assign byte_cnt_3 = byte_cnt[3];
   assign time_first_3 = time_first[3];
   assign time_last_3 = time_last[3];

endmodule
