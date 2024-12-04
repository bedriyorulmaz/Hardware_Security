/*
 * This component implements the AES MixColumns operation by applying the mixcolumn component on each 32bit column of the state matrix
 * Be careful how rows and columns are stored in the state!
 */

/*module mixcolumns(clk, rst, ena, state_in, state_out, done);
	
	input clk;
	input rst;
	input ena;
	input [127:0] state_in;
	output reg [127:0] state_out;
	output reg done;

	reg [127:0] temp_state;


    // Intermediate wires for xtime and multiplication by 3 for each byte in the state
    wire [7:0] xtime_s0, xtime_s1, xtime_s2, xtime_s3;
    wire [7:0] xtime_s4, xtime_s5, xtime_s6, xtime_s7;
    wire [7:0] xtime_s8, xtime_s9, xtime_s10, xtime_s11;
    wire [7:0] xtime_s12, xtime_s13, xtime_s14, xtime_s15;

    wire [7:0] mul3_s0, mul3_s1, mul3_s2, mul3_s3;
    wire [7:0] mul3_s4, mul3_s5, mul3_s6, mul3_s7;
    wire [7:0] mul3_s8, mul3_s9, mul3_s10, mul3_s11;
    wire [7:0] mul3_s12, mul3_s13, mul3_s14, mul3_s15;

     // Instantiate xtime modules for multiplication by 2 for each byte in state_in, using the same order specified in temp_state copying
    xtime xtime_inst0 (.byte_in(state_in[7:0]), .byte_out(xtime_s0));
    xtime xtime_inst1 (.byte_in(state_in[15:8]), .byte_out(xtime_s1));
    xtime xtime_inst2 (.byte_in(state_in[23:16]), .byte_out(xtime_s2));
    xtime xtime_inst3 (.byte_in(state_in[31:24]), .byte_out(xtime_s3));

    xtime xtime_inst4 (.byte_in(state_in[39:32]), .byte_out(xtime_s4));
    xtime xtime_inst5 (.byte_in(state_in[47:40]), .byte_out(xtime_s5));
    xtime xtime_inst6 (.byte_in(state_in[55:48]), .byte_out(xtime_s6));
    xtime xtime_inst7 (.byte_in(state_in[63:56]), .byte_out(xtime_s7));

    xtime xtime_inst8 (.byte_in(state_in[71:64]), .byte_out(xtime_s8));
    xtime xtime_inst9 (.byte_in(state_in[79:72]), .byte_out(xtime_s9));
    xtime xtime_inst10 (.byte_in(state_in[87:80]), .byte_out(xtime_s10));
    xtime xtime_inst11 (.byte_in(state_in[95:88]), .byte_out(xtime_s11));

    xtime xtime_inst12 (.byte_in(state_in[103:96]), .byte_out(xtime_s12));
    xtime xtime_inst13 (.byte_in(state_in[111:104]), .byte_out(xtime_s13));
    xtime xtime_inst14 (.byte_in(state_in[119:112]), .byte_out(xtime_s14));
    xtime xtime_inst15 (.byte_in(state_in[127:120]), .byte_out(xtime_s15));

    // Calculate multiplication by 3 in GF(2^8) as xtime(b) ^ b using state_in directly
    assign mul3_s0 = xtime_s0 ^ state_in[7:0];
    assign mul3_s1 = xtime_s1 ^ state_in[15:8];
    assign mul3_s2 = xtime_s2 ^ state_in[23:16];
    assign mul3_s3 = xtime_s3 ^ state_in[31:24];

    assign mul3_s4 = xtime_s4 ^ state_in[39:32];
    assign mul3_s5 = xtime_s5 ^ state_in[47:40];
    assign mul3_s6 = xtime_s6 ^ state_in[55:48];
    assign mul3_s7 = xtime_s7 ^ state_in[63:56];

    assign mul3_s8 = xtime_s8 ^ state_in[71:64];
    assign mul3_s9 = xtime_s9 ^ state_in[79:72];
    assign mul3_s10 = xtime_s10 ^ state_in[87:80];
    assign mul3_s11 = xtime_s11 ^ state_in[95:88];

    assign mul3_s12 = xtime_s12 ^ state_in[103:96];
    assign mul3_s13 = xtime_s13 ^ state_in[111:104];
    assign mul3_s14 = xtime_s14 ^ state_in[119:112];
    assign mul3_s15 = xtime_s15 ^ state_in[127:120];
    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
            state_out <= 128'b0;
			temp_state <= 128'b0;

        end else if (ena) begin
            // Apply MixColumns transformation directly on state_in and assign to state_out

            // Column 0
            temp_state[7:0]      <= xtime_s0 ^ mul3_s1 ^ state_in[23:16] ^ state_in[31:24];  // s'0,0
            temp_state[15:8]     <= state_in[7:0] ^ xtime_s1 ^ mul3_s2 ^ state_in[31:24];    // s'1,0
            temp_state[23:16]    <= state_in[7:0] ^ state_in[15:8] ^ xtime_s2 ^ mul3_s3;     // s'2,0
            temp_state[31:24]    <= mul3_s0 ^ state_in[15:8] ^ state_in[23:16] ^ xtime_s3;   // s'3,0

            // Column 1
            temp_state[39:32]    <= xtime_s4 ^ mul3_s5 ^ state_in[55:48] ^ state_in[63:56];  // s'0,1
            temp_state[47:40]    <= state_in[39:32] ^ xtime_s5 ^ mul3_s6 ^ state_in[63:56];  // s'1,1
            temp_state[55:48]    <= state_in[39:32] ^ state_in[47:40] ^ xtime_s6 ^ mul3_s7;  // s'2,1
            temp_state[63:56]    <= mul3_s4 ^ state_in[47:40] ^ state_in[55:48] ^ xtime_s7;  // s'3,1

            // Column 2
            temp_state[71:64]    <= xtime_s8 ^ mul3_s9 ^ state_in[87:80] ^ state_in[95:88];  // s'0,2
            temp_state[79:72]    <= state_in[71:64] ^ xtime_s9 ^ mul3_s10 ^ state_in[95:88]; // s'1,2
            temp_state[87:80]    <= state_in[71:64] ^ state_in[79:72] ^ xtime_s10 ^ mul3_s11; // s'2,2
            temp_state[95:88]    <= mul3_s8 ^ state_in[79:72] ^ state_in[87:80] ^ xtime_s11;  // s'3,2

            // Column 3
            temp_state[103:96]   <= xtime_s12 ^ mul3_s13 ^ state_in[119:112] ^ state_in[127:120]; // s'0,3
            temp_state[111:104]  <= state_in[103:96] ^ xtime_s13 ^ mul3_s14 ^ state_in[127:120]; // s'1,3
            temp_state[119:112]  <= state_in[103:96] ^ state_in[111:104] ^ xtime_s14 ^ mul3_s15; // s'2,3
            temp_state[127:120]  <= mul3_s12 ^ state_in[111:104] ^ state_in[119:112] ^ xtime_s15; // s'3,3

            state_out <= temp_state;
            done <= 1;
        end else begin
            done <= 0;
        end
    end
endmodule*/

