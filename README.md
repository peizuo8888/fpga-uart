# FPGA UART Project

## Project Goal

This project implements a basic UART communication system on FPGA.

Current target:

- UART TX
- UART RX
- UART Echo
- Python UART Echo Test

## Hardware

- FPGA Board: PYNQ-Z2
- UART Level: 3.3V TTL
- Baud Rate: 115200
- Format: 8N1
- System Clock: 125 MHz

## Project Structure

```text
rtl/      Verilog RTL source files
sim/      Verilog testbenches
python/   Python UART test scripts
constr/   FPGA constraint files
doc/      Development notes
```

## Development Milestones

- [x] UART TX simulation
- [x] UART TX board test
- [ ] UART RX simulation
- [ ] UART Echo simulation
- [ ] UART Echo board test
- [ ] Python echo test

## UART Format

```text
Start bit : 1 bit, logic 0
Data bits : 8 bits, LSB first
Parity    : None
Stop bit  : 1 bit, logic 1
Baud rate : 115200
```

## Test Goal

The goal of this project is to implement UART echo.

Expected behavior:

```text
PC send : 0x41
FPGA RX : 0x41
FPGA TX : 0x41
PC recv : 0x41
```

`0x41` is ASCII character `A`.

That means:

```text
PC sends A to FPGA.
FPGA receives A.
FPGA sends A back to PC.
PC receives A.
```

## Current Status

UART TX completed.

Done:

- Implemented UART TX module
- Wrote UART TX testbench
- Passed UART TX simulation
- Verified UART TX on FPGA board
- PC successfully received ASCII `A`

Next step:

- Implement UART RX module
- Write UART RX testbench
