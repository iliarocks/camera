import io
import sys
import time
import threading
from picamera2 import Picamera2

stop_requested = threading.Event()
capture_requested = threading.Event()

def listen_for_commands():
    for command in sys.stdin:
        if command.strip() == "stop":
            break
        elif command.strip() == "capture":
            capture_requested.set()
    stop_requested.set()

threading.Thread(target=listen_for_commands, daemon=True).start()

camera = Picamera2()

def write_packet(type, payload):
    sys.stdout.buffer.write(len(payload).to_bytes(4, "little"))
    sys.stdout.buffer.write(type)
    sys.stdout.buffer.write(payload)
    sys.stdout.buffer.flush()


try:
    capture_configuration = camera.create_still_configuration()
    preview_configuration = camera.create_preview_configuration(
        main={"size": (600, 400)}
    )
    camera.configure(preview_configuration)
    camera.start()
    stop_requested.wait(1)

    while not stop_requested.is_set():
        if capture_requested.is_set():
            capture_requested.clear()
            camera.switch_mode_and_capture_file(capture_configuration, f"capture—{time.time_ns()}.jpg")
            write_packet(bytes([1]), bytes([]))
        buffer = io.BytesIO()
        camera.capture_file(buffer, format="jpeg")
        data = buffer.getvalue()
        write_packet(bytes([0]), data)

finally:
    camera.close()
