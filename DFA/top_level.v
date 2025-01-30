/*
 **
 ** Copyright 2019 Karlsruhe Institute of Technology, Chair of Dependable Nano Computing
 **
 ** Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 ** and associated documentation files (the "Software"), to deal in the Software without restriction, 
 ** including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 ** and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do 
 ** so, subject to the following conditions:
 **
 ** The above copyright notice and this permission notice shall be included in all copies or substantial 
 ** portions of the Software.
 **
 ** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
 ** LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
 ** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
 ** WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
 ** SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 **
 */
 
module top_level(clkin, rstin, uart_rxin, uart_txout, ledout);
	
	input clkin; // 12 MHz clock input
	input rstin; // Raw reset input
	
	// UART signals and registers
	input uart_rxin; // UART RX pin
	output uart_txout; // UART TX pin
	reg [7:0] uart_txdata; // Byte to transmit
	wire [7:0] uart_rxdata; // Byte received
	wire uart_rxready; // UART byte received signal
	wire uart_txready; // UART ready to transmit signal
	reg uart_txready_ctrl = 1'b0; // UART byte ready to transmit signal
	
	// AES signals and registers
	wire [127:0] aes_dout; // AES ciphertext out
	reg [127:0] aes_din = 128'h00000000000000000000000000000000; // AES plaintext in
	wire aes_done; // AES encryption completed signal
	reg aes_rst = 1'b0; // AES reset (active low)
	
	output [7:0] ledout; // Board LEDs for blinker and debug
	reg led_blink = 1'b0;
	assign ledout[7] = led_blink;
	
	reg [31:0] ctr = 0; // counter for blinking LED
	wire clk60mhz; // Main design clock from PLL
	
	// Encryption state machine registers
	parameter IDLE = 3'b000, RECV_MASK = 3'b001, RECV_CYCLES = 3'b010, RECV_ACTIVECYCLES = 3'b011, RECV_PLAIN = 3'b100, ENC = 3'b101, SEND_CIPHER = 3'b110; 
	reg [2:0] enc_state = IDLE; 
	reg [7:0] bytectr = 5'b0; 
	reg [1:0] rxready_buf = 2'b0; // buffer for sampling UART recv flank
	assign ledout[2:0] = enc_state;
	
	// RO grid toggle parameters
	reg [31:0] cycles_ctr = 32'h0; // Cycle counter
	reg [31:0] cycles = 32'h0; // Toggle period
	reg [31:0] activecycles = 32'h0; // Toggle duty-cycle
	reg inject = 1'b0; // Toggle activation
	reg ena_fault = 1'b0; //Enable injection at next encryption
	assign ledout[3] = ena_fault;
	
	reg grid_ena_reg = 1'b0; // RO-grid synchronization register
    reg [7:0] grid_mask = 8'hff;
	assign ledout[4] = grid_ena_reg;
	
	// UART module
	uart uart_inst(	.clkin(clk60mhz), .rstin(rstin), .rxin(uart_rxin), .txout(uart_txout), .txdatain(uart_txdata), .rxdataout(uart_rxdata), 
					.txrdyin(uart_txready_ctrl), .rxrdyout(uart_rxready), .txrdyout(uart_txready), .errout(ledout[5])); 
	
	// AES module (with fixed FIPS example key)
	aes aes_inst(.clk(clk60mhz), .rst(aes_rst), .din(aes_din), .dout(aes_dout), .keyin(128'h3c4fcf098815f7aba6d2ae2816157e2b), .done(aes_done), .lastround());
    
	// 60 MHz PLL clock generator
	pll pll_60mhz(.clock_in(clkin), .clock_out(clk60mhz));
	
	genvar i;
	generate
		for (i = 0; i < 4800; i = i + 1) begin : ro_grid //3840
			ringosc ro(.enable(grid_ena_reg & grid_mask[i%8])) /* synthesis syn_noprune=1 syn_preserve=1 */;
		end
	endgenerate

	// Blinking LED process
	always @(posedge clk60mhz) begin
		if (!rstin) begin
			ctr <= 0;
			led_blink <= 1'b0;
		end else if (ctr >= 60000000) begin
			led_blink <= ~led_blink;
			ctr <= 0;
		end else begin
			ctr <= ctr + 1;
		end
	end
	
	// Byte received detection buffer 
	always @(posedge clk60mhz) begin
		if (!rstin) begin
			rxready_buf <= 2'b0;
		end else begin
			rxready_buf <= {rxready_buf[0], uart_rxready};
		end
	end
	
	// Encryption state machine
	always @(posedge clk60mhz) begin
		if (!rstin) begin
			enc_state <= IDLE;
			aes_rst <= 1'b1;
			bytectr <= 1'b0;
			inject <= 1'b0;
			uart_txready_ctrl <= 1'b0;
			ena_fault <= 1'b0;
		end else
			case (enc_state)
				IDLE: 				if (rxready_buf == 2'b01) begin // Byte received on UART
										ena_fault <= uart_rxdata[0];
										bytectr <= 5'd0;
										enc_state <= RECV_MASK;
									end else begin
										aes_rst <= 1'b1;
										bytectr <= 1'b0;
										inject <= 1'b0;
										uart_txready_ctrl <= 1'b0;
										enc_state <= IDLE;
									end
                RECV_MASK:          if (rxready_buf == 2'b01) begin // Byte received on UART
										grid_mask <= uart_rxdata;
										bytectr <= 5'd0;
										enc_state <= RECV_CYCLES;
									end else begin
										aes_rst <= 1'b1;
										bytectr <= 1'b0;
										inject <= 1'b0;
										uart_txready_ctrl <= 1'b0;
										enc_state <= RECV_MASK;
									end
				RECV_CYCLES:		if (bytectr == 5'd4) begin // 4 bytes (cycles) received
										bytectr <= 5'd0;
										enc_state <= RECV_ACTIVECYCLES;
									end else if (rxready_buf == 2'b01) begin
										cycles[31 - (bytectr << 3)-:8] <= uart_rxdata; // Big endian byte order receive
										bytectr <= bytectr + 5'd1;
										enc_state <= RECV_CYCLES;
									end else begin
										enc_state <= RECV_CYCLES;
									end
				RECV_ACTIVECYCLES: 	if (bytectr == 5'd4) begin // 4 bytes (activecycles) received
										bytectr <= 5'd0;
										enc_state <= RECV_PLAIN;
									end else if (rxready_buf == 2'b01) begin
										activecycles[31 - (bytectr << 3)-:8] <= uart_rxdata; // Big endian byte order receive
										bytectr <= bytectr + 5'd1;
										enc_state <= RECV_ACTIVECYCLES;
									end else begin
										enc_state <= RECV_ACTIVECYCLES;
									end
				RECV_PLAIN:			if (bytectr == 5'd16) begin // 16 bytes (complete plaintext) received
										bytectr <= 5'd0;
										enc_state <= ENC;
									end else if (rxready_buf == 2'b01) begin
										aes_din[(bytectr << 3)+:8] <= uart_rxdata; // Little endian byte order receive
										bytectr <= bytectr + 5'd1;
										enc_state <= RECV_PLAIN;
									end else begin
										enc_state <= RECV_PLAIN;
									end
				ENC:				if (aes_done) begin // Wait for AES to complete encryption 
										bytectr <= 5'd0;
										inject <= 1'b0;
										enc_state <= SEND_CIPHER;
									end else begin
                                        aes_rst <= 1'b0;
										inject <= ena_fault; // Enable RO grid toggling
										enc_state <= ENC;
									end
				SEND_CIPHER:		if (bytectr == 5'd16) begin
										uart_txready_ctrl <= 1'b0;
										enc_state <= IDLE;
                                        aes_rst <= 1'b1;
									end else if ((uart_txready) && (!uart_txready_ctrl)) begin // Send the ciphertext
										uart_txdata <= aes_dout[(bytectr << 3)+:8]; // Big endian byte order send
										uart_txready_ctrl <= 1'b1;
										bytectr <= bytectr + 5'd1;
										enc_state <= SEND_CIPHER;
									end else begin
										uart_txready_ctrl <= 1'b0;
										enc_state <= SEND_CIPHER;
									end
				default: 			enc_state <= IDLE;
			endcase
	end
	
	// RO grid toggling
	always @(posedge clk60mhz) begin
		if (!rstin) begin
			cycles_ctr <= 32'h0;
			grid_ena_reg <= 1'b0;
		end else if ((cycles_ctr >= cycles) && inject) begin
			cycles_ctr <= 32'h0;
		end else if ((cycles_ctr <= activecycles) && inject) begin
			grid_ena_reg <= 1'b1;
			cycles_ctr <= cycles_ctr + 32'h1;
		end else if (inject) begin
			grid_ena_reg <= 1'b0;
			cycles_ctr <= cycles_ctr + 32'h1;
		end else begin
			grid_ena_reg <= 1'b0;
		end
	end
	
endmodule


