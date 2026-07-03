```markdown
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
$> iverilog -g2012 -o uart_tx_sim rtl/uart_tx.v rtl/tb/uart_tx_tb.v
$> vvp uart_tx_sim
$> gtkwave uart_tx.vcd
```

**Loopback — single-sample RX (TX → RX):**
```
$> iverilog -g2012 -o uart_loopback_tb rtl/uart_tx.v rtl/uart_rx_single_sample.v rtl/tb/uart_loopback_tb.v
$> vvp uart_loopback_tb
$> gtkwave uart_loopback_tb.vcd
```

**Loopback — oversampled RX (TX → RX):**
```
$> iverilog -g2012 -o uart_loopback_oversampled_tb rtl/uart_tx.v rtl/uart_rx_oversampled.v rtl/tb/uart_loopback_oversampled_tb.v
$> vvp uart_loopback_oversampled_tb
$> gtkwave uart_loopback_oversampled_tb.vcd
```

## Modules

### `uart_tx`

The transmitter module.

```
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

### `uart_rx_single_sample`

The receiver module — single-sample (non-oversampled) version.

```
module uart_rx_single #(
    parameter CLK_HZ        = 100_000_000, // System clock frequency.
    parameter BAUD_RATE     = 9600,        // Target UART baud rate.
    parameter PAYLOAD_BITS  = 8            // Number of data bits per UART packet.
)(
    input                         clk,         // Top level system clock input.
    input                         reset,       // Active high synchronous reset.
    input                         rx_in,       // UART receive pin.
    output reg [PAYLOAD_BITS-1:0] rx_out,      // Received byte.
    output reg                    rx_valid,    // High when rx_out holds a valid received byte.
    output reg                    frame_error  // High when stop bit is invalid.
);
```

Implemented as a 4-state Moore FSM: `IDLE → START → DATA → STOP`. Samples each bit at the center of the bit-period. Includes start-bit glitch validation (re-samples `rx_in` at the mid-point of START and returns to IDLE if the line went back high) and frame error detection (`frame_error` fires if the stop bit is not high, preventing downstream logic from latching corrupted data).

### `uart_rx_oversampled`

The receiver module — 16x oversampled version.

```
module uart_rx_oversampled #(
    parameter CLK_HZ        = 100_000_000, // System clock frequency.
    parameter BAUD_RATE     = 9600,        // Target UART baud rate.
    parameter PAYLOAD_BITS  = 8            // Number of data bits per UART packet.
)(
    input                         clk,         // Top level system clock input.
    input                         reset,       // Active high synchronous reset.
    input                         rx_in,       // UART receive pin.
    output reg [PAYLOAD_BITS-1:0] rx_out,      // Received byte.
    output reg                    rx_valid,    // High when rx_out holds a valid received byte.
    output reg                    frame_error  // High when stop bit is invalid.
);
```

Implemented as a 4-state Moore FSM: `IDLE → START → DATA → STOP`. Samples `rx_in` at the 7/16 point of each bit-period (center of the bit window) for improved tolerance to clock drift and baud rate mismatch between transmitter and receiver. Includes start-bit glitch validation and frame error detection.

## What's Next

* FPGA integration — pin constraints, reset polarity, and clock frequency adjustments
```