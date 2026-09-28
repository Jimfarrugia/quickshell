#!/usr/bin/env python3
"""Keep screenshot notification actions available for the history lifetime."""

import errno
import fcntl
import hashlib
import json
import os
import socket
import stat
import subprocess
import sys
from pathlib import Path
from typing import Any, TextIO

import dbus
import dbus.mainloop.glib
from gi.repository import GLib


SOCKET_NAME = "qe-hyprshot-notification.sock"


def socket_path() -> str:
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
    bus_address = os.environ.get("DBUS_SESSION_BUS_ADDRESS", "")
    session_id = hashlib.sha256(bus_address.encode()).hexdigest()[:16]
    if runtime_dir:
        return os.path.join(runtime_dir, f"{SOCKET_NAME}-{session_id}")
    return os.path.join("/tmp", f"{SOCKET_NAME}-{os.getuid()}-{session_id}")


def valid_request(screenshot: str, screenshot_dir: str) -> bool:
    return os.path.isfile(screenshot) and os.path.isdir(screenshot_dir)


def send_to_existing_daemon(path: str, request: dict[str, str]) -> bool:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
            client.settimeout(0.25)
            client.connect(path)
            client.sendall((json.dumps(request) + "\n").encode())
        return True
    except OSError:
        return False


def create_server(path: str) -> tuple[socket.socket, TextIO] | None:
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    lock = None
    try:
        # Keep the lock for the server's lifetime: a refused connection alone
        # does not prove that a busy listener has died.
        lock_fd = os.open(path + ".lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
        lock = os.fdopen(lock_fd, "r+")
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        try:
            server.bind(path)
        except OSError as error:
            if error.errno != errno.EADDRINUSE:
                raise
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as probe:
                probe.settimeout(0.25)
                try:
                    probe.connect(path)
                except ConnectionRefusedError:
                    endpoint = os.lstat(path)
                    if not stat.S_ISSOCK(endpoint.st_mode) or endpoint.st_uid != os.getuid():
                        raise error
                    os.unlink(path)
                    server.bind(path)
                else:
                    raise error
        server.listen(8)
        server.setblocking(False)
        return server, lock
    except OSError:
        server.close()
        if lock is not None:
            lock.close()
        return None


def request_from_connection(connection: socket.socket) -> dict[str, str] | None:
    try:
        with connection:
            connection.settimeout(0.25)
            payload = connection.recv(4096)
        request: Any = json.loads(payload.decode())
        if not isinstance(request, dict):
            return None
        screenshot = request.get("screenshot")
        screenshot_dir = request.get("screenshot_dir")
        if not isinstance(screenshot, str) or not isinstance(screenshot_dir, str):
            return None
        return {"screenshot": screenshot, "screenshot_dir": screenshot_dir}
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} SCREENSHOT_PATH SCREENSHOT_DIR", file=sys.stderr)
        return 2

    screenshot_path = os.path.realpath(sys.argv[1])
    screenshot_dir = os.path.realpath(sys.argv[2])
    request = {"screenshot": screenshot_path, "screenshot_dir": screenshot_dir}
    notification_socket = socket_path()
    if send_to_existing_daemon(notification_socket, request):
        return 0
    if not valid_request(screenshot_path, screenshot_dir):
        print("Screenshot path or directory is unavailable", file=sys.stderr)
        return 1

    server_endpoint = create_server(notification_socket)
    if server_endpoint is None:
        # Another invocation may have won the startup race.
        for _ in range(10):
            if send_to_existing_daemon(notification_socket, request):
                return 0
            GLib.usleep(10000)
        print("Could not start or contact screenshot notification daemon", file=sys.stderr)
        return 1
    server_socket, server_lock = server_endpoint
    endpoint_stat = os.stat(notification_socket)
    socket_identity = (endpoint_stat.st_dev, endpoint_stat.st_ino)

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    try:
        bus = dbus.SessionBus()
        notifications = dbus.Interface(
            bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications"),
            "org.freedesktop.Notifications",
        )
        notification_owner = bus.get_name_owner("org.freedesktop.Notifications")
        loop = GLib.MainLoop()
        notification_paths: dict[int, str] = {}

        def publish(request_data: dict[str, str]) -> None:
            screenshot = os.path.realpath(request_data["screenshot"])
            directory = os.path.realpath(request_data["screenshot_dir"])
            if not valid_request(screenshot, directory):
                return
            notification_id = int(
                notifications.Notify(
                    "Hyprshot",
                    dbus.UInt32(0),
                    screenshot,
                    "Screenshot saved",
                    os.path.basename(screenshot),
                    dbus.Array(["open", "View Image", "folder", "Open Folder"], signature="s"),
                    dbus.Dictionary(
                        {
                            "resident": dbus.Boolean(True),
                            "image-path": dbus.String(Path(screenshot).as_uri()),
                        },
                        signature="sv",
                    ),
                    dbus.Int32(0),
                )
            )
            notification_paths[notification_id] = screenshot

        def on_owner_changed(_name: str, _old_owner: str, new_owner: str) -> None:
            if new_owner != notification_owner:
                loop.quit()

        def on_action(invoked_id: int, action: str) -> None:
            screenshot = notification_paths.get(int(invoked_id))
            if screenshot is None:
                return
            command = ["xdg-open", screenshot] if action == "open" else ["thunar", screenshot] if action == "folder" else None
            if command is None:
                return
            try:
                subprocess.Popen(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            except OSError as error:
                print(f"Could not run {command[0]}: {error}", file=sys.stderr)

        def on_closed(closed_id: int, _reason: int) -> None:
            notification_paths.pop(int(closed_id), None)

        def on_socket_ready(_source: Any, _condition: Any) -> bool:
            try:
                connection, _address = server_socket.accept()
                request_data = request_from_connection(connection)
                if request_data is not None:
                    publish(request_data)
            except OSError:
                pass
            return True

        bus.add_signal_receiver(on_owner_changed, dbus_interface="org.freedesktop.DBus",
                                signal_name="NameOwnerChanged", arg0="org.freedesktop.Notifications",
                                path="/org/freedesktop/DBus")
        bus.add_signal_receiver(on_action, dbus_interface="org.freedesktop.Notifications",
                                signal_name="ActionInvoked")
        bus.add_signal_receiver(on_closed, dbus_interface="org.freedesktop.Notifications",
                                signal_name="NotificationClosed")
        GLib.io_add_watch(server_socket.fileno(), GLib.IO_IN, on_socket_ready)
        publish(request)
        loop.run()
    except dbus.DBusException as error:
        print(f"Notification service unavailable: {error}", file=sys.stderr)
        return 1
    finally:
        server_socket.close()
        try:
            endpoint_stat = os.stat(notification_socket)
            if (endpoint_stat.st_dev, endpoint_stat.st_ino) == socket_identity:
                os.unlink(notification_socket)
        except FileNotFoundError:
            pass
        finally:
            server_lock.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
