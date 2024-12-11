/*
 * This entity computes a new AES round key using the current round (to get the round constant rcon) and 
 * the previous round key.
 * For the key schedule, operations are performed on 32bit words.
 * Details can be found in NIST.FIPS.197.
 */
// Improved keysched module - single clock cycle for each operation
 /*module keysched(clk, rst, ena, round_in, prev_key_in, next_key_out, done);
    
    input clk;
    input rst;
    input ena;
    input [3:0] round_in;
    input [127:0] prev_key_in;
    output reg [127:0] next_key_out;
    output reg done;

    // Internal Signals
    wire [31:0] rcon_out;
    reg [31:0] rot_word;
    reg [31:0] sub_word;
    reg [31:0] xor_word;
    reg [31:0] columns [0:3];
    reg [127:0] key_reg;
    reg [2:0] state; // Added additional bits for finer control
    parameter IDLE = 3'b000, PROCESS = 3'b001, SEND = 3'b010, DONE = 3'b011;
    integer i;

    // Instantiate the RCON module
    rcon rcon_inst(
        .round_in(round_in),
        .rcon_out(rcon_out)
    );

    // Instantiate the SBOX module
    wire [7:0] sbox_out [3:0];
	sbox sbox_inst0(.byte_in(prev_key_in[127:120]), .byte_out(sbox_out[2]));
    sbox sbox_inst1(.byte_in(prev_key_in[119:112]), .byte_out(sbox_out[1]));
    sbox sbox_inst2(.byte_in(prev_key_in[111:104]), .byte_out(sbox_out[0]));
    sbox sbox_inst3(.byte_in(prev_key_in[103:96]), .byte_out(sbox_out[3]));

    // Register for done signal control
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            key_reg <= 128'b0;
            next_key_out <= prev_key_in;
            rot_word <= 32'b0;
            sub_word <= 32'b0;
            xor_word <= 32'b0;
            for (i = 0; i < 4; i = i + 1)
                columns[i] <= 32'b0;
        end else begin
            case (state)

                IDLE: begin
					done <= 0;

                    if (ena) begin
                        // Separate the columns from the previous key
                        columns[0] <= prev_key_in[31:0];
                        columns[1] <= prev_key_in[63:32];
                        columns[2] <= prev_key_in[95:64];
                        columns[3] <= prev_key_in[127:96];
						sub_word <= {sbox_out[3], sbox_out[2], sbox_out[1], sbox_out[0]};

                        state <= PROCESS;
                    end
                end
                PROCESS: begin
                    // Rotate Word
                    // Substitute bytes using S-Box
                    // XOR with Rcon
                    xor_word <= sub_word ^ {rcon_out[7:0], 24'b0};
                    // Update column 0
                    columns[0] <= columns[0] ^ xor_word;
                    // Update other columns
                    for (i = 1; i < 4; i = i + 1)
                        columns[i] <= columns[i] ^ columns[i-1];
                    // Combine updated columns into key_reg
                    next_key_out <= {columns[3], columns[2], columns[1], columns[0]};
                    done <= 1;

                    state <= DONE;
                end

                DONE: begin
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule*/


