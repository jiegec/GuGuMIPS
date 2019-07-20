#!/usr/bin/env python3

import sys
import os
import struct

size = os.path.getsize(sys.argv[1])
os.write(1, struct.pack('>I', size))
with open(sys.argv[1], 'rb') as f:
    os.write(1, f.read())
