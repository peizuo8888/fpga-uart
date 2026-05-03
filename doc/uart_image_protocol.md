# UART Image Transfer Protocol

## 1. Purpose

This document defines the UART packet protocol used for FPGA image transfer.

The first target is to transfer a 128x128 8-bit grayscale RAW image from PC to FPGA.

The FPGA stores the image data into BRAM and sends the image data back to PC for verification.

The verification target is:

```text
input.raw == output.raw
```

---

## 2. UART Format

```text
Baud rate : 115200
Data bits : 8
Parity    : None
Stop bits : 1
Format    : 8N1
```

Each UART byte uses 10 bits on the wire:

```text
1 start bit + 8 data bits + 1 stop bit = 10 bits
```

---

## 3. Image Format

The first version uses grayscale RAW image data.

```text
Width  : 128
Height : 128
Format : 8-bit grayscale RAW
Size   : 16384 bytes
```

RAW data layout:

```text
bram[0]     = pixel[0][0]
bram[1]     = pixel[0][1]
bram[2]     = pixel[0][2]
...
bram[127]   = pixel[0][127]
bram[128]   = pixel[1][0]
...
bram[16383] = pixel[127][127]
```

One pixel is one byte.

```text
1 pixel = 8 bits = 1 byte
```

---

## 4. Packet Format

All UART image transfer data uses packet format.

```text
Byte 0      : 0xAA
Byte 1      : 0x55
Byte 2      : CMD
Byte 3      : SEQ_L
Byte 4      : SEQ_H
Byte 5      : LEN_L
Byte 6      : LEN_H
Byte 7~N    : PAYLOAD
Last byte   : CHECKSUM
```

---

## 5. Field Description

### Header

```text
0xAA 0x55
```

The header is used to identify the start of a packet.

### CMD

CMD defines the packet type.

### SEQ

SEQ is the packet sequence number.

```text
SEQ = {SEQ_H, SEQ_L}
```

Little-endian order is used:

```text
SEQ_L first
SEQ_H second
```

### LEN

LEN is the payload length in bytes.

```text
LEN = {LEN_H, LEN_L}
```

Little-endian order is used:

```text
LEN_L first
LEN_H second
```

### PAYLOAD

PAYLOAD contains command-specific data.

### CHECKSUM

Checksum is used to detect packet errors.

```text
checksum = sum(CMD, SEQ_L, SEQ_H, LEN_L, LEN_H, PAYLOAD) & 0xFF
```

The header bytes are not included in checksum.

---

## 6. Command List

```text
0x01 : START_IMAGE
0x02 : IMAGE_DATA
0x03 : END_IMAGE
0x04 : READBACK_REQUEST
0x05 : IMAGE_DATA_BACK
0x80 : ACK
0x81 : NACK
```

---

## 7. START_IMAGE Packet

### Direction

```text
PC → FPGA
```

### Purpose

Notify FPGA that a new image transfer is starting.

### CMD

```text
CMD = 0x01
```

### Payload Format

```text
Byte 0 : WIDTH_L
Byte 1 : WIDTH_H
Byte 2 : HEIGHT_L
Byte 3 : HEIGHT_H
Byte 4 : FORMAT
Byte 5 : TOTAL_LEN_0
Byte 6 : TOTAL_LEN_1
Byte 7 : TOTAL_LEN_2
Byte 8 : TOTAL_LEN_3
```

### Format Value

```text
0x01 : 8-bit grayscale RAW
```

### Example for 128x128 Grayscale RAW

```text
WIDTH     = 128
HEIGHT    = 128
FORMAT    = 0x01
TOTAL_LEN = 16384
```

Payload:

```text
80 00 80 00 01 00 40 00 00
```

Because:

```text
128   = 0x0080
16384 = 0x00004000
```

---

## 8. IMAGE_DATA Packet

### Direction

```text
PC → FPGA
```

### Purpose

Send image pixel data to FPGA.

### CMD

```text
CMD = 0x02
```

### Payload Size

The first version uses:

```text
PAYLOAD_SIZE = 128 bytes
```

### Total Packet Count

For a 128x128 grayscale image:

```text
Image size    = 16384 bytes
Payload size  = 128 bytes
Packet count  = 128 packets
```

### BRAM Write Address

For each IMAGE_DATA packet:

```text
base_addr = seq * 128
bram_addr = base_addr + payload_index
```

Example:

```text
SEQ = 0
payload[0]   → bram[0]
payload[1]   → bram[1]
...
payload[127] → bram[127]
```

```text
SEQ = 1
payload[0]   → bram[128]
payload[1]   → bram[129]
...
payload[127] → bram[255]
```

