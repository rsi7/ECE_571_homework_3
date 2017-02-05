// Module: memController.sv
// Author: Rehan Iqbal
// Date: February 10, 2017
// Company: Portland State University
//
// Description:
// ------------
// Acts as a memory controller for the 'mem' module. On the first clock cycle,
// it receives the address, address valid signal, and a read/write signal.
// In the four consecutive cycles after, it proceeds to either read bits from
// the memory and output them on 'data', or write the bits on 'data' into 
// memory. The next transaction begins on the following cycle.
//
///////////////////////////////////////////////////////////////////////////////

`include "definitions.pkg"

module memController (

	/*************************************************************************/
	/* Top-level port declarations											 */
	/*************************************************************************/

	inout	tri		[15:0]	AddrData,	// Multiplexed AddrData bus. On a write
										// operation the address, followed by 4
										// data items are driven onto AddrData by
										// the CPU (your testbench).
										// On a read operation, the CPU will
										// drive the address onto AddrData and tristate
										// its AddrData drivers. Your memory controller
										// will drive the data from the memory onto
										// the AddrData bus.

	input	ulogic1			clk,		// clock to the memory controller and memory
	input	ulogic1			resetH,		// Asserted high to reset the memory controller

	input	ulogic1			AddrValid,	// Asserted high to indicate that there is
										// valid address on AddrData. Kicks off
										// new memory read or write cycle.

	input	ulogic1			rw			// Asserted high for read, low for write
										// valid during cycle where AddrValid asserts
	);

	/*************************************************************************/
	/* Local parameters and variables										 */
	/*************************************************************************/

	state_t		state	=	ADDR;		// register to hold current FSM state
	state_t		next	=	ADDR;		// register to hold pending FSM state

	/*************************************************************************/
	/* FSM Block 1: reset & state advancement								 */
	/*************************************************************************/

	always_ff@(posedge clk or posedge reset) begin

		// reset the FSM to idle state
		if (reset) begin
			state <= IDLE;
		end

		// otherwise, advance the state
		else begin
			state <= next;
		end

	end

	/*************************************************************************/
	/* FSM Block 2: state transistions										 */
	/*************************************************************************/

	always_comb@(posedge clk or posedge reset) begin

		unique case (state)

			// check if start was asserted
			// if so, FSM is receiving data
			// otherwise, keep idle

			IDLE : begin
				if (start) next = RECEIVING;
				else next = IDLE;
			end

			// check if start was de-asserted
			// if so, move to DONE state
			// otherwise, still receiving data

			RECEIVING : begin
				if (!start) next = DONE;
				else next = RECEIVING;
			end

			// final results only last 1 cycle
			DONE : next = IDLE;

			default : next = BAD_STATE;

		endcase
	end

	/*************************************************************************/
	/* FSM Block 3: assigning outputs										 */
	/*************************************************************************/

	always_comb@(posedge clk or posedge reset) begin

		// if reset was asserted, clear the outputs
		if (reset) begin
			maxValue	= '0;
			minValue	= '1;
			done		= '0;
		end

		else begin

			unique case(next)

				// check if starting to receive data
				// if so, update maxValue & minValue

				IDLE : begin

					if (start) begin
						maxValue = inputA;
						minValue = inputA;
					end

					else begin
						maxValue = '0;
						minValue = '1;
					end

					done = '0;
				end

				// compare current maxValue against new data input
				// update if needed - retain previous value otherwise

				RECEIVING : begin

					if (inputA > maxValue) begin
						maxValue = inputA;
					end

					else if (inputA < minValue) begin
						minValue = inputA;
					end

					else begin
						maxValue = maxValue;
						minValue = minValue;
					end

					done = '0;
				end

				// set done flag high to indicate processing finished
				DONE : begin
					maxValue = maxValue;
					minValue = minValue;
					done = '1;
				end

				// set outputs to unknown if case statement fails
				default : begin
					maxValue = 'x;
					minValue = 'x;
					done = 'x;
				end

			endcase	
		end
	end

endmodule