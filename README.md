# FPGA UART Project

## Project Goal

This project implements a basic UART communication system on FPGA.

The first version implements:

- UART TX
- UART RX
- UART Echo
- Python UART Echo Test

The next target is:

- UART Image Transfer

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
doc/      Development notes and protocol documents
images/   Input and output image files
```

## Current Features

- UART TX
- UART RX
- UART Echo
- Python UART Echo Test
- PYNQ-Z2 board verification

## Development Milestones

- [x] UART TX simulation
- [x] UART TX board test
- [x] UART RX simulation
- [x] UART Echo simulation
- [x] UART Echo board test
- [x] Python echo test

## UART Format

```text
Start bit : 1 bit, logic 0
Data bits : 8 bits, LSB first
Parity    : None
Stop bit  : 1 bit, logic 1
Baud rate : 115200
```

## UART Echo Test Goal

The goal of the first version is to implement UART echo.

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

## UART Echo Status

UART Echo is completed.

Done:

- Implemented UART TX module
- Wrote UART TX testbench
- Passed UART TX simulation
- Verified UART TX on FPGA board
- Implemented UART RX module
- Wrote UART RX testbench
- Passed UART RX simulation
- Integrated UART Echo top module
- Passed UART Echo simulation
- Verified UART Echo on FPGA board
- Verified UART Echo with Python serial test

Result:

```text
PC send : 0x41
PC recv : 0x41
Result  : PASS
```

## Next Target: UART Image Transfer

The next goal is to send an image from PC to FPGA through UART.

The first image transfer version will use a simple RAW image format instead of PNG or JPG.

```text
PC image
→ convert to 128x128 grayscale RAW
→ send to FPGA through UART packets
→ write image data into BRAM
→ read back from FPGA
→ verify input.raw == output.raw
```

## Image Transfer Milestones

- [x] Python image to RAW conversion
- [x] Python RAW to image conversion
- [ ] UART packet protocol
- [ ] RX FIFO
- [ ] Packet RX FSM
- [ ] BRAM module
- [ ] Image BRAM write controller
- [ ] ACK / NACK response
- [ ] Image readback
- [ ] Python RAW verification
- [ ] input.raw == output.raw

## Image Format

The first image transfer version uses 8-bit grayscale RAW data.

```text
Width  : 128
Height : 128
Format : 8-bit grayscale RAW
Size   : 16384 bytes
```

One pixel is one byte.

```text
1 pixel = 1 byte
128 x 128 = 16384 bytes
```

## Image Transfer Flow

```text
PC Python
   ↓
image_to_raw.py
   ↓
send_image.py
   ↓ UART packets
USB-to-UART
   ↓
uart_rx.v
   ↓
fifo_sync.v
   ↓
packet_rx_fsm.v
   ↓
image_bram_ctrl.v
   ↓
bram_1p.v
   ↓
packet_tx_fsm.v
   ↓
uart_tx.v
   ↓
recv_image.py
   ↓
raw_to_image.py
   ↓
verify_image.py
```

## Planned RTL Files

```text
rtl/
├── uart_tx.v
├── uart_rx.v
├── uart_echo_top.v
├── fifo_sync.v
├── bram_1p.v
├── packet_rx_fsm.v
├── packet_tx_fsm.v
├── image_bram_ctrl.v
└── uart_image_top.v
```

## Planned Simulation Files

```text
sim/
├── tb_uart_tx.v
├── tb_uart_rx.v
├── tb_uart_echo.v
├── tb_fifo_sync.v
├── tb_packet_rx_fsm.v
├── tb_packet_tx_fsm.v
├── tb_image_bram_ctrl.v
└── tb_uart_image_top.v
```

## Planned Python Files

```text
python/
├── uart_echo_test.py
├── image_to_raw.py
├── raw_to_image.py
├── send_image.py
├── recv_image.py
└── verify_image.py
```

## Development Versions

```text
v1.0-uart-echo              UART TX / RX / Echo completed
v1.1-uart-packet            UART packet protocol and ACK/NACK
v1.2-uart-image-rx-bram     PC sends RAW image to FPGA BRAM
v1.3-uart-image-readback    FPGA sends BRAM image data back to PC
v1.4-uart-image-verify      Verify input.raw == output.raw
v2.0-uart-image-transfer    Complete UART image transfer
```

## Notes

The first image transfer version uses RAW grayscale data.

PNG and JPG are not used in the first version because they are compressed image formats and require additional decoding logic.

The RAW format is easier to debug because one pixel is equal to one byte.