#!/usr/bin/env python3
import socket
import select
import struct
import sys
import threading
import argparse
from powerhub.receiver import ShellPacket, T_DICT

parser = argparse.ArgumentParser(
    description="Interact with PowerHub shells"
)

parser.add_argument(
    "ID",
    type=str,
    help="ID of the shell you want to interact with"
)

args = parser.parse_args()


sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('127.0.0.1', 18157)
sock.connect(server_address)

sock.send(args.ID.encode())

write_socks = []


def listen():
    global write_socks
    while True:
        r, _, _ = select.select([sock], [], [])
        for s in r:
            try:
                header = s.recv(6)
            except Exception as e:
                print(str(e))
                return
            if not header:
                return
            packet_type, packet_length = struct.unpack('>HI', header)
            body = s.recv(packet_length)
            p = ShellPacket(packet_type, body)
            if p["data"]:
                print(p.shell_string(), end='')
                sys.stdout.flush()


threading.Thread(
    target=listen,
    daemon=True,
).start()

while True:
    try:
        command = input()
        json = {
            "msg_type": "COMMAND",
            "data": command,
        }
        p = ShellPacket(T_DICT, json)
        _, w, _ = select.select([], [sock], [])
        w[0].send(p.serialize())
    except Exception as e:
        print(str(e))
        break
