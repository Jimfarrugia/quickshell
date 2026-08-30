#!/usr/bin/env python3
"""Keep screenshot notification actions available for the history lifetime."""

import os
from pathlib import Path
import subprocess
import sys

import dbus
import dbus.mainloop.glib
from gi.repository import GLib


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} SCREENSHOT_PATH SCREENSHOT_DIR", file=sys.stderr)
        return 2

    screenshot_path = os.path.realpath(sys.argv[1])
    screenshot_dir = os.path.realpath(sys.argv[2])
    if not os.path.isfile(screenshot_path) or not os.path.isdir(screenshot_dir):
        print("Screenshot path or directory is unavailable", file=sys.stderr)
        return 1
    screenshot_uri = Path(screenshot_path).as_uri()

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    notifications = dbus.Interface(
        bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications"),
        "org.freedesktop.Notifications",
    )
    loop = GLib.MainLoop()
    notification_id = int(
        notifications.Notify(
            "Hyprshot",
            dbus.UInt32(0),
            screenshot_path,
            "Screenshot saved",
            os.path.basename(screenshot_path),
            dbus.Array(["open", "View Image", "folder", "Open Folder"], signature="s"),
            dbus.Dictionary(
                {
                    "resident": dbus.Boolean(True),
                    "image-path": dbus.String(screenshot_uri),
                },
                signature="sv",
            ),
            dbus.Int32(0),
        )
    )

    def on_action(invoked_id: int, action: str) -> None:
        if int(invoked_id) != notification_id:
            return
        if action == "open":
            command = ["xdg-open", screenshot_path]
        elif action == "folder":
            command = ["thunar", screenshot_path]
        else:
            return
        try:
            subprocess.Popen(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        except OSError as error:
            print(f"Could not run {command[0]}: {error}", file=sys.stderr)

    def on_closed(closed_id: int, _reason: int) -> None:
        if int(closed_id) == notification_id:
            loop.quit()

    bus.add_signal_receiver(
        on_action,
        dbus_interface="org.freedesktop.Notifications",
        signal_name="ActionInvoked",
    )
    bus.add_signal_receiver(
        on_closed,
        dbus_interface="org.freedesktop.Notifications",
        signal_name="NotificationClosed",
    )
    loop.run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
