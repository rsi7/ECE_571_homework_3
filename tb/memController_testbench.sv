// Module: memController_testbench.sv
// Author: Rehan Iqbal
// Date: February 10, 2017
// Company: Portland State University
//
// Description:
// ------------
// Testbench program for the memController module. It has several tasks which
// make it easy to modularize the testbench functionality:
//
// 1) PktGen - generates packets to communicate to memory
// controller. Packet consists of a base address, transaction type
// (READ or WRITE), and four 16-bit values. In the case of a write packet,
// these will random values. In the case of a read, they are zeros.
// Function updates the global copy of the packet array.
//
// 2) MemCycle - starts of by sending an AddrValid signal, read/write signal,
// and initial address to the memory controller. Depending on packet type
// (READ or WRITE) it will either push packet data onto AddrData or read from
// AddrData into the packet. Function updates the global copy of the packet array.
//
// 3) WriteToMem - Sets up the write test. Goes through each element of the
// packet array and calls PktGen to generate the necessary data. Then calls
// MemCycle to send the appropriate bus signals.
//
// 4) ReadFromMem - Sets up the read test. Goes through each element of the
// packet array and calls PktGen to generate the necessary data. Then calls
// MemCycle to send the appropriate bus signals.
//
///////////////////////////////////////////////////////////////////////////////

