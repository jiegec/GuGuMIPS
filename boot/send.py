#!/usr/bin/env python3

import sys
import os
import struct
import serial
import select

n = 1024
timeout = 0.01

if len(sys.argv) != 3:
    print('Usage: send.py file tty')
    sys.exit()

out = serial.Serial(sys.argv[2], 115200, timeout=timeout)

size = os.path.getsize(sys.argv[1])
out.write(struct.pack('>I', size))
with open(sys.argv[1], 'rb') as f:
    data = f.read()
    for i in range(0, len(data), n):
        out.write(data[i:i+n])
        print('.', end='', flush=True)

out.close()
os.execlp('screen', 'screen', sys.argv[2], '115200')
