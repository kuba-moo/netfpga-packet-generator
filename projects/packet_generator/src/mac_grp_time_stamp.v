///////////////////////////////////////////////////////////////////////////////
// vim:set shiftwidth=3 softtabstop=3 expandtab:
// $Id: mac_grp_time_stamp.v 3684 2008-05-05 06:55:10Z grg $
//
// Module: mac_grp_time_stamp.v
// Project: NetFPGA Rev 2.1
// Description: Module that performs time stamping on received packets
//
///////////////////////////////////////////////////////////////////////////////

  module mac_grp_time_stamp
    #(parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH=DATA_WIDTH/8,
      parameter ENABLE_HEADER = 0,
      parameter STAGE_NUMBER = 'hff,
      parameter PORT_NUMBER = 0,
      parameter COUNTER_WIDTH = 32
      )


   (// RX packet
    input [7:0]                      data,
    input                            enable,

    input [COUNTER_WIDTH-1:0]        counter_val,


    // output time stamps
    output reg [31:0]                Time_HI,
    output reg [31:0]                Time_LO,
    output reg                       valid,


    // misc
    input                            reset,
    input                            clk
    );


   reg 				     valid_ptp;
   reg [6:0] 			     byte_counter;
   reg [7:0] 			     eth_lo, eth_hi;
   reg [15:0] 			     eth_type;
   reg [3:0] 			     first_byte_header;

   localparam eth_loc = 23;



   always @(posedge clk)
     begin
	if (reset) begin
	   Time_HI <= 0;
	   Time_LO <= 0;
	   valid <= 0;
	end
	else begin
	   if (valid_ptp) begin
	      Time_HI <= counter_val[63:32];
	      Time_LO <= counter_val[31:0];
	      valid <= 1;
	   end
	   else
	     begin
		Time_HI <= 0;
		Time_LO <= 0;
		valid <= 0;
	     end
	end // else: !if(reset)
     end // always


   always @(posedge clk)
     begin
	if (reset || !enable)
	  byte_counter <= 0;
	else if(enable && byte_counter < eth_loc)
	  byte_counter <= byte_counter + 1;
	else
	  byte_counter <= byte_counter;


     end

    always @(posedge clk)
      begin

	  if (byte_counter == eth_loc-3)
	    eth_lo <= data;
	  else
	    eth_lo <= eth_lo;

	  if (byte_counter == eth_loc-2)
	    eth_hi <= data;
	  else
	    eth_hi <= eth_hi;

	  if (byte_counter == eth_loc-1)
	    begin
	       first_byte_header <= data;
	       eth_type <= {eth_lo, eth_hi};
	    end

	  if (byte_counter == eth_loc)
	    begin
	    if (eth_type == 'h88F7)
	      begin
		 if(first_byte_header[3:0] < 4)
		   valid_ptp = 1;
		 else
		   valid_ptp = 0;
	      end
	    else
	      valid_ptp = 0;
	       first_byte_header <= 0;
	       eth_type <= 0;
	    end
	  else
	    valid_ptp = 0;



       end // always @ (*)




endmodule // mac_grp_time_stamp
