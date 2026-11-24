import json
from pathlib import Path
import socket
import struct
import subprocess
import sys
import time
import unittest
import zlib

PEER = Path(__file__).resolve().parents[1] / "skills/pstack-ios/scripts/virtual-camera"


class CameraSession(unittest.TestCase):
    def setUp(self):
        self.process = subprocess.Popen([sys.executable, str(PEER)], stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE, text=True)
        self.addCleanup(self.stop)
        self.address = json.loads(self.process.stdout.readline())

    def stop(self):
        self.process.stdin.close()
        try:
            self.process.wait(timeout=4)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()
        self.process.stdout.close()

    def connect(self, channel):
        sock = socket.create_connection((self.address["host"], self.address[channel]), timeout=4)
        self.addCleanup(sock.close)
        stream = sock.makefile("rwb", buffering=0)
        self.addCleanup(stream.close)
        deadline = time.monotonic() + 4
        while not self.drive("inspect")["clients"][channel]:
            if time.monotonic() >= deadline:
                self.fail("Peer did not register client")
        return stream

    def drive(self, op):
        self.process.stdin.write(json.dumps({"op": op}) + "\n")
        self.process.stdin.flush()
        return json.loads(self.process.stdout.readline())

    def send(self, channel, **message):
        channel.write(json.dumps(message).encode() + b"\n")

    def read_exact(self, stream, length):
        data = bytearray()
        while len(data) < length:
            part = stream.read(length - len(data))
            self.assertTrue(part, "Video socket closed mid-frame")
            data.extend(part)
        return data

    def frame(self, channel):
        seq, length = struct.unpack(">II", self.read_exact(channel, 8))
        image = self.read_exact(channel, length)
        self.assertEqual(image[:8], b"\x89PNG\r\n\x1a\n")
        compressed = bytearray()
        offset = 8
        while offset < len(image):
            size, tag = struct.unpack_from(">I4s", image, offset)
            if tag == b"IDAT":
                compressed.extend(image[offset + 8:offset + 8 + size])
            offset += size + 12
        row = zlib.decompress(compressed)
        self.assertEqual(row[0], 0)
        return seq, tuple(row[1:4])

    def test_lost_ack_while_video_continues_then_retry_after_reconnect(self):
        video = self.connect("video")
        control = self.connect("control")
        self.drive("tick")
        seq, pixel = self.frame(video)
        self.assertEqual(seq, 1)
        self.assertGreater(len(set(pixel)), 1)

        self.drive("dropNextAck")
        command = {"id": "request-1", "op": "setMode", "mode": "mono"}
        self.send(control, **command)
        # An ordered readback is a barrier: a stray acknowledgment would be the next message.
        self.send(control, id="barrier", op="get")
        self.assertEqual(json.loads(control.readline())["id"], "barrier")
        self.drive("cutControl")
        self.assertEqual(control.readline(), b"")
        self.drive("tick")
        seq, pixel = self.frame(video)
        self.assertEqual(seq, 2)
        self.assertEqual(len(set(pixel)), 1)

        recovered = self.connect("control")
        self.send(recovered, **command)
        self.assertEqual(json.loads(recovered.readline())["appliedMode"], "mono")
        self.assertEqual(self.drive("inspect")["appliedCount"], 1)
        self.send(recovered, id="request-1", op="setMode", mode="color")
        self.assertIn("error", json.loads(recovered.readline()))

    def test_paused_video_keeps_control_and_unsolicited_events_alive(self):
        video = self.connect("video")
        control = self.connect("control")
        self.drive("pauseVideo")
        self.drive("tick")
        self.send(control, id="query", op="get")
        self.assertEqual(json.loads(control.readline())["sequence"], 1)
        self.drive("notify")
        self.assertEqual(json.loads(control.readline())["event"], "state")
        self.drive("resumeVideo")
        self.drive("tick")
        self.assertEqual(self.frame(video)[0], 2)
