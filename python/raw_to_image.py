from pathlib import Path
from PIL import Image


IMG_W = 128
IMG_H = 128
CHANNELS = 3

INPUT_RAW = Path("images/input_rgb888.raw")
OUTPUT_IMAGE = Path("images/roundtrip_rgb888.jpg")


def main():
    if not INPUT_RAW.exists():
        raise FileNotFoundError(f"RAW file not found: {INPUT_RAW}")

    raw_data = INPUT_RAW.read_bytes()

    expected_size = IMG_W * IMG_H * CHANNELS

    if len(raw_data) != expected_size:
        raise RuntimeError(
            f"RAW size mismatch: got {len(raw_data)}, expected {expected_size}"
        )

    img = Image.frombytes(
        mode="RGB",
        size=(IMG_W, IMG_H),
        data=raw_data
    )

    OUTPUT_IMAGE.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUTPUT_IMAGE)

    print("RGB888 RAW to image conversion done")
    print(f"Input RAW    : {INPUT_RAW}")
    print(f"Output image : {OUTPUT_IMAGE}")
    print(f"Image size   : {IMG_W} x {IMG_H}")
    print("Format       : RGB888")
    print(f"RAW bytes    : {len(raw_data)}")


if __name__ == "__main__":
    main()