module mixcolumns(clk, rst, ena, state_in, state_out, done);
    input clk;
    input rst;
    input ena;
    input [127:0] state_in;
    output reg [127:0] state_out;
    output reg done;

    reg [127:0] temp_state;

    // State Encoding
    localparam IDLE = 2'b00, PROCESS = 2'b01, DONE = 2'b10;
    reg [1:0] state;

    // Intermediate wires for xtime and multiplication by 3 for each byte in the state
    wire [7:0] xtime_s [0:15];
    wire [7:0] mul3_s [0:15];

    genvar i;
    
    // Instantiate xtime modules for multiplication by 2 for each byte in state_in
    generate
        for (i = 0; i < 16; i = i + 1) begin : xtime_gen
            xtime xtime_inst (.byte_in(state_in[i*8 +: 8]), .byte_out(xtime_s[i]));
        end
    endgenerate

    // Calculate multiplication by 3 in GF(2^8) as xtime(b) ^ b using state_in directly
    generate
        for (i = 0; i < 16; i = i + 1) begin : mul3_gen
            assign mul3_s[i] = xtime_s[i] ^ state_in[i*8 +: 8];
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            state_out <= 128'b0;
            temp_state <= 128'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (ena) begin
                        state <= PROCESS;
                    end
                end

                PROCESS: begin
                    // Apply MixColumns transformation
                    // Column 0
                    temp_state[7:0]      <= xtime_s[0] ^ mul3_s[1] ^ state_in[23:16] ^ state_in[31:24];
                    temp_state[15:8]     <= state_in[7:0] ^ xtime_s[1] ^ mul3_s[2] ^ state_in[31:24];
                    temp_state[23:16]    <= state_in[7:0] ^ state_in[15:8] ^ xtime_s[2] ^ mul3_s[3];
                    temp_state[31:24]    <= mul3_s[0] ^ state_in[15:8] ^ state_in[23:16] ^ xtime_s[3];

                    // Column 1
                    temp_state[39:32]    <= xtime_s[4] ^ mul3_s[5] ^ state_in[55:48] ^ state_in[63:56];
                    temp_state[47:40]    <= state_in[39:32] ^ xtime_s[5] ^ mul3_s[6] ^ state_in[63:56];
                    temp_state[55:48]    <= state_in[39:32] ^ state_in[47:40] ^ xtime_s[6] ^ mul3_s[7];
                    temp_state[63:56]    <= mul3_s[4] ^ state_in[47:40] ^ state_in[55:48] ^ xtime_s[7];

                    // Column 2
                    temp_state[71:64]    <= xtime_s[8] ^ mul3_s[9] ^ state_in[87:80] ^ state_in[95:88];
                    temp_state[79:72]    <= state_in[71:64] ^ xtime_s[9] ^ mul3_s[10] ^ state_in[95:88];
                    temp_state[87:80]    <= state_in[71:64] ^ state_in[79:72] ^ xtime_s[10] ^ mul3_s[11];
                    temp_state[95:88]    <= mul3_s[8] ^ state_in[79:72] ^ state_in[87:80] ^ xtime_s[11];

                    // Column 3
                    temp_state[103:96]   <= xtime_s[12] ^ mul3_s[13] ^ state_in[119:112] ^ state_in[127:120];
                    temp_state[111:104]  <= state_in[103:96] ^ xtime_s[13] ^ mul3_s[14] ^ state_in[127:120];
                    temp_state[119:112]  <= state_in[103:96] ^ state_in[111:104] ^ xtime_s[14] ^ mul3_s[15];
                    temp_state[127:120]  <= mul3_s[12] ^ state_in[111:104] ^ state_in[119:112] ^ xtime_s[15];

                    state <= DONE;
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

