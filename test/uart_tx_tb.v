`timescale 1ns/1ps

module uart_tx_tb;
    reg        clk;
    reg        reset;
    reg        tx_en;                   // start sending tx_data
    reg [7:0]  tx_data;                 // byte to transmit
    wire       tx_out;                  // serial output line
    wire       tx_busy;                 // high while transmitting

    // 1 - bit period
    localparam CLK_HZ       = 1000;
    localparam BAUD_RATE    = 100;
    localparam CLKS_PER_BIT = CLK_HZ / BAUD_RATE;

    uart_tx #(
        .CLK_HZ(CLK_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        clk, reset, tx_en, tx_data, tx_out, tx_busy
    );

    always #5 clk = ~clk;

    integer i;
    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);

        clk     = 0;
        reset   = 1;
        tx_en   = 0;
        tx_data = 8'b10110101;

        repeat(5) @(posedge clk);
        reset = 0;

        @(posedge clk);
        tx_en = 1;
        @(posedge clk);
        tx_en = 0;

        @(posedge clk);                 // wait for FSM to transition to START
        $display("Start Bit: %b", tx_out);

        // wait for transmission to complete, sampling tx_out once per bit period
        for (i = 0; i < 8; i = i + 1) begin
            repeat(CLKS_PER_BIT) @(posedge clk);
            $display("Bit %0d: tx_out = %b", i, tx_out);
        end

        repeat(CLKS_PER_BIT) @(posedge clk);   // wait for FSM to transition to STOP
        $display("Stop Bit: %b", tx_out);

        repeat(CLKS_PER_BIT) @(posedge clk);
        $finish;
    end

endmodule
