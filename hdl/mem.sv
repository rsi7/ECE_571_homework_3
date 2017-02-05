//////////////////////////////////////////////////////////////
// mem.sv - Memory simulator for ECE 571 HW #3
//
// Author:	Roy Kravitz 
// Date:	01-Feb-2017
//
// Description:
// ------------
// Implements a simple synchronous Read/Write memory system.  The model is parameterized
// to adjust the width and depth of the memory array
// 
// Note:  Original code created by Don T.
////////////////////////////////////////////////////////////////
module mem
#(	
	parameter DATAWIDTH = 16,
	parameter MEMDEPTH = 256,
	parameter ADDRWIDTH = $clog2(MEMDEPTH)
)
(
	input	logic						clk,	// clock (this is a synchronous memory)
	input	logic						rdEn,	// Asserted high to read the memory
	input	logic						wrEn,	// Asserted high to write the memory
	input	logic	[ADDRWIDTH-1:0]		Addr,	// Address to read or write
	inout	tri		[DATAWIDTH-1:0]		Data	// Data to (write) and from (read) the
												// memory.  Tristate (z) when rdEn is
												// is deasserted (low)
);

// declare internal variables
logic	[DATAWIDTH-1:0]		M[MEMDEPTH];		// memory array
logic	[DATAWIDTH-1:0]		out;				// read data from memory

// clear the memory
initial begin
	foreach (M[i]) begin
		M[i] = 0;
	end
end // clear the memory

// implement the tristate data bus
assign Data = (rdEn) ? out : 'bz;

// continously read Data[Addr]
// this is OK because we drive the actual Data bus with a tristate buffer
always_comb begin	
	out = M[Addr];
end

// write a location in memory
always @(posedge clk) begin
	if (wrEn) begin
		M[Addr] <= Data;
	end
end // write a location in memory

endmodule
