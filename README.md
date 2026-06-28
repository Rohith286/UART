A simple UART implementation, written in Verilog.

---

This is a simple implementation of a Universal Asynchronous Receiver Transmitter (UART), built from first principles while learning UART framing, baud-rate timing, and FSM design. It implements the transmitter as a Moore-style FSM, with the receiver in progress.

It was developed with Icarus Verilog and GTKWave, so it should cost you nothing to set up and play with in your own simulations.

This isn't a production-grade or hardware-tested implementation (no FPGA available during development), but it's fully simulated and verified through waveform tracing, and is parameterized so it isn't locked to a fixed clock speed, baud rate, or payload width.

## Tools

* [Icarus Verilog](http://iverilog.icarus.com/)
* [GTK Wave](http://gtkwave.sourceforge.net/)

Both can be installed on Ubuntu via the following command:

```
$> sudo apt-get install iverilog gtkwave
```

## Simulation

```
$> iverilog -o uart_tx_sim rtl/uart_tx.v test/uart_tx_tb.v
$> vvp uart_tx_sim
$> gtkwave uart_tx.vcd
```

This builds and runs the testbench for the TX module and outputs a `.vcd` waveform file you can inspect in GTKWave.

## Modules

### `uart_tx`

The transmitter module.

```verilog
module uart_tx #(
    parameter CLK_HZ        = 100_000_000, // System clock frequency.
    parameter BAUD_RATE     = 9600,        // Target UART baud rate.
    parameter PAYLOAD_BITS  = 8            // Number of data bits per UART packet.
)(
    input                     clk,      // Top level system clock input.
    input                     reset,    // Active high synchronous reset.
    input                     tx_en,    // Send the data on tx_data.
    input  [PAYLOAD_BITS-1:0] tx_data,  // The data to be sent.
    output reg                tx_out,   // UART transmit pin.
    output reg                tx_busy   // Module busy sending previous item.
);
```

Implemented as a 4-state Moore FSM: `IDLE → START → DATA → STOP`. `IDLE` holds the line high; `START` drives it low for one bit-period; `DATA` shifts out `PAYLOAD_BITS` bits, LSB first, one per bit-period; `STOP` returns the line high before going back to `IDLE`.

### `uart_rx`

The receiver module. (In progress.)

## What's Next

- [ ] `uart_rx` — receiver module, with 16x oversampling for reliable bit-center sampling
- [ ] Loopback testbench — TX output fed directly into RX input
- [ ] Framing error detection
