#!/usr/bin/env python3
"""A Bluetooth HID keyboard and mouse that something else can drive.

Demonstration reference for the method described in the repository README.
It registers a HID service, waits for a bonded client to connect, and turns
lines written to a control FIFO into HID reports.

    status            is a client attached?
    type <text>       literal text, case preserved
    key <name>        enter esc tab space backspace up down left right ...
    usage <hex>       any HID usage id, optionally "usage 04 ctrl shift"
    move <dx> <dy>    relative pointer movement, -127..127 per report
    click <button>    left right middle
    scroll <n>        wheel detents, negative scrolls the other way

Requires BlueZ with the `input` and `hostname` plugins disabled, and root,
because the classic HID ports are privileged. See scripts/setup-bridge.sh.

Everything configurable is an environment variable; nothing here is specific
to any particular machine.
"""

import fcntl
import os
import socket
import struct
import sys
import threading
import time

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

# ---------------------------------------------------------------- settings

SERVICE_NAME = os.environ.get("HID_NAME", "ExampleKbdBridge")
FIFO = os.environ.get("HID_FIFO", "/run/hid-bridge/control")
ADAPTER = os.environ.get("HID_ADAPTER", "00:00:00:00:00:00")  # any adapter
KEY_DELAY = float(os.environ.get("HID_KEY_DELAY", "0.012"))

P_CTRL, P_INTR = 17, 19          # L2CAP control and interrupt ports
PROFILE_PATH = "/org/bluez/examplehid"
AGENT_PATH = "/org/bluez/examplehid/agent"
HID_UUID = "00001124-0000-1000-8000-00805f9b34fb"

# Keyboard (report id 1) followed by a relative mouse (report id 2). Both
# collections ride one bond; the host creates two input devices from it.
REPORT_DESC = (
    # --- keyboard -------------------------------------------------------
    "05010906a101"      # Usage Page (Generic Desktop), Usage (Keyboard), Collection
    "8501"              #   Report ID (1)
    "050719e029e7"      #   Usage Page (Keyboard), Usage Min/Max (modifier keys)
    "15002501"          #   Logical Minimum (0), Logical Maximum (1)
    "75019508"          #   Report Size (1), Report Count (8)
    "8102"              #   Input (Data,Var,Abs)        -> modifier byte
    "95017508"          #   Report Count (1), Report Size (8)
    "8101"              #   Input (Const)               -> reserved byte
    "95057501"          #   Report Count (5), Report Size (1)
    "050819012905"      #   Usage Page (LEDs), Usage Min/Max
    "9102"              #   Output (Data,Var,Abs)       -> lock lamps
    "95017503"          #   Report Count (1), Report Size (3)
    "9101"              #   Output (Const)              -> lamp padding
    "95067508"          #   Report Count (6), Report Size (8)
    "15002565"          #   Logical Minimum (0), Logical Maximum (101)
    "050719002965"      #   Usage Page (Keyboard), Usage Min/Max
    "8100"              #   Input (Data,Array)          -> six key slots
    "c0"                # End Collection
    # --- mouse ----------------------------------------------------------
    "05010902a101"      # Usage Page (Generic Desktop), Usage (Mouse), Collection
    "8502"              #   Report ID (2)
    "0901a100"          #   Usage (Pointer), Collection (Physical)
    "050919012903"      #     Usage Page (Button), Usage Min/Max (1..3)
    "15002501"          #     Logical Minimum (0), Logical Maximum (1)
    "95037501"          #     Report Count (3), Report Size (1)
    "8102"              #     Input (Data,Var,Abs)      -> button bits
    "95017505"          #     Report Count (1), Report Size (5)
    "8101"              #     Input (Const)             -> padding
    "0501"              #     Usage Page (Generic Desktop)
    "093009310938"      #     Usage (X), Usage (Y), Usage (Wheel)
    "1581257f"          #     Logical Minimum (-127), Logical Maximum (127)
    "75089503"          #     Report Size (8), Report Count (3)
    "8106"              #     Input (Data,Var,Rel)      -> dx, dy, wheel
    "c0c0"              #   End Collection, End Collection
)

