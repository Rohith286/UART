module uart_rx_oversampled#(
    parameter CLK_HZ    = 100_000_000,     // system clock frequency
    parameter BAUD_RATE = 9600,            // desired baud rate
    parameter PAYLOAD_BITS = 8             // configurable number of data bits
)(
    input clk,
    input reset,
    input rx_in,                            // tx_out
    output reg [PAYLOAD_BITS-1:0] rx_out,   // received byte
    output reg rx_valid,                    // high when rx_out holds a valid received byte
    output reg frame_error                  // high when stop bit is invalid
);

// 1 - bit period
localparam CLKS_PER_BIT = CLK_HZ / BAUD_RATE;

// bit and clock counter at every
reg [$clog2(CLKS_PER_BIT)-1:0] clk_count;  // counts clock cycles within current bit period
reg [$clog2(PAYLOAD_BITS+1)-1:0] bit_index;  // tracks which data bit (0 to PAYLOAD_BITS-1) is being sent

// FSM States
localparam IDLE  = 2'b00;
localparam START = 2'b01;
localparam DATA  = 2'b10;
localparam STOP  = 2'b11;

reg [1:0] present_state;
reg [1:0] next_state;

always @(posedge clk) begin
    if(reset) begin
        present_state <= IDLE;
        clk_count <= 0;
        bit_index <= 0;
    end
    else begin
        present_state <= next_state;
        case (present_state)
            IDLE: begin
                clk_count <= 0;
                bit_index <= 0;
            end

            START: begin
                if(clk_count == CLKS_PER_BIT - 1)
                    clk_count <= 0;
                else 
                    clk_count <= clk_count + 1;
            end

            DATA: begin
                if(clk_count == 7 * CLKS_PER_BIT / 16) begin
                    rx_out[bit_index] <= rx_in;
                    bit_index <= bit_index + 1;
                    clk_count <= clk_count + 1;
                end
                else if(clk_count == CLKS_PER_BIT - 1)
                    clk_count <= 0;
                else 
                    clk_count <= clk_count + 1;
            end

            STOP: begin
                if(clk_count == CLKS_PER_BIT - 1)
                    clk_count <= 0;
                else 
                    clk_count <= clk_count + 1;
            end

            default: begin
                clk_count <= 0;
                bit_index <= 0;
            end
        endcase
    end
end

always @(*) begin
    case (present_state)
        IDLE: next_state = rx_in ? IDLE : START;
        START: next_state = (clk_count == 7*CLKS_PER_BIT/16 && rx_in) ? IDLE  // glitch
                          : (clk_count == CLKS_PER_BIT-1) ? DATA : START;  // real start bit, move on
        DATA: next_state = (bit_index == PAYLOAD_BITS && clk_count == CLKS_PER_BIT-1)? STOP : DATA;
        STOP: next_state = (clk_count == CLKS_PER_BIT-1) ? IDLE : STOP;
        default: next_state = IDLE;
    endcase
end

// output logic
always @(*) begin
    case (present_state)
        STOP: begin
            // rx_valid fires only if stop bit is high (clean frame), frame_error fires if low (baud mismatch or line corruption) — rx_out is discarded downstream if rx_valid never pulses
            rx_valid = (clk_count == CLKS_PER_BIT-1) ? rx_in  : 0;   
            frame_error = (clk_count == CLKS_PER_BIT-1) ? ~rx_in : 0;
        end
        default: begin
            rx_valid = 0;
            frame_error = 0;
        end
    endcase
end

endmodule