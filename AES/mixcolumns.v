/*
 * This component implements the AES MixColumns operation by applying the mixcolumn component on each 32bit column of the state matrix
 * Be careful how rows and columns are stored in the state!
 */



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
            done <= 0;
            state_out <= 128'b0;
            temp_state <= 128'b0;
        end else begin
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
            if (ena) begin
            state_out <= temp_state;
            done <= 1'b1;
            end else begin
                done <= 0;
            end
    end
end
endmodule

