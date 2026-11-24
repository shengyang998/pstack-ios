# Test an external device without hardware

Use this layer for the wire adapter. For feature behavior, start with [interface contract tests](interface-contracts.md). Place the test peer outside the app process. Keep the app's real session, framing, parser, decoder, state management and UI in the test path wherever possible. Use loopback, a local Unix socket, or an injected byte transport in place of the physical link. Select this peer through a test launch configuration. Keep its endpoints explicit and disable fallback to a discovered physical device or live service in that configuration.

## Model one device with independent links

| Boundary | Contract to capture from the device spec or a sanitized recording |
| --- | --- |
| Observable device behavior | Advertised capabilities, reported settings, frame sequences and which public values the contract preserves across reconnect. |
| Video, device → app | Framing and codec, timestamp clock, keyframes, format changes, loss behavior and queue policy. Feed small legal encoded clips through the production parser/decoder when decoder correctness matters. |
| Control, both directions | Commands, response correlation, events that arrive without a request, retry rules and whether the peer can deduplicate or report prior results. |
| Test driver | Choose a seed, advance the clock, delay or drop selected messages, cut one link and inspect the device journal. The app cannot query this private interface. |

A setting accepted, a setting applied and the first visible frame reflecting it can occur at three different times. Describe the expected order or allowed window. Associate them using fields the real protocol supplies; when it supplies none, use a recognizable pattern in the frames and a test-side event log. Do not add production acknowledgments, identifiers or delivery guarantees just to make a test pass.

## Runnable two-channel example

[scripts/virtual-camera](../scripts/virtual-camera) is a desktop camera peer with no physical output. It listens on two randomly assigned **loopback-only** TCP ports. Its first stdout line gives the host and port numbers. A harness keeps its stdin open, writes one JSON driver operation per line and reads one JSON report per operation. EOF or `{"op":"quit"}` ends the process. Python 3.9+ is sufficient.

- **Control socket.** Send newline-delimited JSON, e.g. `{"id":"r1","op":"setMode","mode":"mono"}` or `{"id":"q2","op":"get"}`. For this example, the device applies each set request ID once across link reconnects, and rejects reuse for a different setting. `notify` produces an unsolicited state event on this socket.
- **Video socket.** Read an 8-byte big-endian header (32-bit frame number and PNG byte count), then exactly that many bytes. One manual `tick` produces one frame. Color/monochrome is encoded in the **pixels**. A stopped video consumer can discard frames independently of control traffic.
- **Test driver.** Available operations are `inspect`, `tick`, `dropNextAck`, `cutControl`, `pauseVideo`, `resumeVideo`, `notify` and `quit`. The inspection reply includes connected client counts. Wait for the required connections before advancing the clock. One process represents one device boot.
- **Try the experiment.** In the public repo run `python3 -m unittest discover -s tests -p 'test_virtual_camera.py' -v`. The test opens both sockets, decodes pixels independently and checks device-side effects as well as client observations. For an iOS app, inject the two addresses into the simulator launch configuration and assert against the actual rendered view or decoded frame.

The sample framing and PNGs make cross-channel behavior reproducible. Replace them with the actual wire contract and encoded fixtures for product integration. For USB or platform-owned discovery that cannot run in Simulator, substitute at the lowest available byte/message boundary and state which stack layers are outside the test.

## First scenarios

| Fault | Independent observations |
| --- | --- |
| Setting applied, acknowledgment lost while frames continue | Device applied-count, first matching decoded frame, app's pending state, state readback and retry count after reconnect. |
| Video stalls while control remains connected | Control round trip still completes; UI shows stale video after its deadline. Resume with a decodable frame and confirm recovery. |
| Old frames or events cross a reconnect | Delay a message from session A until session B is active. Check the target's documented ordering and that the app does not roll back to the old state. |
| Decode work cannot keep up | Drive a bounded burst against the project's real queue. Check queue depth, frame-age policy and control responsiveness. A virtual clock tests ordering; a sustained real-time load run measures latency and resource use. |

For printing, the same pattern uses a local IPP peer with a private spool directory. Observe job count, requested copies and rendered content there. For payments, messages or actuators, use an isolated sandbox or emulator that records effects. Run ordinary regression scenarios here. Reserve a separately requested hardware pass for properties such as radio interference, firmware behavior, color on paper, actuator motion or hardware decoder throughput.

## Choose the behavior to simulate

Build the peer from observable request/response and event traces. Its internal bookkeeping is an implementation choice for the test fixture. A trace can simply emit a prescribed response and the next video frame. When two conditions have identical public behavior for the scenarios under test they need no separate representation. If the contract permits more than one event ordering, exercise each relevant ordering. Unsupported operations should fail clearly. Do not require access to the firmware state machine.

Use the fixture's private control channel to schedule scenarios. For application correctness, assert the actual calls, received events and user-visible outcomes. Inspecting an emulator counter in its own self-test checks the emulator's retry contract; it provides no evidence about a physical device's internals.
