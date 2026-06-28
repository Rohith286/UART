module uart_tx #(
    parameter CLK_HZ    = 100_000_000,     // system clock frequency
    parameter BAUD_RATE = 9600,            // desired baud rate
    parameter PAYLOAD_BITS = 8             // configurable number of data bits
)(
    input        clk,
    input        reset,
    input        tx_en,                    // start sending tx_data
    input [PAYLOAD_BITS-1:0] tx_data,      // byte to transmit
    output reg   tx_out,                   // serial output line
    output reg   tx_busy                   // high while transmitting
);

// 1 - bit period
localparam CLKS_PER_BIT = CLK_HZ / BAUD_RATE;

// bit and clock counter at every 
reg [$clog2(CLKS_PER_BIT)-1:0] clk_count;  // counts clock cycles within current bit period
reg [$clog2(PAYLOAD_BITS)-1:0] bit_index;  // tracks which data bit (0 to PAYLOAD_BITS-1) is being sent

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
        
        case(present_state)
            IDLE: begin
                clk_count <= 0;
                bit_index <= 0;
            end
            
            START: begin
                if(clk_count == CLKS_PER_BIT-1)
                    clk_count <= 0;
                else
                    clk_count <= clk_count + 1;
            end
            
            DATA: begin
                if(clk_count == CLKS_PER_BIT-1) begin
                    clk_count <= 0;
                    bit_index <= bit_index + 1;
                end
                else
                    clk_count <= clk_count + 1;
            end
            
            STOP: begin
                if(clk_count == CLKS_PER_BIT-1)
                    clk_count <= 0;
                else
                    clk_count <= clk_count + 1;
            end
        endcase
    end
end

always @(*) begin
    case(present_state)
        IDLE:  next_state = tx_en ? START : IDLE;
        START: next_state = (clk_count == CLKS_PER_BIT-1) ? DATA : START;
        DATA:  next_state = (bit_index == PAYLOAD_BITS-1 && clk_count == CLKS_PER_BIT-1) ? STOP : DATA;
        STOP:  next_state = (clk_count == CLKS_PER_BIT-1) ? IDLE : STOP;
        default: next_state = IDLE;
    endcase
end


// output logic
always @(*) begin
    case (present_state)
        IDLE: begin
            tx_out = 1'b1;      // IDLE line is HIGH by default
            tx_busy = 1'b0;
        end 
        START: begin
            tx_out = 1'b0;      // Start bit is LOW
            tx_busy = 1'b1;
        end 
        DATA: begin
            tx_out = tx_data[bit_index];
            tx_busy = 1'b1;
        end
        STOP: begin
            tx_out = 1'b1;      // Stop bit is HIGH
            tx_busy = 1'b1;
        end
        default: begin
            tx_out = 1'b1;
            tx_busy = 1'b0;
        end
    endcase
end

endmodule