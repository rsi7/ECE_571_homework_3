// Module: memController_top.sv
// Author: Rehan Iqbal
// Date: February 10, 2017
// Company: Portland State University
//
// Description:
// ------------
// Top-level module which instantiates the DUT & testbench. It also handles
// the initial reset, starts the clock ticking, and sets the time units.
// 
///////////////////////////////////////////////////////////////////////////////

`include "definitions.sv"

module memController_top;

	timeunit 1ns;
	timeprecision 100ps;

	/************************************************************************/
	/* Local parameters and variables										*/
	/************************************************************************/

	tri	[15:0]	AddrData;			// Multiplexed AddrData bus. On a write
									// operation the address, followed by 4
									// data items are driven onto AddrData by
									// the CPU (your testbench).
									// On a read operation, the CPU will
									// drive the address onto AddrData and tristate
									// its AddrData drivers. Your memory controller
									// will drive the data from the memory onto
									// the AddrData bus. 

	ulogic1		clk;				// clock to the memory controller and memory
	ulogic1 	resetH;				// Asserted high to reset the memory controller
	
	ulogic1 	AddrValid;			// Asserted high to indicate that there is
									// valid address on AddrData. Kicks off
									// new memory read or write cycle.

	ulogic1 	rw;					// Asserted high for read, low for write
									// valid during cycle where AddrValid asserts

	/************************************************************************/
	/* Instantiating the DUT & testbench									*/
	/************************************************************************/

	memController 				DUT		(.*);
	memController_testbench		tb		(.*);

	/************************************************************************/
	/* Handle simulation reset & clock ticking...							*/
	/************************************************************************/

	initial begin

		//	reset before clock starts ticking...
			resetH = 1'b0;
		#1 	resetH = 1'b1;
		#1 	resetH = 1'b0;

		// now start the clock for rest of simulation...

		clk = 1'b0;
		forever #0.5 clk <= !clk;
		
	end

endmodule