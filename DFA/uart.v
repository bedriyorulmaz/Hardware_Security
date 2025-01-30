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

module uart ( clkin, rstin, txdatain, txrdyin, rxin, rxdataout, rxrdyout, txrdyout, txout, errout );

parameter CLKS_PER_BIT = 3125; // 2500 = 38400 @ 96MHz; 3125 = 19200 @ 60MHz; 625 @ 12MHz

input clkin;
input rstin;
input [7:0] txdatain;
input rxin;
input txrdyin;
output [7:0] rxdataout;
output txout;
output rxrdyout;
output txrdyout;
output errout;

reg [15:0] rxctr = 0;
reg [15:0] txctr = 0;
reg [2:0] rxbitctr = 3'b0;
reg [2:0] txbitctr = 3'b0;
reg [7:0] rxdataout = 8'h0;
reg txout = 1'b0;
reg rxrdyout = 1'b0;
reg errout = 1'b0;
reg txrdyout = 1'b0;
reg [1:0] rxstate = 2'b0;
reg [1:0] txstate = 2'b0;

always @( posedge clkin ) begin
	if ( !rstin ) begin
		rxctr <= 0;
		rxstate <= 2'b00;
		rxbitctr <= 3'b0;
		errout <= 1'b0;
		rxrdyout <= 1'b0;
	end else begin
		case ( rxstate )
			2'b00:
				begin
					rxctr <= 0;
					rxbitctr <= 3'b0;
					if (rxin == 1'b0) begin
						rxdataout <= 8'h00;
						rxstate <= 2'b01;
						rxrdyout <= 1'b0;
					end else begin
						rxstate <= 2'b0;
					end
				end
			2'b01:
				begin
					if ( rxctr == (CLKS_PER_BIT-1)/2 ) begin
						rxctr <= 0;
						if (rxin == 1'b0) begin
							rxstate <= 2'b10;		
						end else begin
							rxstate <= 2'b0;
						end
					end else begin
						rxctr <= rxctr + 1'b1;
						rxstate <= 2'b01;
					end
				end
			2'b10:
				begin
					if ( rxctr == CLKS_PER_BIT-1 ) begin
						rxctr <= 0;
						rxdataout[rxbitctr] <= rxin;
						if (rxbitctr == 3'b111) begin
							rxbitctr <= 3'b0;
							rxstate <= 2'b11;
						end else begin
							rxbitctr <= rxbitctr + 1'b1;
							rxstate <= 2'b10;
						end
					end else begin
						rxctr <= rxctr + 1'b1;
						rxstate <= 3'b010;
					end
				end
			2'b11:
				begin
					if ( rxctr == CLKS_PER_BIT-1 ) begin
						rxctr <= 0;
						if (rxin == 1'b1) begin
							rxrdyout <= 1'b1;
						end else begin
							errout <= 1'b1;
						end
						rxstate <= 2'b00;
					end else begin
						rxctr <= rxctr + 1'b1;
						rxstate <= 2'b11;
					end
				end
		endcase
	end
end

always @( posedge clkin ) begin
	if (!rstin) begin
		txstate <= 2'b00;
		txrdyout <= 1'b1;
		txout <= 1'b1;
		txctr <= 0;
		txbitctr <= 3'b0;
	end else begin
		case ( txstate )
			2'b00:
				begin
					txctr <= 0;
					txbitctr <= 3'b0;
					txrdyout <= 1'b1;
					if (txrdyin == 1'b1) begin
						txrdyout <= 1'b0;
						txstate <= 2'b01;
					end else begin
						txstate <= 2'b00;
					end
				end
			2'b01:
				begin
					txout <= 1'b0;
					if (txctr == (CLKS_PER_BIT-1)) begin
						txctr <= 0;
						txstate <= 2'b10;
					end else begin
						txctr <= txctr + 1'b1;
					end
				end
			2'b10:
				begin
					txout <= txdatain[txbitctr];
					if (txctr == (CLKS_PER_BIT-1)) begin
						txctr <= 0;
						if (txbitctr == 3'b111) begin
							txbitctr <= 3'b0;
							txstate <= 2'b11;
						end else begin
							txbitctr <= txbitctr + 1'b1;
							txstate <= 2'b10;
						end
					end else begin
						txctr <= txctr + 1'b1;
					end
				end
			2'b11:
				begin
					txout <= 1'b1;
					if (txctr == (CLKS_PER_BIT-1)) begin
						txctr <= 0;
						txstate <= 2'b00;
						txrdyout <= 1'b1;
					end else begin
						txctr <= txctr + 1'b1;
					end
				end
		endcase
	end
end


endmodule 