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

	parameter	PAGE 	= 4'h2;

	state_t		state	= STATE_A;		// register to hold current FSM state
	state_t		next	= STATE_A;		// register to hold pending FSM state

	ulogic1		rdEn;					// Asserted high to read the memory
	ulogic1		wrEn;					// Asserted high to write the memory

	ulogic8		Addr;					// Address to read or write

	tri	[15:0]	Data;					// Data to (write) and from (read) the
										// memory.  Tristate (z) when rdEn is
										// is deasserted (low)

	/************************************************************************/
	/* Local parameters and variables										*/
	/************************************************************************/

	ulogic16	AddrReg	= '0;			// Reg to hold Address for incrementing
	
	ulogic1		selectDevice;			// selects the current memory controller
	ulogic1		SendDataToMem;			// flag for sending data to memory
	ulogic1		SendDataToTB;			// flag for sending data to testbench
	ulogic1		rw_hold;				// register for holding R/W status during cycle

	/************************************************************************/
	/* Instantiate a memory device											*/
	/************************************************************************/
	
	mem		mem1	(.*);				// Instantiate a memory device

	/************************************************************************/
	/* Wire assignments														*/
	/************************************************************************/

	// Select the controller if address matches page
	// and address-input phase of cycles is over

	assign selectDevice = ((AddrReg[15:12] == PAGE) && !AddrValid) ? 1'b1 : 1'b0;

	// Data is tri-state (wire) so need continous assignnment
	// need to send data to mem when it's a write packet & AddrValid is low
	// otherwise, keep disconnected

	assign SendDataToMem = (wrEn && selectDevice);
	assign Data = SendDataToMem ? AddrData : 16'bz;
	
	// AddrData is tri-state (wire), so need continous assignment
	// need to send data to TB  when it's a READ packet & AddrValid is low
	// otherwise, keep disconnected

	assign SendDataToTB = (rdEn && selectDevice);
	assign AddrData = SendDataToTB ? Data : 16'bz;

	// use wire assigns on read/write enable signals to memory
	// to guarantee same-cycle activity

	assign rdEn = selectDevice && rw_hold;
	assign wrEn = selectDevice && !rw_hold;

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

	always_comb begin

		unique case (state)

			// each state lasts exactly 1 cycle,
			// except STATE_A, which holds until AddrValid

			STATE_A : begin
				if (AddrValid) next = STATE_B;
				else next = STATE_A;
			end

			STATE_B : next = STATE_C;
			STATE_C : next = STATE_D;
			STATE_D : next = STATE_E;
			STATE_E : next = STATE_A;

		endcase
	end

	/************************************************************************/
	/* FSM Block 3 & 4: assigning Addr & rw_hold							*/
	/************************************************************************/

	always_comb begin

		unique case (state)

			// handle address input & determine R/W status
			STATE_A : begin

				rw_hold = (rw) ? 1'b1 : 1'b0; 
				Addr = (AddrValid) ? (AddrData[7:0]) : '0;

			end

			// handles transactions on cycles 2 thru 5
			// rdEn & wrEn remain the same
			// increment the memory address
			// either deassert data line or push data onto it

			STATE_B, STATE_C, STATE_D, STATE_E : begin

				rw_hold = rw_hold; 
				Addr = AddrReg;

			end
		endcase
	end

	// block to hold address value for one cycle, then increment for 3 cycles
	// need for sequential memory accesses in both read & write

	always_ff@(posedge clk) begin

		unique case (state)

			STATE_A : AddrReg <= AddrData;
			STATE_B, STATE_C, STATE_D, STATE_E : AddrReg <= AddrReg + 1'b1;

		endcase

	end

endmodule