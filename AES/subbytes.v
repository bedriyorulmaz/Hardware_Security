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
	
	// TODO: Implement the SubBytes AES operation
	// ???
	


 // Instantiate the S-Box module
    wire [7:0] sbox_out;
    reg [7:0] sbox_in;

    sbox sbox_instance (
        .byte_in(sbox_in),
        .byte_out(sbox_out)
    );

	reg [3:0] byte_idx;
    reg [127:0] temp_state;
    reg [1:0] state;  // State machine states

    localparam IDLE = 2'b00,
               START = 2'b01,
               PROCESS = 2'b10,
               DONE = 2'b11;

	always @(posedge clk or posedge rst) begin
		if (rst) begin
			// Reset logic
			state_out <= 128'b0;
			done <= 1'b0;
			byte_idx <= 4'b0;
			temp_state <= 128'b0;
			state <= IDLE;
		end else begin
			case (state)
				IDLE: begin
					if (ena) begin
						temp_state <= state_in;
						byte_idx <= 4'b0;
						done <= 1'b0;
						state <= START;
					end
				end
				START: begin
					// Start processing
					sbox_in <= temp_state[(byte_idx * 8) +: 8]; // Extract byte to be substituted

					state <= PROCESS;
				end
				PROCESS: begin
					// Process each byte

                    // Wait one cycle for S-Box output, then update
                    temp_state[(byte_idx * 8) +: 8] <= sbox_out;  // Update substituted byte
                    
                    if (byte_idx < 4'b1111) begin
                        byte_idx <= byte_idx + 1;
						sbox_in <= temp_state[((byte_idx + 1) * 8) +: 8];  // Load next byte into S-box

                    end else begin
                        state <= DONE;
                    end
				end
                DONE: begin
					state_out <= temp_state;
					done <= 1'b1;
                    state <= IDLE;
                end

			endcase
		end
	end
		
		
endmodule


