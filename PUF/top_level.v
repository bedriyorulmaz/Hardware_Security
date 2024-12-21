module top_level (
   input  CLK,
   input  RST,
   output [7:0] LED,
   input  UART_RX,
   output UART_TX
);
   parameter PUF_BITS_DEF = 131072;

   wire [7:0] data_to_tx;
   wire [7:0] data_from_rx;
   wire tx_enable, rx_ready;
   wire data_valid;
   wire uart_rx_s, uart_tx_s;

   reg [7:0] led_state;
   wire err; // ı change reg to wire for output
   
   reg [22:0] counter = 0;
   wire [2:0]state;

   uart uart_inst (
      .clk ( CLK ),
      .rst ( RST ),
      .txdatain ( data_to_tx ),
      .txrdyin ( tx_enable ),
      .rxpin ( uart_rx_s ),
      .rxdataout ( data_from_rx ),
      .rxrdyout ( rx_ready ),
      .txrdyout ( data_valid ),
      .txpin ( uart_tx_s ),
      .errout ( err )
   );
   defparam uart_inst.CLKS_PER_BIT = 104;
   
   puf_module puf_module_inst (
        .clk ( CLK ),
        .rst ( RST ),
        // receiving signals
        .uart_rx_ready ( rx_ready ),
        .uart_data_from_rx ( data_from_rx ),
        // sending signals
        .uart_tx_ready ( data_valid ),
        .uart_data_to_tx ( data_to_tx ),

        .uart_tx_enable ( tx_enable )
   );
   defparam puf_module_inst.PUF_BITS = PUF_BITS_DEF;

   assign UART_TX = uart_tx_s;
   assign uart_rx_s = UART_RX;
   assign LED = led_state;
//assign LED[0] = err;      // Blinking heartbeat
//assign LED[1] = rx_ready;         // UART RX readiness
//assign LED[2] = data_valid;       // UART TX readiness
//assign LED[3] = RST;              // UART TX enable
//assign LED[4] = (data_from_rx == 8'h73); // Light up when 's' is received
//assign LED[5] = state[0]; // FSM state bit 0
//assign LED[6] = state[1]; // FSM state bit 1
//assign LED[7] = state[2];// FSM state bit 2
//assign LED[6:0] = data_to_tx[6:0];


   always @(posedge CLK, posedge RST) begin
     if (RST) begin
        begin
            counter <= 0;
            led_state <= 0;
        end
     end else begin
        if (counter < 6000000) begin
            counter <= counter + 1;
        end else begin
           led_state[0] <= led_state[0] ^ 1;
            counter <= 0;
        end
     end
   end

endmodule
