#!/usr/bin/python3

import os
import sys
import serial
import time
import serial.tools.list_ports
import csv
import random

# Edit UART device if necessary
DEV_UART = '/dev/ttyUSB1'

# Sensor trace length
SENS_LEN = 56

# Number of traces
NUM_TRACES = 100000

# Configure UART port for Windows or Linux
if ('-win') in sys.argv:
    plist = list(serial.tools.list_ports.comports())
    if len(plist) <= 0:
        print("The Serial port can't be found!")
        sys.exit(1)
    else:
        plist_0 = list(plist[0])
        DEV_UART = plist_0[0]

BAUD_RATE = 1000000

ser = serial.Serial(
    port=DEV_UART,
    baudrate=BAUD_RATE,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS,
    timeout=1
)

# Ensure result folder exists and is empty
RESULT_DIR = "result"
if not os.path.exists(RESULT_DIR):
    os.makedirs(RESULT_DIR)
else:
    for file in os.listdir(RESULT_DIR):
        os.remove(os.path.join(RESULT_DIR, file))

# Open CSV files in the result folder
msgs_file_path = os.path.join(RESULT_DIR, "msgs.csv")
traces_file_path = os.path.join(RESULT_DIR, "traces.csv")

with open(msgs_file_path, mode="w", newline="") as msgs_file, open(traces_file_path, mode="w", newline="") as traces_file:
    msgs_writer = csv.writer(msgs_file)
    traces_writer = csv.writer(traces_file)

    # Write headers
    msgs_writer.writerow(["Plaintext", "Ciphertext"])
    traces_writer.writerow([f"Sensor {i+1}" for i in range(SENS_LEN)])

    # Generate and log data for NUM_TRACES traces
    for i in range(NUM_TRACES):
        # Reset the FPGA
        time.sleep(0.001)
        ser.setRTS(False)
        time.sleep(0.001)
        ser.setRTS(True)
        time.sleep(0.001)

        # Consume leftover bytes in the UART buffer
        ser.read(32).decode('utf8', 'ignore')

        # Generate a random 128-bit plaintext
        plaintext = ''.join(random.choices('0123456789abcdef', k=32))

        # Send the plaintext to the FPGA
        ser.write(bytes.fromhex(plaintext))

        # Receive the 16-byte ciphertext
        cipher = ser.read(16)

        # Receive the 56-byte sensor values
        sense = ser.read(SENS_LEN)

        if len(cipher) == 16 and len(sense) == SENS_LEN:
            ciphertext = cipher.hex()
            sensor_values = list(map(int, sense))

            # Log data to CSV files
            msgs_writer.writerow([plaintext, ciphertext])
            traces_writer.writerow(sensor_values)

            print(f"Logged plaintext and sensor values. Trace {i + 1}/{NUM_TRACES}")
        else:
            print(f"Error receiving data on trace {i + 1}.")
            break

print("Finished generating and logging traces.")
