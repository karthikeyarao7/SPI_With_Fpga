  Project Overview
This project demonstrates a complete browser-to-FPGA communication pipeline where clicking a switch on a webpage sends a signal through WebSocket, through an ESP32 microcontroller via SPI, and directly controls LEDs on a Digilent ZedBoard (Xilinx Zynq XC7Z020) FPGA development board.
It is a hands-on implementation of:

SPI slave design in Verilog HDL
Real-time WebSocket communication
ESP32 as a wireless SPI master bridge
FPGA digital design with synchronous logic and metastability handling


  Simulation: 7/7 tests passed in Vivado XSim


 How It Works
User clicks switch on browser
        ↓  WebSocket (WiFi)
ESP32 receives "LED:01"
        ↓  SPI (CS + SCLK + MOSI)
FPGA shift register assembles byte
        ↓  data_ready pulse
LED controller latches output
        ↓  3.3V on FPGA pin
ZedBoard LED lights up ✓
Total click-to-LED latency: under 10ms

🗂️ Repository Structure
📦 FPGA_SPI_Web_Dashboard
 ┣ 📂 rtl
 ┃ ┣ spi_slave.v          → SPI receiver with double-flop synchronizer
 ┃ ┣ led_controller.v     → LED output register
 ┃ ┗ top.v                → Top-level wrapper
 ┃
 ┣ 📂 sim
 ┃ ┗ testbench.v          → Self-checking testbench (7 test cases)
 ┃
 ┣ 📂 constraints
 ┃ ┗ zedboard_constraints.xdc  → ZedBoard pin & timing constraints
 ┃
 ┣ 📂 esp32
 ┃ ┗ spi_master.ino       → Arduino firmware (WebSocket server + SPI master)
 ┃
 ┣ 📂 web
 ┃ ┗ index.html           → Complete web dashboard (no server needed)
 ┃
 ┗ README.md

  Hardware Required
ComponentDetailsFPGA BoardDigilent ZedBoard (Xilinx Zynq XC7Z020)MicrocontrollerESP32 DevKit (any WROOM variant)Jumper Wires5× Male-to-MaleUSB Cables2× (one per board)NetworkWiFi 2.4GHz (ESP32 + PC on same network)

🔧 Wiring (ESP32 ↔ ZedBoard PMOD JA)
ESP32 GPIO 18  ──────→  PMOD JA Pin 1   (SCLK)
ESP32 GPIO 23  ──────→  PMOD JA Pin 2   (MOSI)
ESP32 GPIO 19  ←──────  PMOD JA Pin 3   (MISO)
ESP32 GPIO 5   ──────→  PMOD JA Pin 4   (CS_N)
ESP32 GND      ──────→  PMOD JA GND     (GND)

⚠️ Both boards operate at 3.3V logic — do NOT connect 5V lines to PMOD pins.
⚠️ Shared GND is mandatory for SPI to work.


  SPI Protocol Details
ParameterValueModeSPI Mode 0 (CPOL=0, CPHA=0)Bit OrderMSB FirstClock Speed1 MHzPacket Size8 bits (1 byte)CS PolarityActive LOW
Command Protocol
Browser sendsByte (hex)BinaryLEDs ONLED:000x000000 0000All OFFLED:010x010000 0001LD0LED:800x801000 0000LD7LED:FF0xFF1111 1111All ONLED:AA0xAA1010 1010LD1,3,5,7LED:550x550101 0101LD0,2,4,6

  RTL Design
Core Shift Register Logic (spi_slave.v)
verilog// Double-flop synchronizer — prevents metastability
always @(posedge clk) begin
    sclk_r1 <= sclk; sclk_r2 <= sclk_r1;
    mosi_r1 <= mosi; mosi_r2 <= mosi_r1;
end

// Rising edge detection
wire sclk_rising = (sclk_r1 && !sclk_r2);

// Shift register — MSB first
always @(posedge clk) begin
    if (!cs_n && sclk_rising) begin
        shift_reg <= {shift_reg[6:0], mosi_r2};
        bit_count <= bit_count + 1;
        if (bit_count == 3'd7) begin
            rx_data    <= {shift_reg[6:0], mosi_r2};
            data_ready <= 1'b1;   // Pulse for one clock cycle
        end
    end
end
LED Controller Logic (led_controller.v)
verilogalways @(posedge clk) begin
    if (data_ready)
        leds <= rx_data;   // Direct map: byte → 8 LEDs
end

  Simulation Results
Tested in Vivado XSim 2025.2 using run all in the Tcl console:
=== SPI FPGA LED Testbench ===
PASS [ LED0_ON]: LEDs = 0x01
PASS [ LED7_ON]: LEDs = 0x80
PASS [  ALL_ON]: LEDs = 0xff
PASS [ ALL_OFF]: LEDs = 0x00
PASS [TTERN_AA]: LEDs = 0xaa
PASS [TTERN_55]: LEDs = 0x55
PASS [SW_COMBO]: LEDs = 0xa5
==============================
TOTAL: 7 PASS, 0 FAIL
>>> ALL TESTS PASSED <<<
==============================

  Quick Start
Step 1 — Vivado Project Setup

Create RTL project → select part xc7z020clg484-1 or board ZedBoard
Add design sources: spi_slave.v, led_controller.v, top.v
Set top.v as top module
Add constraints: zedboard_constraints.xdc
Add simulation source: testbench.v

Step 2 — Simulate
Flow Navigator → Simulation → Run Simulation → Run Behavioral Simulation
Tcl Console: run all
All 7 tests must show PASS.
Step 3 — Synthesize → Implement → Bitstream
Flow Navigator → Run Synthesis → Run Implementation → Generate Bitstream
Step 4 — Program ZedBoard
Open Hardware Manager → Open Target → Auto Connect
Right-click xc7z020 → Program Device → select top.bit → Program
Step 5 — ESP32 Firmware

Install WebSockets library by Markus Sattler in Arduino IDE
Edit spi_master.ino — set your WiFi SSID and password
Upload to ESP32 → note the IP address from Serial Monitor

Step 6 — Open Web Dashboard

Open web/index.html in browser (Chrome/Firefox)
Enter ESP32 IP address → click Connect
Click any switch → ZedBoard LED lights up ✓


  Future Improvements

 Full-duplex SPI — read ZedBoard switch states back to browser
 CPOL & CPHA configurable modes
 FSM-based multi-byte packet controller
 OLED display integration via I2C
 Sensor monitoring dashboard
 FIFO buffering support
 FPGA protocol analyzer
 Mobile-responsive web dashboard


  Learning Outcomes

SPI protocol implementation at hardware level
Synchronous digital design with metastability handling
Double-flop synchronizer design pattern
FPGA I/O constraints and pin mapping
ESP32 WebSocket server programming
Real-time browser-hardware communication
Hardware debugging and simulation methodology


  Technologies Used
LayerTechnologyHardware DescriptionVerilog HDLFPGA ToolchainXilinx Vivado 2025.2FPGA BoardDigilent ZedBoard (Zynq XC7Z020)MicrocontrollerESP32 (Arduino framework)Wireless ProtocolWebSocket (port 81)FrontendHTML5 / CSS3 / JavaScriptSimulationVivado XSimDebuggingLogic Analyzer / Serial Monitor

  License
This project is open-source and available under the MIT License.

  Author
Karthikeya Rao
VLSI Design & Embedded Systems Enthusiast
