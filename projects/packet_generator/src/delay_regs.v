///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: delay_regs.v 5803 2009-08-04 21:23:10Z g9coving $
//
// Module: delay_regs.v
// Project: delay module
// Description: Registers for the delay module
//
///////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module delay_regs
  #(
      parameter UDP_REG_SRC_WIDTH = 2,
      parameter DELAY_BLOCK_TAG = `DELAY_BLOCK_ADDR
   )
   (
      input                                  reg_req_in,
      input                                  reg_ack_in,
      input                                  reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]       reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]      reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]         reg_src_in,

      output reg                             reg_req_out,
      output reg                             reg_ack_out,
      output reg                             reg_rd_wr_L_out,
      output reg [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_out,
      output reg [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_out,
      output reg [UDP_REG_SRC_WIDTH-1:0]     reg_src_out,


      output reg                             delay_reset,

      input                                  clk,
      input                                  reset
   );

   `LOG2_FUNC

   // ------------- Internal parameters --------------
   parameter NUM_REGS_USED = 2; /* don't forget to update this when adding regs */
   parameter ADDR_WIDTH = log2(NUM_REGS_USED);

   // ------------- Wires/reg ------------------

   wire [ADDR_WIDTH-1:0]                              addr;
   wire [`DELAY_REG_ADDR_WIDTH - 1:0]                 reg_addr;
   wire [`UDP_REG_ADDR_WIDTH-`DELAY_REG_ADDR_WIDTH - 1:0] tag_addr;

   wire                                               addr_good;
   wire                                               tag_hit;

   // -------------- Logic --------------------

   assign addr = reg_addr_in[ADDR_WIDTH-1:0];
   assign reg_addr = reg_addr_in[`DELAY_REG_ADDR_WIDTH-1:0];
   assign tag_addr = reg_addr_in[`UDP_REG_ADDR_WIDTH - 1:`DELAY_REG_ADDR_WIDTH];

   assign addr_good = (reg_addr<NUM_REGS_USED);
   assign tag_hit = tag_addr == DELAY_BLOCK_TAG;

   always @(posedge clk) begin
      // Never modify the address/src
      reg_rd_wr_L_out <= reg_rd_wr_L_in;
      reg_addr_out <= reg_addr_in;
      reg_src_out <= reg_src_in;

      if( reset ) begin
         reg_req_out                   <= 1'b0;
         reg_ack_out                   <= 1'b0;
         reg_data_out                  <= 'h0;

         delay_reset                   <= 1'b0;
      end
      else begin
         if(reg_req_in && tag_hit) begin
            if(addr_good) begin

               if (!reg_rd_wr_L_in && addr == `DELAY_RESET)
                  delay_reset <= reg_data_in;
               else
                  delay_reset <= 1'b0;

               if (reg_rd_wr_L_in)
                  reg_data_out <= addr == `DELAY_RESET ? 32'h0 : 32'hdead_beef;
               else
                  reg_data_out <= reg_data_in;
            end
            else begin
               reg_data_out <= reg_rd_wr_L_in ? 32'hdead_beef : reg_data_in;
               delay_reset <= 1'b0;
            end

            // requests complete after one cycle
            reg_ack_out <= 1'b1;
         end
         else begin
            reg_ack_out <= reg_ack_in;
            reg_data_out <= reg_data_in;
            delay_reset <= 1'b0;
         end
         reg_req_out <= reg_req_in;
      end // else: !if( reset )
   end // always @ (posedge clk)

endmodule // delay_regs
