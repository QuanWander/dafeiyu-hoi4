# DaFeiYu HOI4 HID bridge for Raspberry Pi Pico (CircuitPython)
# Requires: adafruit_hid in /lib
import time
import usb_hid
import usb_cdc
from adafruit_hid.keyboard import Keyboard
from adafruit_hid.keycode import Keycode

kbd = Keyboard(usb_hid.devices)
ser = usb_cdc.console

def open_console():
    # Shift + ` => ~
    kbd.press(Keycode.LEFT_SHIFT, Keycode.GRAVE_ACCENT)
    time.sleep(0.08)
    kbd.release_all()
    time.sleep(0.35)

def type_command():
    kbd.write("run dfy_orders.txt")
    time.sleep(0.12)
    kbd.send(Keycode.ENTER)
    time.sleep(0.45)

def close_console():
    kbd.press(Keycode.GRAVE_ACCENT)
    time.sleep(0.08)
    kbd.release_all()

while True:
    if ser is not None and ser.in_waiting:
        line = ser.readline().decode("utf-8", "ignore").strip().upper()
        if line == "PING":
            ser.write(b"PONG\n")
        elif line == "RUN":
            try:
                open_console()
                type_command()
                close_console()
                ser.write(b"OK\n")
            except Exception:
                ser.write(b"ERR\n")
