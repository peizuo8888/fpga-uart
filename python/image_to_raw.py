from pathlib import Path
from PIL import Image


IMG_W = 128
IMG_H = 128

INPUT_IMAGE = Path("images/input.jpg")
OUTPUT_RAW = Path("images/input_rgb888.raw")
OUTPUT_PREVIEW = Path("images/input_rgb888_preview.jpg")


def main():
    if not INPUT_IMAGE.exists():
        raise FileNotFoundError(f"Input image not found: {INPUT_IMAGE}")

    OUTPUT_RAW.parent.mkdir(parents=True, exist_ok=True)

    # Open image file
    img = Image.open(INPUT_IMAGE)

    # Convert JPG/PNG image to RGB888
    img = img.convert("RGB")

    # Resize to fixed FPGA image size
    img = img.resize((IMG_W, IMG_H))

    # RGB888 raw data:
    # pixel0: R G B
    # pixel1: R G B
    # ...
    raw_data = img.tobytes()

    expected_size = IMG_W * IMG_H * 3

    if len(raw_data) != expected_size:
        raise RuntimeError(
            f"RAW size mismatch: got {len(raw_data)}, expected {expected_size}"
        )

    with open(OUTPUT_RAW, "wb") as f:
        f.write(raw_data)

    img.save(OUTPUT_PREVIEW)

    print("RGB888 image to RAW conversion done")
    print(f"Input image : {INPUT_IMAGE}")
    print(f"Output RAW  : {OUTPUT_RAW}")
    print(f"Preview PNG : {OUTPUT_PREVIEW}")
    print(f"Image size  : {IMG_W} x {IMG_H}")
    print("Format      : RGB888")
    print(f"RAW bytes   : {len(raw_data)}")


if __name__ == "__main__":
    main()