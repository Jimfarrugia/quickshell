import importlib.util
import os
import socket
import tempfile
import unittest


spec = importlib.util.spec_from_file_location("hyprshot_notification", "scripts/qe-hyprshot-notification.py")
sender = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sender)


class HyprshotNotificationTests(unittest.TestCase):
    def test_stale_socket_does_not_block_next_screenshot_sender(self):
        with tempfile.TemporaryDirectory() as directory:
            path = os.path.join(directory, "notification.sock")
            abandoned = socket.socket(socket.AF_UNIX)
            abandoned.bind(path)
            abandoned.close()

            endpoint = sender.create_server(path)
            self.assertIsNotNone(endpoint, "a dead sender must not suppress new screenshot notifications")
            try:
                with socket.socket(socket.AF_UNIX) as client:
                    client.connect(path)
            finally:
                if endpoint is not None:
                    server, lock = endpoint
                    server.close()
                    lock.close()

    def test_live_sender_socket_is_not_replaced(self):
        with tempfile.TemporaryDirectory() as directory:
            path = os.path.join(directory, "notification.sock")
            with socket.socket(socket.AF_UNIX) as live:
                live.bind(path)
                live.listen(1)
                self.assertIsNone(sender.create_server(path))
                with socket.socket(socket.AF_UNIX) as client:
                    client.connect(path)

    def test_sender_lock_prevents_replacing_a_live_owner_with_a_refused_socket(self):
        with tempfile.TemporaryDirectory() as directory:
            path = os.path.join(directory, "notification.sock")
            server, lock = sender.create_server(path)
            try:
                server.close()  # Simulate a listener refusing connections while its owner is still alive.
                self.assertIsNone(sender.create_server(path))
                self.assertTrue(os.path.exists(path))
            finally:
                lock.close()


if __name__ == "__main__":
    unittest.main()
