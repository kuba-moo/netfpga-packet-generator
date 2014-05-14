

/////////////////////////////////////////////////////////////////////////////
// Time stamp counter
// When enable is 1, initial_load is loaded into the counter
// at reset counter starts from zero
//
/////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ps
module stamp_counter #(
		       parameter COUNTER_WIDTH = 96,
		       parameter COUNTER_FRACTION = 32,
		       parameter NUM_QUEUES       = 8
		       )
   (
    //interface to the register
    input                                    counter_reg_req,
    input                                    counter_reg_rd_wr_L,
    input  [`COUNTER_REG_ADDR_WIDTH-1:0]     counter_reg_addr,
    input  [`CPCI_NF2_DATA_WIDTH-1:0]        counter_reg_wr_data,
    output [`CPCI_NF2_DATA_WIDTH-1:0]        counter_reg_rd_data,
    output                                   counter_reg_ack,

    //output 32 highest bit of the counter
    input   [NUM_QUEUES/2-1:0]                    valid_rx,
    input   [NUM_QUEUES/2-1:0]                    valid_tx,


    output  [COUNTER_WIDTH-1:COUNTER_FRACTION]    counter_val,


    input                                clk,
    input                                reset);



   /////////////////////////////////////////////////////////////////////////

   reg [COUNTER_WIDTH-1:0] 		                  temp;

   //Interface with the stamp_counter_regs

   //adds inc_value_int to the 64 highest bit of the counter when enable_inc is 1
   wire 				                  enable_inc_int;
   wire 				                  enable_inc_frac;
   wire [COUNTER_WIDTH-1-COUNTER_FRACTION:0] 		  inc_value_int;


   //adds inc_value_frac+8 to the 64 lowest bit of the counter in each clock cycle
   reg  [COUNTER_WIDTH-1-COUNTER_FRACTION:0]              inc_value_frac;
   wire [COUNTER_WIDTH-1-COUNTER_FRACTION:0] 		  temp_inc_value_frac;




   localparam FRACTION_NUM_BITS = COUNTER_WIDTH-COUNTER_FRACTION*2;



   always @(posedge clk) begin
      if(reset)
	temp <= 0;
      else if (enable_inc_int)
	temp <= temp + {inc_value_int , {FRACTION_NUM_BITS{1'b0}}};
      else
	temp <= temp + {{FRACTION_NUM_BITS{1'b0}}, inc_value_frac}+36'h800000000;
   end

   assign counter_val = temp[COUNTER_WIDTH-1:COUNTER_FRACTION];


   always @(posedge clk) begin
      if (reset)
	inc_value_frac <= 'h0;
      else if(enable_inc_frac)
	inc_value_frac <= temp_inc_value_frac;
      else
	inc_value_frac <= inc_value_frac;
   end



    stamp_counter_regs #(
		   .COUNTER_WIDTH (COUNTER_WIDTH),
		   .COUNTER_FRACTION (COUNTER_FRACTION),
		   .NUM_QUEUES (NUM_QUEUES)
		      ) stamp_counter_regs

   ( .counter_reg_req      (counter_reg_req),
     .counter_reg_rd_wr_L  (counter_reg_rd_wr_L),
     .counter_reg_addr     (counter_reg_addr),
     .counter_reg_wr_data  (counter_reg_wr_data),

     .counter_reg_rd_data  (counter_reg_rd_data),
     .counter_reg_ack      (counter_reg_ack),

     // interface to the counter reg
     .enable_inc_int           (enable_inc_int),
     .enable_inc_frac          (enable_inc_frac),
     .inc_value_int            (inc_value_int),
     .inc_value_frac           (temp_inc_value_frac),
     .counter_val              (temp),
     .valid_rx                 (valid_rx),
     .valid_tx                 (valid_tx),

     .clk                      (clk),
     .reset                    (reset)

);


endmodule // stamp_counter