# HIDDeviceSubclass 0xc0 = keyboard with a pointing device.
# HIDBootDevice is advertised true because hosts expect it of a keyboard, but
# note the tension: boot protocol has no report ids, so a host that genuinely
# falls back to boot mode will misread these reports. A keyboard-only build
# can claim it without that caveat.
SDP_RECORD = """<?xml version="1.0" encoding="UTF-8" ?>
<record>
  <attribute id="0x0001"><sequence><uuid value="0x1124" /></sequence></attribute>
  <attribute id="0x0004"><sequence>
    <sequence><uuid value="0x0100" /><uint16 value="0x0011" /></sequence>
    <sequence><uuid value="0x0011" /></sequence>
  </sequence></attribute>
  <attribute id="0x0005"><sequence><uuid value="0x1002" /></sequence></attribute>
  <attribute id="0x0006"><sequence>
    <uint16 value="0x656e" /><uint16 value="0x006a" /><uint16 value="0x0100" />
  </sequence></attribute>
  <attribute id="0x0009"><sequence>
    <sequence><uuid value="0x1124" /><uint16 value="0x0100" /></sequence>
  </sequence></attribute>
  <attribute id="0x000d"><sequence><sequence>
    <sequence><uuid value="0x0100" /><uint16 value="0x0013" /></sequence>
    <sequence><uuid value="0x0011" /></sequence>
  </sequence></sequence></attribute>
  <attribute id="0x0100"><text value="%(name)s" /></attribute>
  <attribute id="0x0101"><text value="Demonstration HID bridge" /></attribute>
  <attribute id="0x0102"><text value="%(name)s" /></attribute>
  <attribute id="0x0201"><uint16 value="0x0100" /></attribute>
  <attribute id="0x0202"><uint8 value="0xc0" /></attribute>
  <attribute id="0x0203"><uint8 value="0x00" /></attribute>
  <attribute id="0x0204"><boolean value="true" /></attribute>
  <attribute id="0x0205"><boolean value="true" /></attribute>
  <attribute id="0x0206"><sequence><sequence>
    <uint8 value="0x22" /><text encoding="hex" value="%(desc)s" />
  </sequence></sequence></attribute>
  <attribute id="0x0207"><sequence><sequence>
    <uint16 value="0x0409" /><uint16 value="0x0100" />
  </sequence></sequence></attribute>
  <attribute id="0x020b"><uint16 value="0x0100" /></attribute>
  <attribute id="0x020c"><uint16 value="0x0c80" /></attribute>
  <attribute id="0x020d"><boolean value="false" /></attribute>
  <attribute id="0x020e"><boolean value="true" /></attribute>
</record>""" % {"name": SERVICE_NAME, "desc": REPORT_DESC}

# ------------------------------------------------------------------ tables

MOD = {"ctrl": 0x01, "shift": 0x02, "alt": 0x04, "gui": 0x08,
       "rctrl": 0x10, "rshift": 0x20, "ralt": 0x40, "rgui": 0x80}

NAMED = {"enter": 0x28, "esc": 0x29, "backspace": 0x2a, "tab": 0x2b,
         "space": 0x2c, "caps": 0x39, "right": 0x4f, "left": 0x50,
         "down": 0x51, "up": 0x52, "home": 0x4a, "end": 0x4d,
         "pageup": 0x4b, "pagedown": 0x4e, "delete": 0x4c, "insert": 0x49}
for _i in range(12):
    NAMED["f%d" % (_i + 1)] = 0x3a + _i

ASCII = {}
for _i, _c in enumerate("abcdefghijklmnopqrstuvwxyz"):
    ASCII[_c] = (0x04 + _i, 0)
    ASCII[_c.upper()] = (0x04 + _i, MOD["shift"])
for _i, _c in enumerate("1234567890"):
    ASCII[_c] = (0x1e + _i, 0)
for _c, _u in {" ": 0x2c, "\n": 0x28, "\t": 0x2b, "-": 0x2d, "=": 0x2e,
               "[": 0x2f, "]": 0x30, "\\": 0x31, ";": 0x33, "'": 0x34,
               "`": 0x35, ",": 0x36, ".": 0x37, "/": 0x38}.items():
    ASCII[_c] = (_u, 0)
for _c, _base in {"!": "1", "@": "2", "#": "3", "$": "4", "%": "5", "^": "6",
                  "&": "7", "*": "8", "(": "9", ")": "0", "_": "-", "+": "=",
                  "{": "[", "}": "]", "|": "\\", ":": ";", '"': "'",
                  "~": "`", "<": ",", ">": ".", "?": "/"}.items():
    ASCII[_c] = (ASCII[_base][0], MOD["shift"])

BUTTON = {"left": 0x01, "right": 0x02, "middle": 0x04}


def log(msg):
    sys.stderr.write("%s %s\n" % (time.strftime("%H:%M:%S"), msg))
    sys.stderr.flush()


# ------------------------------------------------------------------- bluez

class Agent(dbus.service.Object):
    """Accepts pairing. The client still confirms in its own dialog."""

    @dbus.service.method("org.bluez.Agent1", in_signature="ouu")
    def RequestConfirmation(self, device, passkey, *_):
        log("pairing request from %s passkey %06d: allowing" % (device, passkey))
        return

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        log("passkey requested by %s" % device)
        return dbus.UInt32(0)

    @dbus.service.method("org.bluez.Agent1", in_signature="os")
    def AuthorizeService(self, device, uuid):
        return

    @dbus.service.method("org.bluez.Agent1")
    def Cancel(self):
        log("pairing cancelled")


class Profile(dbus.service.Object):
    """Present so BlueZ accepts the SDP registration; the sockets are ours."""

    @dbus.service.method("org.bluez.Profile1")
    def Release(self):
        return

    @dbus.service.method("org.bluez.Profile1", in_signature="oha{sv}")
    def NewConnection(self, path, fd, props):
        return


