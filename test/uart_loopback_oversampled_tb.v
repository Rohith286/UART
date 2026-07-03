`timescale 1ns/1ps

module uart_loopback_tb;

// parameters
localparam CLK_HZ      = 100_000_000;
localparam BAUD_RATE   = 9600;
localparam PAYLOAD_BITS = 8;
localparam CLK_PERIOD  = 1_000_000_000 / CLK_HZ;  // in ns
localparam CLKS_PER_BIT = CLK_HZ / BAUD_RATE;

// inputs to TX
reg clk, reset;
reg tx_en;
reg [PAYLOAD_BITS-1:0] tx_data;

// TX outputs / RX inputs
wire tx_out;
wire tx_busy;

// RX outputs
wire [PAYLOAD_BITS-1:0] rx_out;
wire rx_valid;
wire frame_error;

// instantiate TX
uart_tx #(
    .CLK_HZ(CLK_HZ),
    .BAUD_RATE(BAUD_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS)
) tx_inst (
    .clk(clk),
    .reset(reset),
    .tx_en(tx_en),
    .tx_data(tx_data),
    .tx_out(tx_out),
    .tx_busy(tx_busy)
);

// instantiate RX — loopback: tx_out -> rx_in
uart_rx_oversampled #(
    .CLK_HZ(CLK_HZ),
    .BAUD_RATE(BAUD_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS)
) rx_inst (
    .clk(clk),
    .reset(reset),
    .rx_in(tx_out),
    .rx_out(rx_out),
    .rx_valid(rx_valid),
    .frame_error(frame_error)
);

// clock generation
always #(CLK_PERIOD/2) clk = ~clk;

// test
initial begin
    $dumpfile("uart_loopback_oversampled_tb.vcd");
    $dumpvars(0, uart_loopback_tb);

    // init
    clk = 0;
    reset = 1;
    tx_en = 0;
    tx_data  = 0;

    // hold reset
    repeat(5) @(posedge clk);
    reset = 0;

    // send 10100101
    @(posedge clk);
    tx_data  = 8'b10100101;
    tx_en = 1;
    @(posedge clk);
    tx_en = 0;

    // wait for rx_valid, timeout after 20 bit periods
    /*
    begin : timeout_block
        integer count;
        count = 0;
        while(!rx_valid && count < CLKS_PER_BIT * 20) begin
            @(posedge clk);
            count = count + 1;
        end
        if(!rx_valid) begin
            $display("FAIL: timeout, rx_valid never asserted");
            $finish;
        end
    end
    */
    fork
        begin   // branch - 1
            wait(rx_valid);
            @(posedge clk);
        end
        begin   // branch - 2 
            repeat(CLKS_PER_BIT * 20) @(posedge clk);
            $display("FAIL: timeout, rx_valid never asserted");
            $finish;
        end
    join_any
    disable fork;
    // Branch 2 counts 20 posedge clks and if it finishes before branch 1 (meaning rx_valid never went high in that time), 
    // it prints FAIL and calls $finish. Branch 1 is still stuck at wait(rx_valid) but $finish kills everything anyway.

    // check
    if(rx_out === tx_data)
        $display("PASS: received %b", rx_out);
    else
        $display("FAIL: expected %b, got %b", tx_data, rx_out);

    if(frame_error)
        $display("FAIL: frame error asserted");

    // wait and finish
    repeat(CLKS_PER_BIT * 2) @(posedge clk);
    $finish;
end

endmodule