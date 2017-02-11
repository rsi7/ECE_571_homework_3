// Module: memController.sv
// Author: Rehan Iqbal
// Date: February 10, 2017
// Company: Portland State University
// Description:
// ------------
// Acts as a memory controller for the 'mem' module. On the first clock cycle,
// it receives the address, address valid signal, and a read/write signal.
// In the four consecutive cycles after, it proceeds to either read bits from
// the memory and output them on 'data', or write the bits on 'data' into 
// memory. The next transaction begins on the following cycle.
//
//////////////////////////////////////////////////////////////////////////////

`include "definitions.sv"

module memController (

	/************************************************************************/
	/* Top-level port declarations											*/
	/************************************************************************/

	inout	tri		[15:0]	AddrData,	// Multiplexed AddrData bus. On a write
										// operation the address, followed by 4
										// data items are driven onto AddrData by
										// the CPU (your testbench).
										// On a read operation, the CPU will
										// drive the address onto AddrData and tristate
										// its AddrData drivers. Your memory controller
										// will drive the data from the memory onto
										// the AddrData bus.

	input	ulogic1		clk,			// clock to the memory controller and memory
	input	ulogic1		resetH,			// Asserted high to reset the memory controller

	input	ulogic1		AddrValid,		// Asserted high to indicate that there is
										// valid address on AddrData. Kicks off
										// new memory read or write cycle.

	input	ulogic1		rw				// Asserted high for read, low for write
										// valid during cycle where AddrValid asserts
	);

	/************************************************************************/
	/* Local parameters and variables										*/
	/************************************************************************/

	state_t		state	= STATE_A;		// register to hold current FSM state
	state_t		next	= STATE_A;		// register to hold pending FSM state

	ulogic1		rdEn;					// Asserted high to read the memory
	ulogic1		wrEn;					// Asserted high to write the memory

	ulogic8		Addr;					// Address to read or write

	tri	[15:0]	Data;					// Data to (write) and from (read) the
										// memory.  Tristate (z) when rdEn is
										// is deasserted (low)

	/************************************************************************/
	/* Instantiate a memory device											*/
	/************************************************************************/
	
	mem		mem1	(.*);

	/************************************************************************/
	/* Wire assignments														*/
	/************************************************************************/

	assign Data 	= ((state != STATE_A) && (wrEn)) ? AddrData : 16'bz;
	assign AddrData	= (rdEn) ? Data : 16'bz;

	/************************************************************************/
	/* FSM Block 1: reset & state advancement								*/
	/************************************************************************/

	always_ff@(posedge clk or posedge resetH) begin

		// reset the FSM to waiting state
		if (resetH) begin
			state <= STATE_A;
		end

		// otherwise, advance the state
		else begin
			state <= next;
		end

	end

	/************************************************************************/
	/* FSM Block 2: state transistions										*/
	/************************************************************************/

	always_ff@(posedge clk) begin

		unique case (state)

			// each state lasts exactly 1 cycle,
			// except STATE_A, which holds until AddrValid

			STATE_A : begin
				if (AddrValid) next <= STATE_B;
				else next <= STATE_A;
			end

			STATE_B : next <= STATE_C;
			STATE_C : next <= STATE_D;
			STATE_D : next <= STATE_E;
			STATE_E : next <= STATE_A;

		endcase
	end

	/************************************************************************/
	/* FSM Commbinational: assigning outputs								*/
	/************************************************************************/

	always_comb begin

		unique case (state)

			// handle address input & determine R/W status
			STATE_A : begin

				rdEn = (rw) ? 1'b1 : 1'b0; 
				wrEn = (rw) ? 1'b0 : 1'b1;
				Addr = (AddrValid) ? (AddrData[7:0]) : '0;

			end

			// handles transactions on cycles 2 thru 5
			// rdEn & wrEn remain the same
			// increment the memory address
			// either deassert data line or push data onto it

			STATE_B, STATE_C, STATE_D, STATE_E : begin

				rdEn = rdEn; 
				wrEn = wrEn;
				Addr = Addr + 1;

			end
		endcase
	end

endmodule