# ------------------------------------------------------------------ device

class HidDevice(object):
    def __init__(self):
        self.ctrl = None
        self.intr = None
        self.lock = threading.Lock()

    def serve(self):
        cs = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET,
                           socket.BTPROTO_L2CAP)
        isock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_SEQPACKET,
                              socket.BTPROTO_L2CAP)
        for s, port in ((cs, P_CTRL), (isock, P_INTR)):
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind((ADAPTER, port))
            s.listen(1)
        log("listening on L2CAP ports %d and %d" % (P_CTRL, P_INTR))
        while True:
            c, cinfo = cs.accept()
            i, iinfo = isock.accept()
            with self.lock:
                self.ctrl, self.intr = c, i
            log("client connected from %s" % (cinfo[0],))

    def _send(self, payload):
        with self.lock:
            if self.intr is None:
                return False
            try:
                self.intr.send(bytes(payload))
                return True
            except OSError as exc:
                log("send failed, dropping client: %s" % exc)
                self.ctrl = self.intr = None
                return False

    def keys(self, mods, usages):
        return self._send([0xa1, 0x01, mods, 0x00]
                          + (list(usages) + [0] * 6)[:6])

    def tap(self, usage, mods=0):
        if not self.keys(mods, [usage]):
            return False
        time.sleep(KEY_DELAY)
        return self.keys(0, [])

    def pointer(self, buttons=0, dx=0, dy=0, wheel=0):
        clamp = lambda v: max(-127, min(127, int(v))) & 0xff
        return self._send([0xa1, 0x02, buttons & 0x07,
                           clamp(dx), clamp(dy), clamp(wheel)])

    def click(self, button):
        if not self.pointer(buttons=button):
            return False
        time.sleep(KEY_DELAY)
        return self.pointer(buttons=0)


def type_text(dev, text):
    sent = 0
    for ch in text:
        hit = ASCII.get(ch)
        if hit is None:
            log("skipping character with no usage: %r" % ch)
            continue
        if not dev.tap(hit[0], hit[1]):
            break
        sent += 1
        time.sleep(KEY_DELAY)
    return sent


# ----------------------------------------------------------------- control

def handle(dev, raw):
    parts = raw.strip().split()
    if not parts:
        return
    verb = parts[0].lower()

    if verb == "status":
        log("connected=%s" % (dev.intr is not None))
    elif verb == "type":
        log("typed %d character(s)" % type_text(dev, raw.split(" ", 1)[1]))
    elif verb == "key" and len(parts) > 1:
        usage = NAMED.get(parts[1].lower())
        log("key %s -> %s" % (parts[1], dev.tap(usage) if usage else "unknown"))
    elif verb == "usage" and len(parts) > 1:
        mods = 0
        for name in parts[2:]:
            mods |= MOD.get(name.lower(), 0)
        log("usage %s -> %s" % (parts[1], dev.tap(int(parts[1], 16), mods)))
    elif verb == "move" and len(parts) > 2:
        log("move -> %s" % dev.pointer(dx=int(parts[1]), dy=int(parts[2])))
    elif verb == "click" and len(parts) > 1:
        log("click -> %s" % dev.click(BUTTON.get(parts[1].lower(), 0x01)))
    elif verb == "scroll" and len(parts) > 1:
        log("scroll -> %s" % dev.pointer(wheel=int(parts[1])))
    else:
        log("unknown command: %r" % raw)


def control_loop(dev):
    directory = os.path.dirname(FIFO)
    if directory and not os.path.isdir(directory):
        os.makedirs(directory, 0o700)
    if not os.path.exists(FIFO):
        os.mkfifo(FIFO, 0o600)
    log("control fifo ready at %s" % FIFO)
    while True:
        with open(FIFO, "r") as fh:
            for line in fh:
                if line.strip():
                    handle(dev, line.rstrip("\n"))


# -------------------------------------------------------------------- main

def main():
    if os.geteuid() != 0:
        log("needs root: L2CAP ports below 4096 are privileged")
        return 1

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    Agent(bus, AGENT_PATH)
    manager = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"),
                             "org.bluez.AgentManager1")
    manager.RegisterAgent(AGENT_PATH, "DisplayYesNo")
    manager.RequestDefaultAgent(AGENT_PATH)

    Profile(bus, PROFILE_PATH)
    profiles = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"),
                              "org.bluez.ProfileManager1")
    profiles.RegisterProfile(PROFILE_PATH, HID_UUID, {
        "ServiceRecord": SDP_RECORD,
        "Role": "server",
        "RequireAuthentication": dbus.Boolean(True),
        "RequireAuthorization": dbus.Boolean(False),
    })
    log("HID profile registered as %r" % SERVICE_NAME)

    dev = HidDevice()
    threading.Thread(target=dev.serve, daemon=True).start()
    threading.Thread(target=control_loop, args=(dev,), daemon=True).start()
    GLib.MainLoop().run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
