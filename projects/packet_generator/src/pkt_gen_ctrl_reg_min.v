///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: pkt_gen_ctrl_reg_min.v 5803 2009-08-04 21:23:10Z g9coving $
//
// Module: pkt_gen_ctrl_reg_min.v
// Project: Packet generator ctrl registers
// Description: Minimal implementation of the packet gen control registers
//              Does not do reads
//              Does not implement full set of registers
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module pkt_gen_ctrl_reg_min
   #(
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (// --- data path interface
    output reg [3:0]                      enable,

    // --- Register interface
    input                                 reg_req_in,
    input                                 reg_ack_in,
    input                                 reg_rd_wr_L_in,
    input  [`UDP_REG_ADDR_WIDTH-1:0]      reg_addr_in,
    input  [`CPCI_NF2_DATA_WIDTH-1:0]     reg_data_in,
    input  [UDP_REG_SRC_WIDTH-1:0]        reg_src_in,

    output reg                            reg_req_out,
    output reg                            reg_ack_out,
    output reg                            reg_rd_wr_L_out,
    output reg [`UDP_REG_ADDR_WIDTH-1:0]  reg_addr_out,
    output reg [`CPCI_NF2_DATA_WIDTH-1:0] reg_data_out,
    output reg [UDP_REG_SRC_WIDTH-1:0]    reg_src_out,

    // --- Misc
    input                                 clk,
    input                                 reset);

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
   localparam NUM_REGS_USED = 1;
   localparam ADDR_WIDTH = NUM_REGS_USED == 1 ? 1 : log2(NUM_REGS_USED);

   // ------------- Wires/reg ------------------

   wire [ADDR_WIDTH-1:0]                 addr;
   wire [`PKT_GEN_REG_ADDR_WIDTH - 1:0] reg_addr;
   wire [`UDP_REG_ADDR_WIDTH-`PKT_GEN_REG_ADDR_WIDTH - 1:0] tag_addr;

   wire                                  addr_good;
   wire                                  tag_hit;


   // -------------- Logic --------------------

   assign addr = reg_addr_in[ADDR_WIDTH-1:0];
   assign reg_addr = reg_addr_in[`PKT_GEN_REG_ADDR_WIDTH-1:0];
   assign tag_addr = reg_addr_in[`UDP_REG_ADDR_WIDTH - 1:`PKT_GEN_REG_ADDR_WIDTH];

   assign addr_good = reg_addr < NUM_REGS_USED;
   assign tag_hit = tag_addr == `PKT_GEN_BLOCK_ADDR;


   /* run the counters and mux between write and update */
   always @(posedge clk) begin
      if(reset) begin
         enable <= 'h0;

         reg_req_out                                    <= 0;
         reg_ack_out                                    <= 0;
         reg_rd_wr_L_out                                <= 0;
         reg_addr_out                                   <= 0;
         reg_data_out                                   <= 0;
         reg_src_out                                    <= 0;

      end // if (reset)
      else begin
         reg_req_out       <= reg_req_in;
         reg_ack_out       <= reg_ack_in;
         reg_rd_wr_L_out   <= reg_rd_wr_L_in;
         reg_addr_out      <= reg_addr_in;
         reg_data_out      <= reg_data_in;
         reg_src_out       <= reg_src_in;

         // Check if we see a request and the tags match (we need to
         // respond)
         if (reg_req_in && tag_hit) begin

            if (!reg_rd_wr_L_in) begin // write
               // Update the appropriate register
               case (addr)
                  `PKT_GEN_CTRL_ENABLE    : enable <= reg_data_in;
               endcase
            end
         end
      end // if else
   end // always @ (posedge clk)

endmodule
