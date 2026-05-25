# FPGA SPI Web Dashboard

> Control ZedBoard LEDs in real time from a browser — Browser → WebSocket → ESP32 → SPI → FPGA → LED

![Simulation](https://img.shields.io/badge/Simulation-7%2F7%20PASS-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)
![Board](https://img.shields.io/badge/Board-ZedBoard-red)
![Language](https://img.shields.io/badge/HDL-Verilog-blueviolet)

---

## What This Project Does

Click a switch on a webpage → LED lights up on a real FPGA board.

The signal travels like this:

```
Browser  →  WebSocket (WiFi)  →  ESP32  →  SPI  →  FPGA  →  LED ON
```

Total delay: **under 10ms** from click to LED glow.

---

## Repository Structure

```
FPGA_SPI_Web_Dashboard/
├── rtl/
│   ├── spi_slave.v            SPI receiver (double-flop synchronizer)
│   ├── led_controller.v       LED output register
│   └── top.v                  Top-level wrapper
├── sim/
│   └── testbench.v            Self-checking testbench — 7 test cases
├── constraints/
│   └── zedboard_constraints.xdc   Pin and timing constraints
├── esp32/
│   └── spi_master.ino         Arduino firmware (WebSocket + SPI master)
├── web/
│   └── index.html             Web dashboard (open directly in browser)
└── README.md
```

---

## Hardware

| Component | Details |
|---|---|
| FPGA Board | Digilent ZedBoard — Zynq XC7Z020 |
| Microcontroller | ESP32 DevKit (any WROOM variant) |
| Jumper Wires | 5× Male-to-Male |
| USB Cables | 2× (one per board) |
| Network | WiFi 2.4GHz — ESP32 and PC on same network |

---

## Wiring

```
ESP32 GPIO 18  ──────→  ZedBoard PMOD JA Pin 1   (SCLK)
ESP32 GPIO 23  ──────→  ZedBoard PMOD JA Pin 2   (MOSI)
ESP32 GPIO 19  ←──────  ZedBoard PMOD JA Pin 3   (MISO)
ESP32 GPIO 5   ──────→  ZedBoard PMOD JA Pin 4   (CS)
ESP32 GND      ──────→  ZedBoard PMOD JA GND     (GND)
```

> Both boards are 3.3V logic. Do NOT connect 5V to PMOD pins. Shared GND is mandatory.

---

## SPI Protocol

| Setting | Value |
|---|---|
| Mode | SPI Mode 0 (CPOL=0, CPHA=0) |
| Speed | 1 MHz |
| Bit Order | MSB First |
| Packet Size | 8 bits — 1 byte |
| CS Polarity | Active LOW |

Each bit in the byte maps directly to one LED:

| Byte sent | Binary | LEDs ON |
|---|---|---|
| `0x01` | `00000001` | LD0 only |
| `0x80` | `10000000` | LD7 only |
| `0xFF` | `11111111` | All 8 LEDs |
| `0x00` | `00000000` | All OFF |
| `0xAA` | `10101010` | LD1, LD3, LD5, LD7 |

---

## Core Verilog Logic

**Shift register in spi_slave.v** — assembles incoming bits into a byte:

```verilog
// Detect rising edge of SCLK
wire sclk_rising = (sclk_r1 && !sclk_r2);

// Shift in one bit per clock edge, MSB first
always @(posedge clk) begin
    if (!cs_n && sclk_rising) begin
        shift_reg <= {shift_reg[6:0], mosi_r2};
        bit_count <= bit_count + 1;
        if (bit_count == 3'd7) begin
            rx_data    <= {shift_reg[6:0], mosi_r2};
            data_ready <= 1'b1;
        end
    end
end
```

**LED controller in led_controller.v** — latches byte to LED outputs:

```verilog
always @(posedge clk) begin
    if (data_ready)
        leds <= rx_data;
end
```

---

## Simulation Results

Run in **Vivado XSim 2025.2** — type `run all` in the Tcl Console:

```
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
```

---

## How to Run This Project

**Step 1 — Vivado Setup**

- Create new RTL project, select part `xc7z020clg484-1` or board ZedBoard
- Add design sources: `spi_slave.v`, `led_controller.v`, `top.v`
- Set `top.v` as top module
- Add constraints: `zedboard_constraints.xdc`
- Add simulation source: `testbench.v`

**Step 2 — Simulate**

- Flow Navigator → Simulation → Run Behavioral Simulation
- In Tcl Console type: `run all`
- All 7 tests must show PASS

**Step 3 — Build**

- Run Synthesis → Run Implementation → Generate Bitstream

**Step 4 — Program the FPGA**

- Open Hardware Manager → Auto Connect
- Right-click xc7z020 → Program Device → select `top.bit`

**Step 5 — ESP32 Firmware**

- Install the **WebSockets** library by Markus Sattler in Arduino IDE
- Open `esp32/spi_master.ino`
- Change WiFi SSID and password to your network
- Upload to ESP32
- Open Serial Monitor at 115200 baud — note the IP address shown

**Step 6 — Web Dashboard**

- Open `web/index.html` in Chrome or Firefox
- Enter the ESP32 IP address and click Connect
- Click any switch — the matching LED lights up on ZedBoard ✓

---

## Technologies Used

| Layer | Tool / Language |
|---|---|
| Hardware Description | Verilog HDL |
| FPGA Toolchain | Xilinx Vivado 2025.2 |
| FPGA Board | Digilent ZedBoard (Zynq XC7Z020) |
| Microcontroller | ESP32 (Arduino framework) |
| Wireless Protocol | WebSocket on port 81 |
| Frontend | HTML5, CSS3, JavaScript |
| Simulation | Vivado XSim |

---

## Future Improvements

- [ ] Full-duplex SPI — read ZedBoard switch states back to browser
- [ ] CPOL and CPHA configurable modes
- [ ] Multi-byte SPI packet support
- [ ] FSM-based advanced controller
- [ ] OLED display integration
- [ ] FIFO buffering
- [ ] Sensor monitoring dashboard
- [ ] Mobile-responsive web UI

---

## Learning Outcomes

- SPI protocol implementation at hardware level
- Synchronous digital design and clock domain crossing
- Double-flop synchronizer for metastability prevention
- FPGA I/O constraints and pin mapping in XDC
- ESP32 WebSocket server programming
- Real-time browser to hardware communication

---

## License

MIT License — free to use, modify, and distribute.

---

## Author

**Karthikeya Rao**  
VLSI Design & Embedded Systems Enthusiast

Feel free to fork, improve, and raise pull requests.  
If this project helped you, please give it a ⭐
