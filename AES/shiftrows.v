/*
 * This components implements the AES ShiftRows operation
 * It represents a cyclic byte shift of the rows of the state matrix (see NIST.FIPS.197 for details)
 * Be careful with how columns/rows are stored in the state matrix!
 */

module shiftrows(clk, rst, ena, state_in, state_out, done);
	
	input clk;
	input rst;
	input ena;
	input [127:0] state_in;
	output [127:0] state_out;
	output done;

	reg done;
	reg [127:0] state_out;
	// Internal signal to hold intermediate state
	reg [127:0] temp_state;
	
	always @(posedge clk) begin
		if (rst) begin
			state_out = 128'b0;
	        temp_state= 128'b0;

			done = 1'b0;
		end else  begin
			// Perform the ShiftRows operation
			// state_in = {s0,0, s1,0, s2,0, s3,0, s0,1, s1,1, s2,1, s3,1, s0,2, s1,2, s2,2, s3,2, s0,3, s1,3, s2,3, s3,3}
			//
			// Row 0: No shift
			// Row 1: 1-byte left shift
			// Row 2: 2-byte left shift
			// Row 3: 3-byte left shift
			// Row 0 (no shift)


			// Row 0: No shift
			temp_state[7:0]     = state_in[7:0];      // s0,0
			temp_state[39:32]   = state_in[39:32];    // s0,1 
			temp_state[71:64]   = state_in[71:64];    // s0,2 
			temp_state[103:96]  = state_in[103:96];   // s0,3 
			
			// Row 1: 1-byte left shift
			temp_state[15:8]    = state_in[47:40];    // s1,0 
			temp_state[47:40]   = state_in[79:72];    // s1,1 
			temp_state[79:72]   = state_in[111:104];  // s1,2 
			temp_state[111:104] = state_in[15:8];     // s1,3 
			
			// Row 2: 2-byte left shift
			temp_state[23:16]   = state_in[87:80];    // s2,0 
			temp_state[55:48]   = state_in[119:112];  // s2,1 
			temp_state[87:80]   = state_in[23:16];    // s2,2 
			temp_state[119:112] = state_in[55:48];    // s2,3 
			
			// Row 3: 3-byte left shift
			temp_state[31:24]   = state_in[127:120];  // s3,0 
			temp_state[63:56]   = state_in[31:24];    // s3,1 
			temp_state[95:88]   = state_in[63:56];    // s3,2 
			temp_state[127:120] = state_in[95:88];    // s3,3 

			if (ena) begin
				state_out <= temp_state;
				done <= 1'b1;
			end else begin
				done <= 1'b0;
			end
	end
end
endmodule


