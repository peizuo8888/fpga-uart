import serial
import time

PORT = "COM6"
BAUD = 115200

ser = serial.Serial(PORT, BAUD, timeout=1)

tx_data = b"Hello FPGA"

ser.write(tx_data)
time.sleep(0.2)

rx_data = ser.read(len(tx_data))

print("TX:", tx_data)
print("RX:", rx_data)

if rx_data == tx_data:
    print("PASS")
else:
    print("FAIL")

ser.close()