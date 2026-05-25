// =============================================================================
// Module: top.v
// Description: Top-level wrapper for FPGA SPI Web Dashboard
//              Instantiates: spi_slave + led_controller
//
//  PIN MAPPING (Basys3 / Nexys A7 — adjust in XDC for your board):
//    clk     → W5   (100 MHz onboard clock)
//    rst_n   → U18  (BTN_CENTER or slide switch)
//    spi_sclk→ J1   (PMOD JA pin 1)
//    spi_mosi→ L2   (PMOD JA pin 2)
//    spi_cs_n→ J2   (PMOD JA pin 4)
//    spi_miso→ G2   (PMOD JA pin 3)
//    leds[0] → U16  (LD0)
//    leds[1] → E19  (LD1)
//    leds[2] → U19  (LD2)
//    leds[3] → V19  (LD3)
//    leds[4] → W18  (LD4)
//    leds[5] → U15  (LD5)
//    leds[6] → U14  (LD6)
//    leds[7] → V14  (LD7)
// =============================================================================

module top (
    input  wire       clk,         // 100 MHz system clock
    input  wire       rst_n,       // Active-low reset (button/switch)
    // SPI interface (from ESP32)
    input  wire       spi_sclk,
    input  wire       spi_mosi,
    input  wire       spi_cs_n,
    output wire       spi_miso,
    // LED outputs
    output wire [7:0] leds
);

    // Internal wires
    wire [7:0] rx_data;
    wire       data_ready;

    // -------------------------------------------------------------------------
    // SPI Slave Instance
    // -------------------------------------------------------------------------
    spi_slave u_spi_slave (
        .clk        (clk),
        .rst_n      (rst_n),
        .sclk       (spi_sclk),
        .mosi       (spi_mosi),
        .cs_n       (spi_cs_n),
        .miso       (spi_miso),
        .rx_data    (rx_data),
        .data_ready (data_ready)
    );

    // -------------------------------------------------------------------------
    // LED Controller Instance
    // -------------------------------------------------------------------------
    led_controller u_led_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_data    (rx_data),
        .data_ready (data_ready),
        .leds       (leds)
    );

endmodule
