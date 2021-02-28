#!/usr/bin/env python3

import socket
import sys

fileName = sys.argv[1]

s = socket.socket()
s.connect(("localhost", 55555))
filetosend = open(fileName, "rb")
data = filetosend.read(1024)
s.send(("download:"+fileName+"\n").encode())
while data:
    print("Sending...")
    s.send(data)
    data = filetosend.read(1024)
filetosend.close()
print("Done Sending.")
s.shutdown(2)
s.close()

