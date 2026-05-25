// =============================================================================
// Module: spi_slave.v
// Description: SPI Slave — Mode 0 (CPOL=0, CPHA=0)
//              Receives 8-bit bytes from ESP32 SPI Master
//              Shifts MOSI bits on rising edge of SCLK
//              Asserts data_ready for one clk cycle when full byte received
// =============================================================================

module spi_slave (
    input  wire       clk,        // System clock (e.g., 100 MHz)
    input  wire       rst_n,      // Active-low synchronous reset
    input  wire       sclk,       // SPI Clock from ESP32
    input  wire       mosi,       // Master Out Slave In
    input  wire       cs_n,       // Chip Select (active LOW)
    output wire       miso,       // Master In Slave Out (loopback / status)
    output reg  [7:0] rx_data,    // Received byte
    output reg        data_ready  // Pulses HIGH for one clk when byte complete
);

    // -------------------------------------------------------------------------
    // Double-flop synchronizers for SCLK, MOSI, CS_N (metastability)
    // -------------------------------------------------------------------------
    reg sclk_r1, sclk_r2;
    reg mosi_r1, mosi_r2;
    reg cs_r1,   cs_r2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_r1 <= 1'b0; sclk_r2 <= 1'b0;
            mosi_r1 <= 1'b0; mosi_r2 <= 1'b0;
            cs_r1   <= 1'b1; cs_r2   <= 1'b1;
        end else begin
            sclk_r1 <= sclk; sclk_r2 <= sclk_r1;
            mosi_r1 <= mosi; mosi_r2 <= mosi_r1;
            cs_r1   <= cs_n; cs_r2   <= cs_r1;
        end
    end

    // Detect rising edge of SCLK in system clock domain
    wire sclk_rising = (sclk_r1 && !sclk_r2);

    // -------------------------------------------------------------------------
    // Shift register and bit counter
    // -------------------------------------------------------------------------
    reg [7:0] shift_reg;
    reg [2:0] bit_count;   // Counts 0–7

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg  <= 8'h00;
            bit_count  <= 3'd0;
            rx_data    <= 8'h00;
            data_ready <= 1'b0;
        end else begin
            data_ready <= 1'b0;   // Default: de-assert

            if (!cs_r2) begin
                // CS is active (LOW) — SPI transaction in progress
                if (sclk_rising) begin
                    shift_reg <= {shift_reg[6:0], mosi_r2};  // MSB first
                    bit_count <= bit_count + 1;

                    if (bit_count == 3'd7) begin
                        // Full byte received on this edge
                        rx_data    <= {shift_reg[6:0], mosi_r2};
                        data_ready <= 1'b1;
                        bit_count  <= 3'd0;
                    end
                end
            end else begin
                // CS de-asserted — reset for next transaction
                bit_count <= 3'd0;
            end
        end
    end

    // MISO: send back received byte MSB first (loopback / echo)
    assign miso = shift_reg[7];

endmodule
