`timescale 1ns/1ps

module uart_tx_tb;
    reg        clk;
    reg        reset;
    reg        tx_en;                    // start sending tx_data
    reg [7:0] tx_data;      // byte to transmit
    wire   tx_out;                   // serial output line
    wire   tx_busy;                   // high while transmitting

    uart_tx #(
        .CLK_HZ(1000),
        .BAUD_RATE(100)
    )
    uut (
        clk, reset, tx_en, tx_data, tx_out, tx_busy
    );

    always #5 clk = ~clk;

    integer i;
    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);

        clk = 0;
        reset = 1;
        tx_en = 0;
        tx_data = 8'b0;
        tx_data = 8'b10110101;

        #50;
        reset = 0;
        tx_en = 1;

        #10;
        tx_en = 0;
        $display("Start Bit: %d", tx_out);

        // Wait for transmission to complete, sampling tx_out once per bit period
        for (i = 0; i < 8; i = i + 1) begin   // 1 start + 8 data + 1 stop = 10 bit periods
            #100;                              // CLKS_PER_BIT * clk_period = 10*10 = 100ns
            $display("Bit %0d: tx_out = %b", i, tx_out);
        end

        $display("Stop Bit: %d", tx_out);

        #100;
        $finish;
    end
    
endmodule