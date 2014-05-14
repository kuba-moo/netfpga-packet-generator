
`timescale 1ns/1ps

module stamp_counter_regs
  #(parameter COUNTER_WIDTH = 96,
    parameter COUNTER_FRACTION = 1/3,
    parameter NUM_QUEUES=8)

   ( input                                    counter_reg_req,
     input                                    counter_reg_rd_wr_L,
     input  [`COUNTER_REG_ADDR_WIDTH-1:0]     counter_reg_addr,
     input  [`CPCI_NF2_DATA_WIDTH-1:0]        counter_reg_wr_data,

     output reg [`CPCI_NF2_DATA_WIDTH-1:0]    counter_reg_rd_data,
     output reg                               counter_reg_ack,

     // interface to the counter reg
     output                                   enable_inc_int,
     output                                   enable_inc_frac,
     output [63:0]                            inc_value_int,
     output [63:0]                            inc_value_frac,
     input  [95:0]                            counter_val,
     input  [NUM_QUEUES/2-1:0]                valid_rx,
     input  [NUM_QUEUES/2-1:0]                valid_tx,


     input                                    clk,
     input                                    reset);

    function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   // -------- Internal parameters --------------

   localparam NUM_REGS_USED         = 36; /* don't forget to update this when adding regs */
   localparam REG_FILE_ADDR_WIDTH   = log2(NUM_REGS_USED)+1;

   // ------------- Wires/reg ------------------

   wire [REG_FILE_ADDR_WIDTH-1:0]      addr;

   wire                                addr_good;

   wire                                new_reg_req;
   reg                                 reg_req_d1;
   reg [`CPCI_NF2_DATA_WIDTH-1:0]      reg_rd_data_nxt;

   reg [`CPCI_NF2_DATA_WIDTH-1:0]      reg_file [0:NUM_REGS_USED-1];


   integer                             i;
   wire                                counter_read_enable;
   wire                                enable_mask_rx;
   wire                                enable_mask_tx;
   wire [NUM_QUEUES/2-1:0] 	       mask_rx;
   wire [NUM_QUEUES/2-1:0] 	       mask_tx;

   reg [3:0] 			       temp_valid_rx;
   reg [3:0] 			       temp_valid_tx;


   reg [3:0] 			       valid_rx_sync;
   reg [3:0] 			       valid_tx_sync;

   // ---------- Logic ----------

   assign addr = counter_reg_addr[REG_FILE_ADDR_WIDTH-1:0];
   assign addr_good = counter_reg_addr[`COUNTER_REG_ADDR_WIDTH-1:REG_FILE_ADDR_WIDTH] == 'h0 &&
      addr < NUM_REGS_USED;

   assign new_reg_req = counter_reg_req && !reg_req_d1;


   // Handle register requests
   always @(posedge clk) begin


      reg_req_d1 <= counter_reg_req;

      if( reset ) begin
         counter_reg_rd_data  <= 0;
         counter_reg_ack      <= 0;

	 for(i=0; i<NUM_REGS_USED; i=i+1) begin
            reg_file[i] <= 0;
	 end
      end

      else begin
         // Register access logic
         if(new_reg_req) begin // read request
            if(addr_good) begin
               counter_reg_rd_data <=  reg_file[addr];
	       if (!counter_reg_rd_wr_L)
                 reg_file[addr] <= counter_reg_wr_data;
	    end
	    else begin
               counter_reg_rd_data <= 32'hdead_beef;
            end

	    counter_reg_ack <= 1;

         end // if (new_reg_req)
	 // update the reg_file
	 if(counter_read_enable) begin
	    reg_file[`COUNTER_BIT_95_64] <= counter_val[95:64];
	    reg_file[`COUNTER_BIT_63_32] <= counter_val[63:32];
	    reg_file[`COUNTER_BIT_31_0]  <= counter_val[31:0];
	 end

	 if(valid_rx_sync[0]==1'b1) begin
	    reg_file[`COUNTER_CLK_SYN_0_RX_HI] <= counter_val[95:64];
	    reg_file[`COUNTER_CLK_SYN_0_RX_LO] <= counter_val[63:32];
	 end
	 if(valid_rx_sync[1]==1'b1) begin
	    reg_file[`COUNTER_CLK_SYN_1_RX_HI] <= counter_val[95:64];
	    reg_file[`COUNTER_CLK_SYN_1_RX_LO] <= counter_val[63:32];
	 end
	 if(valid_rx_sync[2]==1'b1) begin
	    reg_file[`COUNTER_CLK_SYN_2_RX_HI] <= counter_val[95:64];
	    reg_file[`COUNTER_CLK_SYN_2_RX_LO] <= counter_val[63:32];
	 end
	 if(valid_rx_sync[3]==1'b1) begin
	    reg_file[`COUNTER_CLK_SYN_3_RX_HI] <= counter_val[95:64];
	    reg_file[`COUNTER_CLK_SYN_3_RX_LO] <= counter_val[63:32];
	 end
	 if(valid_tx_sync[0]==1'b1) begin
	    reg_file[`COUNTER_CLK_SYN_0_TX_HI] <= counter_val[95:64];
	    reg_file[`COUNTER_CLK_SYN_0_TX_LO] <= counter_val[63:32];
	 end
	 if(valid_tx_sync[1]==1'b1) begin
	    reg_file[`COUNTER_CLK_SYN_1_TX_HI] <= counter_val[95:64];
	    reg_file[`COUNTER_CLK_SYN_1_TX_LO] <= counter_val[63:32];
	 end
	 if(valid_tx_sync[2]==1'b1) begin
	    reg_file[`COUNTER_CLK_SYN_2_TX_HI] <= counter_val[95:64];
	    reg_file[`COUNTER_CLK_SYN_2_TX_LO] <= counter_val[63:32];
	 end
	 if(valid_tx_sync[3]==1'b1) begin
	    reg_file[`COUNTER_CLK_SYN_3_TX_HI] <= counter_val[95:64];
	    reg_file[`COUNTER_CLK_SYN_3_TX_LO] <= counter_val[63:32];
	 end

	 reg_file[`COUNTER_PTP_VALID_RX] <= {28'b0, temp_valid_rx};
	 reg_file[`COUNTER_PTP_VALID_TX] <= {28'b0, temp_valid_tx};



         // requests complete after one cycle
         counter_reg_ack <= new_reg_req;
      end // else: !if( reset )
   end // always @ (posedge clk)


   always @(enable_mask_rx or mask_rx or valid_rx_sync)
     begin
	for (i=0; i<4; i=i+1)
	  begin
	     if (valid_rx_sync[i])
	       temp_valid_rx[i] <= 1'b1;
	     else if (enable_mask_rx)
	       temp_valid_rx[i] <= reg_file[`COUNTER_PTP_VALID_RX][i] & mask_rx[i];
	     else
	       temp_valid_rx[i] <= reg_file[`COUNTER_PTP_VALID_RX][i];
	  end
     end // always @ (enable_mask_rx or mask_rx or valid_rx_sync)


   always @(enable_mask_tx or mask_tx or valid_tx_sync)
     begin
	for (i=0; i<4; i=i+1)
	  begin
	     if (valid_tx_sync[i])
		temp_valid_tx[i] <= 1'b1;
	     else if (enable_mask_tx)
	       temp_valid_tx[i] <= reg_file[`COUNTER_PTP_VALID_TX][i] & mask_tx[i];
	     else
	       temp_valid_tx[i] <= reg_file[`COUNTER_PTP_VALID_TX][i];
	  end // for (i=0; i<4; i=i+1)
     end // always @ (enable_mask_tx or mask_tx or valid_tx_sync)



   generate
      genvar g;
      for( g=0; g<4; g=g+1) begin :valid_sync
	 always@(posedge clk or posedge valid_rx[g])
	   if (valid_rx[g])
	     valid_rx_sync[g] <= 1'b1;
	   else
	     valid_rx_sync[g] <= 1'b0;

     always@(posedge clk or posedge valid_tx[g])
     if (valid_tx[g])
       valid_tx_sync[g] <= 1'b1;
     else
       valid_tx_sync[g] <= 1'b0;
    end
   endgenerate



   // get data from registers

   assign inc_value_int = {reg_file[`COUNTER_1], reg_file[`COUNTER_2]};
   assign inc_value_frac = {reg_file[`COUNTER_3], reg_file[`COUNTER_4]};

   assign enable_inc_int  =  reg_file[`COUNTER_1_2_LOAD][0];
   assign enable_inc_frac =  reg_file[`COUNTER_3_4_LOAD][0];

   assign counter_read_enable = reg_file[`COUNTER_READ_ENABLE][0];

   assign enable_mask_rx   = reg_file[`COUNTER_PTP_ENABLE_MASK_RX][0];
   assign enable_mask_tx   = reg_file[`COUNTER_PTP_ENABLE_MASK_TX][0];

   assign mask_rx = reg_file[`COUNTER_PTP_MASK_RX][NUM_QUEUES/2-1:0];
   assign mask_tx = reg_file[`COUNTER_PTP_MASK_TX][NUM_QUEUES/2-1:0];






endmodule // cpu_dma_queue_regs