`include "definitions.sv"

program memController_testbench	(

	/************************************************************************/
	/* Top-level port declarations											*/
	/************************************************************************/

	inout	tri		[15:0]	AddrData,			// Multiplexed AddrData bus. On a write
												// operation the address, followed by 4
												// data items are driven onto AddrData by
												// the CPU (your testbench).
												// On a read operation, the CPU will
												// drive the address onto AddrData and tristate
												// its AddrData drivers. Your memory controller
												// will drive the data from the memory onto
												// the AddrData bus.

	input	ulogic1		clk,					// clock to the memory controller and memory
	input	ulogic1		resetH,					// Asserted high to reset the memory controller

	output	ulogic1		AddrValid = 1'b0,		// Asserted high to indicate that there is
												// valid address on AddrData. Kicks off
												// new memory read or write cycle.

	output	ulogic1		rw = 1'b0				// Asserted high for read, low for write
												// valid during cycle where AddrValid asserts
	);

	/************************************************************************/
	/* Local parameters and variables										*/
	/************************************************************************/

	memPkt_t	wr_pkt_array[];			// global array of write-to-memory packets
	memPkt_t	rd_pkt_array[];			// global array of read-from-memomry packets

	ulogic16	pktAddrData;			// register value to hold AddrData values

	/************************************************************************/
	/* Wire assignments														*/
	/************************************************************************/

	// AddrData is tri-state (wire), so need continous assignment

	assign SendDataToTB = ((DUT1.rdEn) || (DUT2.rdEn)) && !AddrValid;
	assign AddrData = SendDataToTB ? 16'bz : pktAddrData;
	
	/************************************************************************/
	/* Task : PktGen														*/
	/************************************************************************/

	task automatic PktGen (input pktType_t pktType, ref memPkt_t pkt);
	
		ulogic4 random_page = $urandom_range(4'h2, 4'h1);
		ulogic8 random_addr = $urandom_range(8'd255, 8'd0);

		pkt.Type = pktType;

		if (pktType == WRITE) begin
			pkt.Address = {random_page, 4'b0, random_addr};
		end

		 foreach (pkt.Data[i]) begin

		 	if (pkt.Type == WRITE) begin
		 		pkt.Data[i] = $urandom_range(16'd65535, 16'd0);
		 	end

		 	else begin
		 		pkt.Data[i] = 16'd0;
		 	end

		 end

	endtask

	/************************************************************************/
	/* Task : MemCycle														*/
	/************************************************************************/

	task automatic MemCycle (ref memPkt_t pkt);

		@(posedge clk)

		// send signals for cycle  A of the transaction
		// AddrValid for 1 cycle
		AddrValid = 1'b1;
		rw = pkt.Type;

		// put packet address on the AddrData bus
		// through pktAddrData register

		pktAddrData = pkt.Address;

		// for each element in packet data length
		// (four elements by default)
		// maniuplate global AddrData signal

		foreach (pkt.Data[i]) begin

			@(posedge clk)
			AddrValid = 1'b0;
			rw = 1'b0;

			if (pkt.Type == READ) begin
				pkt.Data[i] = AddrData;
			end

			else begin
				pktAddrData = pkt.Data[i];
			end
		end

	endtask

	/************************************************************************/
	/* Task : WriteToMem													*/
	/************************************************************************/

	task WriteToMem ();

		int	fhandle_wr;

		// format time units for printing later
		// also setup the output file location

		$timeformat(-9, 0, "ns", 8);
		fhandle_wr = $fopen("C:/Users/riqbal/Desktop/memController_wr_results.txt");

		// print header at top of write log
		$fwrite(fhandle_wr,"Hardware Write Results:\n\n");

		foreach (wr_pkt_array[i]) begin

			// generate packets & send the bus signals
			PktGen(WRITE, wr_pkt_array[i]);
			MemCycle(wr_pkt_array[i]);

			// print signal values to log file
			$fstrobe(fhandle_wr,	"Time:%t\t\t", $time,
									"Packet #: %2d\t\t", i,
									"Base Address: %6d\n\n", wr_pkt_array[i].Address,
									
									"Data[0]: %6d\t\n", wr_pkt_array[i].Data[0],
									"Data[1]: %6d\t\n", wr_pkt_array[i].Data[1],
									"Data[2]: %6d\t\n", wr_pkt_array[i].Data[2],
									"Data[3]: %6d\t\n", wr_pkt_array[i].Data[3]);
		end

		// wrap up file writing
		$fwrite(fhandle_wr, "\nEND OF FILE");
		$fclose(fhandle_wr);

	endtask

	/************************************************************************/
	/* Task : ReadFromMem													*/
	/************************************************************************/

	task ReadFromMem ();

		int	fhandle_rd;

		// copy the write-packet array to read-packet array
		// this lets us reuse the Address - we'll wipe their Data

		rd_pkt_array = wr_pkt_array;

		// format time units for printing later
		// also setup the output file location

		$timeformat(-9, 0, "ns", 8);
		fhandle_rd = $fopen("C:/Users/riqbal/Desktop/memController_rd_results.txt");

		// print header at top of read log
		$fwrite(fhandle_rd,"Hardware Read Results:\n\n");

		foreach (rd_pkt_array[i]) begin

			// generate packets & send the bus signals
			PktGen(READ, rd_pkt_array[i]);
			MemCycle(rd_pkt_array[i]);

			// print signal values to log file
			$fstrobe(fhandle_rd, 	"Time:%t\t\t", $time,
									"Packet #: %2d\t\t", i,
									"Base Address: %6d\n\n", rd_pkt_array[i].Address,
						
									"Data[0]: %6d\t\n", rd_pkt_array[i].Data[0],
									"Data[1]: %6d\t\n", rd_pkt_array[i].Data[1],
									"Data[2]: %6d\t\n", rd_pkt_array[i].Data[2],
									"Data[3]: %6d\t\n", rd_pkt_array[i].Data[3]);
		end

		// wrap up file writing
		$fwrite(fhandle_rd, "\nEND OF FILE");
		$fclose(fhandle_rd);

	endtask

	/************************************************************************/
	/* Main simulation loop													*/
	/************************************************************************/

	initial begin

		static uint32 sim_trials = 16;

		// dynamically allocate more entries
		wr_pkt_array = new[sim_trials];
		rd_pkt_array = new[sim_trials];

		// call the write & read tests
		WriteToMem();
		ReadFromMem();

		$stop;

	end

endprogram