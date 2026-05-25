// File: testbench.v
// Description: Self-checking testbench for top.v
//              Simulates ESP32 as SPI Master sending bytes
//              Verifies LED outputs match sent byte
//
//  Run in Vivado Simulator or ModelSim / Icarus Verilog
// =============================================================================

`timescale 1ns / 1ps

module testbench;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg        clk       = 0;
    reg        rst_n     = 0;
    reg        spi_sclk  = 0;
    reg        spi_mosi  = 0;
    reg        spi_cs_n  = 1;
    wire       spi_miso;
    wire [7:0] leds;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    top dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .spi_sclk (spi_sclk),
        .spi_mosi (spi_mosi),
        .spi_cs_n (spi_cs_n),
        .spi_miso (spi_miso),
        .leds     (leds)
    );

    // -------------------------------------------------------------------------
    // Clock: 100 MHz → 10 ns period
    // -------------------------------------------------------------------------
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // SPI Master task — sends 8-bit byte MSB first, SPI Mode 0
    //   sclk_half: half-period of SPI clock (e.g., 200 ns = 2.5 MHz SPI)
    // -------------------------------------------------------------------------
    task spi_send_byte;
        input [7:0] data;
        integer i;
        begin
            spi_cs_n = 1'b0;          // Assert CS
            #200;                      // Setup time
            for (i = 7; i >= 0; i = i - 1) begin
                spi_mosi = data[i];   // Place bit on MOSI
                #200;
                spi_sclk = 1'b1;      // Rising edge — FPGA samples here
                #200;
                spi_sclk = 1'b0;      // Falling edge
                #200;
            end
            spi_cs_n = 1'b1;          // De-assert CS
            #500;
        end
    endtask

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [7:0] expected;
        input [7:0] actual;
        input [63:0] test_name;
        begin
            #100;  // Allow LED register to settle
            if (actual === expected) begin
                $display("PASS [%s]: LEDs = 0x%02X", test_name, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [%s]: Expected 0x%02X, Got 0x%02X", test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        // Waveform dump for GTKWave / Vivado
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);

        // ---- Reset ----
        rst_n = 0;
        #200;
        rst_n = 1;
        #200;

        $display("=== SPI FPGA LED Testbench ===");

        // Test 1: Turn on LED0 only (0x01)
        spi_send_byte(8'h01);
        check(8'h01, leds, "LED0_ON");

        // Test 2: Turn on LED7 only (0x80)
        spi_send_byte(8'h80);
        check(8'h80, leds, "LED7_ON");

        // Test 3: Turn on all LEDs (0xFF)
        spi_send_byte(8'hFF);
        check(8'hFF, leds, "ALL_ON");

        // Test 4: Turn off all LEDs (0x00)
        spi_send_byte(8'h00);
        check(8'h00, leds, "ALL_OFF");

        // Test 5: Alternating pattern (0xAA = 10101010)
        spi_send_byte(8'hAA);
        check(8'hAA, leds, "PATTERN_AA");

        // Test 6: Alternating pattern (0x55 = 01010101)
        spi_send_byte(8'h55);
        check(8'h55, leds, "PATTERN_55");

        // Test 7: Switch 1+3+5+7 = 0xAA → LED on
        spi_send_byte(8'hA5);
        check(8'hA5, leds, "SW_COMBO");

        // ---- Summary ----
        #500;
        $display("==============================");
        $display("TOTAL: %0d PASS, %0d FAIL", pass_count, fail_count);
        if (fail_count == 0)
            $display(">>> ALL TESTS PASSED <<<");
        else
            $display(">>> SOME TESTS FAILED <<<");
        $display("==============================");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #1_000_000;
        $display("TIMEOUT — simulation exceeded 1ms");
        $finish;
    end

endmodule
