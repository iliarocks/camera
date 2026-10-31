import io
import sys
import time
from picamera2 import Picamera2

camera = Picamera2()

try:
    configuration = camera.create_preview_configuration(
        main={"size": (600, 400)}
    )
    camera.configure(configuration)
    camera.start()
    time.sleep(1)

    # Capture one JPEG into an in-memory buffer.
    # Send the buffer's bytes to standard output.
    buffer = io.BytesIO()
    camera.capture_file(buffer, format="jpeg")
    data = buffer.getvalue()
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()

finally:
    camera.close()
