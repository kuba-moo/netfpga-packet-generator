///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: delay.v 5878 2010-01-01 02:09:12Z grg $
//
// Module: delay.v
// Project: delay
// Description: delays any pkts coming through by a programmable delay
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
`include "udp_defines.v"

module delay
  #(parameter DATA_WIDTH = 64,
    parameter CTRL_WIDTH = DATA_WIDTH/8,
    parameter UDP_REG_SRC_WIDTH = 2,
    parameter STAGE_NUM = `DELAY_CTRL_VAL,
    parameter COUNTER_WIDTH = 96,
    parameter COUNTER_FRACTION = 32
   )
   (output reg [DATA_WIDTH-1:0]        out_data,
    output reg [CTRL_WIDTH-1:0]        out_ctrl,
    output reg                         out_wr,
    input                              out_rdy,

    input  [DATA_WIDTH-1:0]            in_data,
    input  [CTRL_WIDTH-1:0]            in_ctrl,
    input                              in_wr,
    output                             in_rdy,

    // --- Register interface

    input                              reg_req_in,
    input                              reg_ack_in,
    input                              reg_rd_wr_L_in,
    input  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_in,
    input  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_in,
    input  [UDP_REG_SRC_WIDTH-1:0]     reg_src_in,

    output                             reg_req_out,
    output                             reg_ack_out,
    output                             reg_rd_wr_L_out,
    output  [`UDP_REG_ADDR_WIDTH-1:0]  reg_addr_out,
    output  [`CPCI_NF2_DATA_WIDTH-1:0] reg_data_out,
    output  [UDP_REG_SRC_WIDTH-1:0]    reg_src_out,

    // --- PTP counter
    input [COUNTER_WIDTH-1:COUNTER_FRACTION] counter_val,

    // --- Misc
    input                              clk,
    input                              reset);



   //----------------------- local parameter ---------------------------
   parameter OUT_WAIT_FOR_PKT = 0;
   parameter OUT_CHECK_TIMESTAMP = 1;
   parameter OUT_WAIT_EOP = 2;


   //----------------------- wires/regs---------------------------------
   wire [CTRL_WIDTH-1:0]               delay_fifo_out_ctrl;
   wire [DATA_WIDTH-1:0]               delay_fifo_out_data;

   wire [63:0]                         curr_time;
   reg [63:0]                          curr_time_d1;
   reg [63:0]                          curr_time_d2;

   reg [39:0]                          remaining_delay;
   reg                                 reset_remaining_delay;

   reg [39:0]                          want_delay;
   reg [39:0]                          want_delay_next;

   reg [39:0]                          last_delay;
   reg [39:0]                          last_start_d1;
   reg [39:0]                          last_start_d2;

   reg                                 start_data;

   reg                                 delay_good;
   reg [39:0]                          delay_d1;
   reg [39:0]                          delay_d2;

   reg                                 seen_delay;
   reg                                 seen_delay_next;


   reg [1:0]                           out_state_next, out_state;
   reg                                 out_wr_next;
   reg                                 delay_fifo_rd_en;

   reg                                 delay_fifo_ctrl_prev_is_0;

   reg                                 data_good;

   wire                                delay_reset;

   //------------------------ Modules ----------------------------------
   syncfifo_1024x72 delay_fifo
     (  .clk(clk),
        .din({in_ctrl, in_data}),
        .rd_en(delay_fifo_rd_en),
        .rst(reset),
        .wr_en(in_wr),
        .dout({delay_fifo_out_ctrl, delay_fifo_out_data}),
        .empty(delay_fifo_empty),
        .almost_full(delay_fifo_almost_full),
        .full(delay_fifo_full));


   //----------------------- delay logic -----------------------
   assign in_rdy = !delay_fifo_almost_full;
   assign curr_time = counter_val;

   /*
    * Outgoing state machine: Wait for a timestamp
    * then check if the time has been reached
    */
   assign out_eop = delay_fifo_ctrl_prev_is_0 && (delay_fifo_out_ctrl!=0);
   always @(*) begin
      out_state_next         = out_state;
      out_wr_next            = 0;
      delay_fifo_rd_en       = 0;
      want_delay_next        = want_delay;
      seen_delay_next        = seen_delay;
      start_data             = 0;

      case(out_state)
         OUT_WAIT_FOR_PKT: begin
            if (!delay_fifo_empty) begin
               delay_fifo_rd_en = 1;
               out_state_next   = OUT_CHECK_TIMESTAMP;
               seen_delay_next  = 0;
            end
         end // case: OUT_WAIT_FOR_PKT

         OUT_CHECK_TIMESTAMP: begin
            if (data_good) begin
               // Attempt to identify the next delay value
               if (delay_reset) begin
                  want_delay_next = 'h0;
                  seen_delay_next = 0;
               end
               else if (delay_fifo_out_ctrl == STAGE_NUM) begin
                  want_delay_next = want_delay + delay_fifo_out_data;
                  seen_delay_next = 1;
               end

               // Look for the beginning of the packet and only transit
               // to wait eop state when the current delay is expired
               // or when there is no delay recorded for the current packet
               if (delay_fifo_out_ctrl == 'h0 && (delay_good || !seen_delay)) begin
                  out_state_next   = OUT_WAIT_EOP;
                  start_data = 1;
               end

               // Sent output to next stage when in the header or
               // when the curr_delay flag has expired
               if (delay_fifo_out_ctrl == 'h0 && (delay_good || !seen_delay) ||
                   delay_fifo_out_ctrl != 'h0) begin
                  delay_fifo_rd_en = out_rdy && !delay_fifo_empty;
                  out_wr_next      = out_rdy;
               end
            end
            else begin
               delay_fifo_rd_en = !delay_fifo_empty;
            end
         end

         OUT_WAIT_EOP: begin
            out_wr_next = out_rdy & data_good;
            delay_fifo_rd_en = out_rdy && !delay_fifo_empty;

            if (data_good && out_rdy) begin
               if (out_eop) begin
                  if (delay_fifo_rd_en) begin
                     out_state_next = OUT_CHECK_TIMESTAMP;
                  end
                  else begin
                     out_state_next = OUT_WAIT_FOR_PKT;
                  end

                  // If the packet we're processing had a delay then update the
                  // wanted delay (account for small deltas due to clock sync
                  // and PTP)
                  if (seen_delay)
                     want_delay_next = remaining_delay;
                  else
                     want_delay_next = 0;

                  seen_delay_next  = 0;
               end
            end
         end // case: OUT_WAIT_EOP

      endcase // case(out_state)
   end // always @ (*)

   always @(posedge clk) begin
      if(reset) begin
         delay_fifo_ctrl_prev_is_0    <= 0;
         out_state                    <= OUT_WAIT_FOR_PKT;
         out_data                     <= 0;
         out_ctrl                     <= 0;
         out_wr                       <= 0;
         want_delay                   <= 'h0;
         last_delay                   <= 'h0;
         last_start_d1                <= 'h8;
         last_start_d2                <= 'h0;
         seen_delay                   <= 0;
         data_good                    <= 0;
      end
      else begin
         out_wr            <= out_wr_next;
         out_data          <= delay_fifo_out_data;
         out_ctrl          <= delay_fifo_out_ctrl;
         out_state         <= out_state_next;

         if(out_wr_next) begin
            delay_fifo_ctrl_prev_is_0 <= (delay_fifo_out_ctrl==0);
         end

         want_delay        <= want_delay_next;
         seen_delay        <= seen_delay_next;
         data_good         <= delay_fifo_rd_en || (data_good && !out_wr_next);

         if (start_data) begin
            last_start_d1 <= curr_time_d1;
            last_start_d2 <= curr_time_d2;
            last_delay    <= delay_d1;
         end
      end // else: !if(reset)

      // Delayed version of the current time
      curr_time_d1                    <= counter_val;
      curr_time_d2                    <= curr_time_d1;
   end


   // Calculation of the delay values
   always @(posedge clk) begin
      if (reset || start_data) begin
         delay_d1 <= 8;
         delay_d2 <= 16;
         delay_good <= want_delay < 16 || want_delay[39];
      end
      else begin
         delay_d1 <= curr_time - last_start_d1;
         delay_d2 <= curr_time - last_start_d2;
         if (!seen_delay)
            delay_good <= 0;
         else
            delay_good <= want_delay <= delay_d2 || want_delay[39] || delay_d2[39];
      end
   end // always @ (posedge clk)


   // Logic to calculate the remaining delay after a packet is sent
   always @(posedge clk) begin
      reset_remaining_delay <= last_delay[39:8] > want_delay[39:8];
      remaining_delay <= reset_remaining_delay ? 'h0 : want_delay - last_delay;
   end


   // --- Registers ---
delay_regs
  #(
      .UDP_REG_SRC_WIDTH (UDP_REG_SRC_WIDTH)
   ) delay_regs (
      .reg_req_in                            (reg_req_in),
      .reg_ack_in                            (reg_ack_in),
      .reg_rd_wr_L_in                        (reg_rd_wr_L_in),
      .reg_addr_in                           (reg_addr_in),
      .reg_data_in                           (reg_data_in),
      .reg_src_in                            (reg_src_in),

      .reg_req_out                           (reg_req_out),
      .reg_ack_out                           (reg_ack_out),
      .reg_rd_wr_L_out                       (reg_rd_wr_L_out),
      .reg_addr_out                          (reg_addr_out),
      .reg_data_out                          (reg_data_out),
      .reg_src_out                           (reg_src_out),


      .delay_reset                           (delay_reset),

      .clk                                   (clk),
      .reset                                 (reset)
   );

endmodule // delay