module keysched(clk, rst, ena, round_in, prev_key_in, next_key_out, done);
    
    input clk;
    input rst;
    input ena;
    input [3:0] round_in;
    input [127:0] prev_key_in;
    output reg [127:0] next_key_out;
    output reg done;

    // Internal Signals
    wire [31:0] rcon_out;
    reg [31:0] rot_word;
    reg [31:0] sub_word;
    reg [31:0] xor_word;
    reg [31:0] column0;
    reg [31:0] column1;
    reg [31:0] column2;
    reg [31:0] column3;
	reg [31:0] next_column0;
    reg [31:0] next_column1;
    reg [31:0] next_column2;
    reg [31:0] next_column3;
    reg [127:0] key_reg;
    reg [2:0] state; // Added additional bits for finer control
    parameter IDLE = 3'b000, PROCESS = 3'b010, WAIT = 3'b001, DONE = 3'b100,SEND= 3'b011,UPDATE= 3'b111;
    integer i;

    // Instantiate the RCON module
    rcon rcon_inst(
        .round_in(round_in),
        .rcon_out(rcon_out)
    );
    assign column0={prev_key_in[7:0] ,prev_key_in[15:8] , prev_key_in[23:16] , prev_key_in[31:24]};
    assign column1={prev_key_in[39:32] ,prev_key_in[47:40] , prev_key_in[55:48] ,prev_key_in[63:56]};
    assign column2={prev_key_in[71:64] , prev_key_in[79:72] ,prev_key_in[87:80] ,prev_key_in[95:88]};
    assign column3={prev_key_in[103:96] ,prev_key_in[111:104] ,prev_key_in[119:112] ,prev_key_in[127:120]};


    // Instantiate the SBOX module
    wire [7:0] sbox_out [3:0];
	sbox sbox_inst0(.byte_in(prev_key_in[127:120]), .byte_out(sbox_out[2]));
    sbox sbox_inst1(.byte_in(prev_key_in[119:112]), .byte_out(sbox_out[1]));
    sbox sbox_inst2(.byte_in(prev_key_in[111:104]), .byte_out(sbox_out[0]));
    sbox sbox_inst3(.byte_in(prev_key_in[103:96]), .byte_out(sbox_out[3]));
    reg done_flag;
    // Register for done signal control
    always @(negedge clk) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
           // key_reg <= 128'b0;
            //next_key_out <= prev_key_in;
            rot_word <= 32'b0;
            sub_word <= 32'b0;
            xor_word <= 32'b0;
    
			next_column0 <= 32'b0;
            next_column1 <= 32'b0;
            next_column2 <= 32'b0;
            next_column3 <= 32'b0;
		end else  begin


                   // next_key_out = prev_key_in;

                    // Separate the columns from the previous key
                
                    sub_word = {sbox_out[0], sbox_out[1], sbox_out[2], sbox_out[3]};
                    
                

				
                    // Rotate Word
                    // Substitute bytes using S-Box
                    // XOR with Rcon
                    // Update column 0
                    //column0 <= column0 ^ xor_word;
                    // Update other columns



                  
			
             
                    // Combine updated columns into key_reg
                    //next_key_out = {column3, column2, column1, column0};
                   // next_key_out = key_reg;
                                
                    if (ena) begin
                        xor_word = sub_word ^ rcon_out ;

                        next_column0 = xor_word ^ column0;
                        next_column1 = next_column0 ^ column1;
                        next_column2 = next_column1 ^ column2;
                        next_column3 = next_column2 ^ column3;
                        next_key_out = {next_column3[7:0] ,next_column3[15:8] ,next_column3[23:16] ,next_column3[31:24],
                        next_column2[7:0]  ,next_column2[15:8] ,next_column2[23:16] ,next_column2[31:24] ,
                        next_column1[7:0]  ,next_column1[15:8] ,next_column1[23:16] ,next_column1[31:24] ,
                        next_column0[7:0]  ,next_column0[15:8] ,next_column0[23:16] ,next_column0[31:24]};
                        done= 1;
                    end else begin
                        done=0;
                    end
     



                
        end 
    end

endmodule

/*
module keysched(clk, rst, ena, round_in, prev_key_in, next_key_out, done);
    
    input clk;
    input rst;
    input ena;
    input [3:0] round_in;
    input [127:0] prev_key_in;
    output reg [127:0] next_key_out;
    output reg done;

    // Internal Signals
    wire [31:0] rcon_out;
    reg [31:0] rot_word;
    reg [31:0] sub_word;
    reg [31:0] xor_word;
    reg [31:0] column0;
    reg [31:0] column1;
    reg [31:0] column2;
    reg [31:0] column3;
    reg [31:0] next_column0;
    reg [31:0] next_column1;
    reg [31:0] next_column2;
    reg [31:0] next_column3;
    reg [127:0] key_reg;
    reg [2:0] state; // Added additional bits for finer control
    parameter IDLE = 3'b000, PROCESS = 3'b010, WAIT = 3'b001, DONE = 3'b100, SEND = 3'b011, UPDATE = 3'b111;
    integer i;

    // Instantiate the RCON module
    rcon rcon_inst(
        .round_in(round_in),
        .rcon_out(rcon_out)
    );

    // Assign columns directly from prev_key_in
    assign column0 = prev_key_in[127:96];
    assign column1 = prev_key_in[95:64];
    assign column2 = prev_key_in[63:32];
    assign column3 = prev_key_in[31:0];

    // Instantiate the SBOX module
    wire [7:0] sbox_out [3:0];
    sbox sbox_inst0(.byte_in(column3[31:24]), .byte_out(sbox_out[3]));
    sbox sbox_inst1(.byte_in(column3[23:16]), .byte_out(sbox_out[2]));
    sbox sbox_inst2(.byte_in(column3[15:8]), .byte_out(sbox_out[1]));
    sbox sbox_inst3(.byte_in(column3[7:0]), .byte_out(sbox_out[0]));

    // Register for done signal control
    always @(negedge clk) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            rot_word <= 32'b0;
            sub_word <= 32'b0;
            xor_word <= 32'b0;
            next_column0 <= 32'b0;
            next_column1 <= 32'b0;
            next_column2 <= 32'b0;
            next_column3 <= 32'b0;
        end else begin
            sub_word = {sbox_out[2], sbox_out[1], sbox_out[0], sbox_out[3]};

            if (ena) begin
                xor_word = sub_word ^ rcon_out;

                next_column0 = xor_word ^ column0;
                next_column1 = next_column0 ^ column1;
                next_column2 = next_column1 ^ column2;
                next_column3 = next_column2 ^ column3;

                next_key_out = {next_column0, next_column1, next_column2, next_column3};
                done = 1;
            end else begin
                done = 0;
            end
        end 
    end

endmodule*/