---

## 9. END_IMAGE Packet

### Direction

```text
PC → FPGA
```

### Purpose

Notify FPGA that image transfer is complete.

### CMD

```text
CMD = 0x03
```

### Payload

```text
No payload
LEN = 0
```

After receiving END_IMAGE, FPGA should check whether the expected number of bytes has been received.

---

## 10. READBACK_REQUEST Packet

### Direction

```text
PC → FPGA
```

### Purpose

Request FPGA to send the stored image data back to PC.

### CMD

```text
CMD = 0x04
```

### Payload

```text
No payload
LEN = 0
```

After receiving READBACK_REQUEST, FPGA reads image data from BRAM and sends IMAGE_DATA_BACK packets to PC.

---

## 11. IMAGE_DATA_BACK Packet

### Direction

```text
FPGA → PC
```

### Purpose

Send BRAM image data back to PC.

### CMD

```text
CMD = 0x05
```

### Payload Size

```text
PAYLOAD_SIZE = 128 bytes
```

### Sequence

The sequence number follows the same rule as IMAGE_DATA.

```text
SEQ = 0   → image bytes 0 to 127
SEQ = 1   → image bytes 128 to 255
...
SEQ = 127 → image bytes 16256 to 16383
```

---

## 12. ACK Packet

### Direction

```text
FPGA → PC
```

### Purpose

Notify PC that a packet was received correctly.

### CMD

```text
CMD = 0x80
```

### Payload Format

```text
Byte 0 : STATUS
```

### STATUS

```text
0x00 : OK
```

Example:

```text
AA 55 80 SEQ_L SEQ_H 01 00 00 CHECKSUM
```

---

## 13. NACK Packet

### Direction

```text
FPGA → PC
```

### Purpose

Notify PC that a packet error occurred.

### CMD

```text
CMD = 0x81
```

### Payload Format

```text
Byte 0 : ERROR_CODE
```

### ERROR_CODE

```text
0x01 : Checksum error
0x02 : Length error
0x03 : Sequence error
0x04 : Unsupported command
0x05 : Image size error
```

Example:

```text
AA 55 81 SEQ_L SEQ_H 01 00 ERROR_CODE CHECKSUM
```

---

## 14. Transfer Flow

### Image Send Flow

```text
PC sends START_IMAGE
FPGA replies ACK

PC sends IMAGE_DATA seq=0
FPGA writes payload to BRAM
FPGA replies ACK

PC sends IMAGE_DATA seq=1
FPGA writes payload to BRAM
FPGA replies ACK

...

PC sends IMAGE_DATA seq=127
FPGA writes payload to BRAM
FPGA replies ACK

PC sends END_IMAGE
FPGA replies ACK
```

---

### Image Readback Flow

```text
PC sends READBACK_REQUEST
FPGA replies ACK

FPGA sends IMAGE_DATA_BACK seq=0
PC receives payload

FPGA sends IMAGE_DATA_BACK seq=1
PC receives payload

...

FPGA sends IMAGE_DATA_BACK seq=127
PC receives payload

PC writes output.raw
PC verifies input.raw == output.raw
```

---

## 15. Checksum Example

For a packet body:

```text
CMD     = 0x02
SEQ_L   = 0x00
SEQ_H   = 0x00
LEN_L   = 0x80
LEN_H   = 0x00
PAYLOAD = 128 bytes
```

Checksum calculation:

```text
checksum = sum(CMD, SEQ_L, SEQ_H, LEN_L, LEN_H, PAYLOAD) & 0xFF
```

The packet header `0xAA 0x55` is not included.

---

## 16. FPGA Module Responsibility

```text
uart_rx.v
    Receive UART byte

fifo_sync.v
    Buffer received UART bytes

packet_rx_fsm.v
    Parse packet header, command, sequence, length, payload, checksum

image_bram_ctrl.v
    Write image payload data into BRAM
    Read image data from BRAM during readback

bram_1p.v
    Store image data

packet_tx_fsm.v
    Send ACK, NACK, and IMAGE_DATA_BACK packets

uart_tx.v
    Transmit UART byte
```

---

## 17. First Version Limitation

The first version only supports:

```text
Image size : 128x128
Format     : 8-bit grayscale RAW
Baud rate  : 115200
Payload    : 128 bytes per packet
```

The first version does not support:

```text
PNG decoding
JPG decoding
RGB image
Variable image size
Compression
Real-time video
```

---

## 18. Verification Rule

The transfer is considered successful only when:

```text
input.raw == output.raw
```

Python verification result should be:

```text
PASS
```

If the files are different, the result should be:

```text
FAIL
```