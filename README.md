# UART

A simple UART implementation, written in Verilog.

This is a simple implementation of a Universal Asynchronous Receiver Transmitter (UART), built from first principles while learning UART framing, baud-rate timing, and FSM design. Both the transmitter and receiver are implemented as Moore-style FSMs. The receiver includes start-bit glitch validation and frame error detection.

It was developed with Icarus Verilog and GTKWave, so it should cost you nothing to set up and play with in your own simulations.

This isn't a production-grade or hardware-tested implementation (FPGA integration in progress), but it's fully simulated and verified through loopback testing and waveform tracing, and is parameterized so it isn't locked to a fixed clock speed, baud rate, or payload width.

## Tools

* [Icarus Verilog](http://iverilog.icarus.com/)
* [GTKWave](http://gtkwave.sourceforge.net/)

Both can be installed on Ubuntu via the following command:

```
$> sudo apt-get install iverilog gtkwave
```

## Simulation

**TX only:**

```
$> iverilog -g2012 -o uart_tx_sim uart_tx.v uart_tx_tb.v
$> vvp uart_tx_sim
$> gtkwave uart_tx.vcd
```

**Loopback — single-sample RX:**

```
$> iverilog -g2012 -o uart_loopback_tb uart_loopback_tb.v uart_tx.v uart_rx_single_sample.v
$> vvp uart_loopback_tb
$> gtkwave uart_loopback_tb.vcd
```

**Loopback — oversampled RX:**

```
$> iverilog -g2012 -o uart_loopback_oversampled_tb uart_loopback_oversampled_tb.v uart_tx.v uart_rx_oversampled.v
$> vvp uart_loopback_oversampled_tb
$> gtkwave uart_loopback_oversampled_tb.vcd
```

## Modules

### `uart_tx`

The transmitter module.

```
module uart_tx #(
    parameter CLK_HZ        = 100_000_000,
    parameter BAUD_RATE     = 9600,
    parameter PAYLOAD_BITS  = 8
)(
    input                     clk,
    input                     reset,
    input                     tx_en,
    input  [PAYLOAD_BITS-1:0] tx_data,
    output reg                tx_out,
    output reg                tx_busy
);
```

Implemented as a 4-state Moore FSM: `IDLE → START → DATA → STOP`. `IDLE` holds the line high; `START` drives it low for one bit-period; `DATA` shifts out `PAYLOAD_BITS` bits, LSB first, one per bit-period; `STOP` returns the line high before going back to `IDLE`.

### `uart_rx_single_sample`

The receiver module — single-sample (non-oversampled) version.

```
module uart_rx_single #(
    parameter CLK_HZ        = 100_000_000,
    parameter BAUD_RATE     = 9600,
    parameter PAYLOAD_BITS  = 8
)(
    input                         clk,
    input                         reset,
    input                         rx_in,
    output reg [PAYLOAD_BITS-1:0] rx_out,
    output reg                    rx_valid,
    output reg                    frame_error
);
```

Implemented as a 4-state Moore FSM: `IDLE → START → DATA → STOP`. Samples each bit at the center of the bit-period. Includes start-bit glitch validation (re-samples `rx_in` at the mid-point of START and returns to IDLE if the line went back high) and frame error detection (`frame_error` fires if the stop bit is not high, preventing downstream logic from latching corrupted data).

### `uart_rx_oversampled`

The receiver module — 16x oversampled version.

```
module uart_rx_oversampled #(
    parameter CLK_HZ        = 100_000_000,
    parameter BAUD_RATE     = 9600,
    parameter PAYLOAD_BITS  = 8
)(
    input                         clk,
    input                         reset,
    input                         rx_in,
    output reg [PAYLOAD_BITS-1:0] rx_out,
    output reg                    rx_valid,
    output reg                    frame_error
);
```

Implemented as a 4-state Moore FSM: `IDLE → START → DATA → STOP`. Samples `rx_in` at the 7/16 point of each bit-period (center of the bit window) for improved tolerance to clock drift and baud rate mismatch between transmitter and receiver. Includes start-bit glitch validation and frame error detection.

## What's Next

* FPGA integration — pin constraints, reset polarity, and clock frequency adjustments