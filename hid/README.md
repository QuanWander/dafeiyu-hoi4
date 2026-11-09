# DaFeiYu HOI4 HID bridge

Target: remove the last human step (`run dfy_orders.txt`) without installing a kernel driver.

## Hardware

Use a board with **native USB HID** support:

- Raspberry Pi Pico / Pico 2 (CircuitPython)
- Arduino Leonardo / Micro / Pro Micro (ATmega32u4)

An Arduino Uno/Nano cannot act as a USB keyboard.

## How it works

```
app/agent.ps1 writes dfy_orders.txt
        │
        ▼
app/hid.ps1 sends "RUN" over USB serial
        │
        ▼
board acts as a real USB keyboard:
  ~  →  run dfy_orders.txt  →  Enter  →  ~
```

The game sees a hardware keyboard, so it is not the blocked `SendInput` path.
No DLL injection, no driver, no memory writing.

## Pico (CircuitPython)

1. Flash CircuitPython.
2. Copy `adafruit_hid` into `lib/`.
3. Copy `pico/code.py` to `CIRCUITPY/code.py`.
4. Plug the Pico into the PC. A serial port appears.
5. App auto-detects ports containing `Pico`/`USB Serial`; otherwise set `hid_port` in `%LOCALAPPDATA%\DaFeiYuHOI4\config.json`.

## Leonardo / Pro Micro

1. Open `leonardo/leonardo_hid.ino` in Arduino IDE.
2. Select the board and upload.
3. A serial port appears. App auto-detects `Arduino`/`Leonardo`.

## Protocol

App → board:

```text
PING
RUN
```

Board → app:

```text
PONG
OK
ERR
```

Baud: `115200`.

## Safety

- Board only types `~`, `run dfy_orders.txt`, Enter, `~`.
- No arbitrary text from chat is sent to the keyboard.
- If the board is absent or the port is wrong, app falls back to manual `run`.
- Unplugging the board does not affect the game or save.
