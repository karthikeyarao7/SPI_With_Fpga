// =============================================================================
// Module: led_controller.v
// Description: Decodes received SPI byte and drives 8 LEDs
//              Bit[0] → LED0, Bit[1] → LED1 ... Bit[7] → LED7
//              Each bit directly maps to one LED
//              Supports TOGGLE and SET modes via command byte
//
//  Command protocol (one byte from ESP32):
//    Bits [7:0] = LED mask — 1 = ON, 0 = OFF  (direct mode)
//
//  For future extension:
//    You can use upper nibble as opcode and lower nibble as LED select
// =============================================================================

module led_controller (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] rx_data,      // Byte from SPI slave
    input  wire       data_ready,   // Pulse from SPI slave
    output reg  [7:0] leds          // 8 LED outputs (active HIGH)
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            leds <= 8'h00;   // All LEDs OFF on reset
        end else begin
            if (data_ready) begin
                leds <= rx_data;   // Direct map: received byte → LEDs
            end
        end
    end

endmodule
