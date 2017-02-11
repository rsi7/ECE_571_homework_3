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
// 1) PktGen - generates & returns packets to communicate to memory
// controller. Packet consists of a base address, transaction type
// (READ or WRITE), and four 16-bit values. In the case of a write packet,
// these will random values. In the case of a read, they are zeros.
//
// 2) MemCycle - starts of by sending an AddrValid signal, read/write signal,
// and initial address to the memory controller. Depending on packet type
// (READ or WRITE) it will either push packet data onto AddrData or read from
// AddrData into the packet.
// 
// While these tasks run to send stimulus to the DUT and verify function in
// software, the testbench uses $fwrite and $fmonitor to write hardware results
// to another text file. This can be compared against the algorithmic log
// to verify functionality is as intended.
//
///////////////////////////////////////////////////////////////////////////////

`include "definitions.sv"
`timescale 1ns / 100ps


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

	int			trials = 10;				// number of packets to send

	int 		fhandle_hw;					// integer to hold file location

	memPkt_t	pkt_array[10];				// array to hold all the packets

	ulogic16	pktAddrData;

	/************************************************************************/
	/* Wire assignments														*/
	/************************************************************************/

	assign AddrData = ((DUT.rdEn) && (!AddrValid)) ? 16'bz : pktAddrData;
	
	/************************************************************************/
	/* Task : PktGen														*/
	/************************************************************************/

	task PktGen (input pktType_t pktType, output memPkt_t pkt);
	
		pkt.Type = pktType;

		pkt.Address = $urandom_range(16'd65535, 16'd0);

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

	task MemCycle (input memPkt_t pkt);

		AddrValid = 1'b1;
		rw = pkt.Type;
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
	/* Main simulation loop													*/
	/************************************************************************/

	initial begin

		// format time units for printing later
		// also setup the output file location

		$timeformat(-9, 0, "ns", 8);
		fhandle_hw = $fopen("C:/Users/riqbal/Desktop/memController_hw_results.txt");

		// print header at top of hardware log
		$fwrite(fhandle_hw,"Hardware Results\n\n");

		@(posedge clk)

		for (int i = 0; i < trials; i++) begin

			PktGen(WRITE, pkt_array[i]);
			MemCycle(pkt_array[i]);

			$fstrobe(fhandle_hw,	"Time:%t\t\t", $time,
									"Packet #: %2d\t\t", i,
									"Access Type: %s\t\t", pkt_array[i].Type.name,
									"Base Address: %6x\t\t", pkt_array[i].Address);
		end

		// wrap up file writing & finish simulation
		$fwrite(fhandle_hw, "\nEND OF FILE");
		$fclose(fhandle_hw);
		$stop;

	end

endprogram