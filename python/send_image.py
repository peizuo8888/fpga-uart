from pathlib import Path


# ============================================================
# Image configuration
# ============================================================
IMG_W = 128
IMG_H = 128
CHANNELS = 3

IMAGE_FORMAT_RGB888 = 0x02

RAW_FILE = Path("images/input_rgb888.raw")
PACKET_FILE = Path("images/input_rgb888_packets.bin")

CHUNK_SIZE = 128


# ============================================================
# Command definition
# ============================================================
CMD_START_IMAGE = 0x01
CMD_IMAGE_DATA = 0x02
CMD_END_IMAGE = 0x03

CMD_ACK = 0x80
CMD_NACK = 0x81


# ============================================================
# Packet helper
# ============================================================
def calc_checksum(data: bytes) -> int:
    """
    Checksum range:
        CMD + SEQ_L + SEQ_H + LEN_L + LEN_H + PAYLOAD

    Header 0xAA 0x55 is not included.
    """
    return sum(data) & 0xFF


def make_packet(cmd: int, seq: int, payload: bytes) -> bytes:
    if not 0 <= cmd <= 0xFF:
        raise ValueError("cmd must be 0~255")

    if not 0 <= seq <= 0xFFFF:
        raise ValueError("seq must be 0~65535")

    if len(payload) > 0xFFFF:
        raise ValueError("payload too large")

    header = bytes([0xAA, 0x55])

    seq_l = seq & 0xFF
    seq_h = (seq >> 8) & 0xFF

    length = len(payload)
    len_l = length & 0xFF
    len_h = (length >> 8) & 0xFF

    body = bytes([
        cmd,
        seq_l,
        seq_h,
        len_l,
        len_h,
    ]) + payload

    checksum = calc_checksum(body)

    return header + body + bytes([checksum])


# ============================================================
# Packet generation
# ============================================================
def make_start_image_payload(total_size: int) -> bytes:
    """
    START_IMAGE payload format:

    Byte 0 : width low
    Byte 1 : width high
    Byte 2 : height low
    Byte 3 : height high
    Byte 4 : format, 0x02 = RGB888
    Byte 5 : total_size[7:0]
    Byte 6 : total_size[15:8]
    Byte 7 : total_size[23:16]
    Byte 8 : total_size[31:24]
    """
    return bytes([
        IMG_W & 0xFF,
        (IMG_W >> 8) & 0xFF,

        IMG_H & 0xFF,
        (IMG_H >> 8) & 0xFF,

        IMAGE_FORMAT_RGB888,

        total_size & 0xFF,
        (total_size >> 8) & 0xFF,
        (total_size >> 16) & 0xFF,
        (total_size >> 24) & 0xFF,
    ])


def build_image_packets(raw_data: bytes) -> list[bytes]:
    packets = []

    total_size = len(raw_data)
    expected_size = IMG_W * IMG_H * CHANNELS

    if total_size != expected_size:
        raise RuntimeError(
            f"RAW size mismatch: got {total_size}, expected {expected_size}"
        )

    # START_IMAGE packet
    start_payload = make_start_image_payload(total_size)
    packets.append(make_packet(CMD_START_IMAGE, 0, start_payload))

    # IMAGE_DATA packets
    seq = 0
    for offset in range(0, total_size, CHUNK_SIZE):
        payload = raw_data[offset:offset + CHUNK_SIZE]
        packets.append(make_packet(CMD_IMAGE_DATA, seq, payload))
        seq += 1

    # END_IMAGE packet
    packets.append(make_packet(CMD_END_IMAGE, seq, b""))

    return packets


def main():
    if not RAW_FILE.exists():
        raise FileNotFoundError(f"RAW file not found: {RAW_FILE}")

    raw_data = RAW_FILE.read_bytes()

    packets = build_image_packets(raw_data)

    PACKET_FILE.parent.mkdir(parents=True, exist_ok=True)

    with open(PACKET_FILE, "wb") as f:
        for pkt in packets:
            f.write(pkt)

    data_packet_count = (len(raw_data) + CHUNK_SIZE - 1) // CHUNK_SIZE

    print("UART image packet generation done")
    print(f"Input RAW          : {RAW_FILE}")
    print(f"Output packet file : {PACKET_FILE}")
    print(f"Image size         : {IMG_W} x {IMG_H}")
    print("Format             : RGB888")
    print(f"RAW bytes          : {len(raw_data)}")
    print(f"Chunk size         : {CHUNK_SIZE}")
    print(f"Image data packets : {data_packet_count}")
    print(f"Total packets      : {len(packets)}")
    print(f"Packet file bytes  : {PACKET_FILE.stat().st_size}")


if __name__ == "__main__":
    main()