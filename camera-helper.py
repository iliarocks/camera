import io
import sys
import time
import threading
from picamera2 import Picamera2

stop_requested = threading.Event()

def listen_for_stop():
    for command in sys.stdin:
        if command.strip() == "stop":
            break
    stop_requested.set()

threading.Thread(target=listen_for_stop, daemon=True).start()

camera = Picamera2()

try:
    configuration = camera.create_preview_configuration(
        main={"size": (600, 400)}
    )
    camera.configure(configuration)
    camera.start()
    stop_requested.wait(1)

    while not stop_requested.is_set():
        buffer = io.BytesIO()
        camera.capture_file(buffer, format="jpeg")
        data = buffer.getvalue()
        sys.stdout.buffer.write(len(data).to_bytes(4, "little"))
        sys.stdout.buffer.write(data)
        sys.stdout.buffer.flush()

finally:
    camera.close()
