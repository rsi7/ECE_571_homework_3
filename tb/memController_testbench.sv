// Module: memController_testbench.sv
// Author: Rehan Iqbal
// Date: February 10, 2017
// Company: Portland State University
//
// Description:
// ------------
// lorem ipsum
// 
///////////////////////////////////////////////////////////////////////////////

`include "definitions.pkg"

module memController_testbench;

	timeunit 1ns;
	timeprecision 100ps;

	/*************************************************************************/
	/* Local parameters and variables										 */
	/*************************************************************************/

	inout	tri		[15:0]	AddrData_tb;	// Multiplexed AddrData bus. On a write
											// operation the address, followed by 4
											// data items are driven onto AddrData by
											// the CPU (your testbench).
											// On a read operation, the CPU will
											// drive the address onto AddrData and tristate
											// its AddrData drivers. Your memory controller
											// will drive the data from the memory onto
											// the AddrData bus. 

	ulogic1		clk_tb;						// clock to the memory controller and memory
	ulogic1 	resetH_tb;					// Asserted high to reset the memory controller
	
	ulogic1 	AddrValid_tb;				// Asserted high to indicate that there is
											// valid address on AddrData. Kicks off
											// new memory read or write cycle.

	ulogic1 	rw_tb;						// Asserted high for read, low for write
											// valid during cycle where AddrValid asserts

	int 		fhandle;					// integer to hold file location

	/*************************************************************************/
	/* Instantiating the DUT												 */
	/*************************************************************************/

	memController DUT (

		.AddrData		(AddrData_tb),		// T [15:0] Bidirectional address/data bus
		.clk			(clk_tb),			// I [0:0] clock to the memory controller
		.resetH			(resetH_tb),		// I [0:0] Active-high reset signal
		.AddrValid		(AddrValid_tb),		// I [0:0] Active-high valid signal
		.rw				(rw_tb)				// I [0:0] Active-high: read. Active-low: write

		);

	/*************************************************************************/
	/* Running the testbench simluation										 */
	/*************************************************************************/

	// keep the clock ticking
	always begin
		#0.5 clk_tb <= !clk_tb;
	end

	// main simulation loop

	initial begin

		// format time units for printing later
		// also setup the output file location

		$timeformat(-9, 0, "ns", 8);
		fhandle = $fopen("C:/Users/riqbal/Desktop/findMax_results.txt");

		// toggle the resets to start the FSM
		#5 reset_tb = '1;
		#5 reset_tb = '0;

		// run the simulation for some number of sequences
		for (int j = 1; j <= trials; j++) begin

			// choose how many bytes to send this sequence
			bytes = $urandom_range(16,1);
			$fwrite(fhandle,"\nSending %d number of bytes to module...\n", bytes);

			// loop the number of bytes in one sequence
			for (int i = 1; i <= bytes; i++) begin

				// send a byte between 0 - 255 on inputA
				#1 inputA_tb = $urandom_range(8'd255,8'b0);
				start_tb = '1;
				$fstrobe(fhandle,"Time:%t\t\tinputA: %d\t\tmaxValue: %d\t\tminValue: %d\t\t", $time, inputA_tb, maxValue_tb, minValue_tb);
			end

			// finish sequence by deasserting start
			#1 start_tb = '0;
			$fstrobe(fhandle,"Time:%t\t\t\t\t\t\tmaxValue: %d\t\tminValue: %d\t\t", $time, maxValue_tb, minValue_tb);
			#5;
		end

		// wrap up file writing & finish simulation
		$fwrite(fhandle, "\nEND OF FILE");
		$fclose(fhandle);
		$stop;

	end

endmodule