/*
 * This component applies the AES sbox to each of the 16 bytes of the AES state
 * This implements the AES SubBytes operation
 */

module subbytes(clk, rst, ena, state_in, state_out, done);
	
input clk;
input rst;
input ena;
input [127:0] state_in;
output reg [127:0] state_out;
output reg done;

// Temporary state storage
reg [127:0] temp_state;

// Instantiate the S-Box module using a generate statement
genvar i;
wire [7:0] sbox_out [15:0];
generate
	for (i = 0; i < 16; i = i + 1) begin : sbox_gen
		sbox sbox_instance (
			.byte_in(state_in[(127 - i * 8) -: 8]),
			.byte_out(sbox_out[i])
		);
	end
endgenerate

// Perform SubBytes in one clock cycle
always @(posedge clk) begin
	if (rst) begin
		state_out <= 128'b0;
		done <= 1'b0;
	end else  begin
		temp_state = {
			sbox_out[0],  sbox_out[1],  sbox_out[2],  sbox_out[3],
			sbox_out[4],  sbox_out[5],  sbox_out[6],  sbox_out[7],
			sbox_out[8],  sbox_out[9],  sbox_out[10], sbox_out[11],
			sbox_out[12], sbox_out[13], sbox_out[14], sbox_out[15]
		};
		if (ena) begin
		state_out <= temp_state;	
		done <= 1'b1;
		end else begin
			done <= 1'b0;
		end
end
end
endmodule
