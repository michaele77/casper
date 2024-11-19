from io import BytesIO
from PIL import Image
# from multiprocessing import Process, Queue
import threading
import queue
import time
import atexit
import os

RECEIVED_IMAGES_REL_PATH_PREFIX = 'data/received_images/'

# FIFO queue that stores incoming PNG data in its pure data form.
# We will store the data in the queue temporarily to avoid I/O bottlenecking from writing to disk.
# Producer is the @socketio.on('upload_image') route.
# Consumer is a thread worker that will save the images to 
IMAGE_DATA_QUEUE = queue.Queue()

# Event to signal the worker thread to stop. Only used for cleanup.
stop_event = threading.Event()

def cleanup():
    print(" >> [Image data manager] Shutting down...")
    stop_event.set()  # Signal the worker thread to stop
    worker_thread.join()  # Wait for the worker thread to finish
    print(" >> [Image data manager] Worker thread stopped.")

def add_image_data(uuid, image_data):
    # Using UNIX microseconds.
    IMAGE_DATA_QUEUE.put((uuid, image_data, int(time.time_ns() / 1_000)))

def save_images_worker():
    while not stop_event.is_set():  # Check for the stop signal
        try:
            # Wait for an item in the queue, with a timeout to check for stop_event
            uuid, image_data, time_added = IMAGE_DATA_QUEUE.get(timeout=1)

            # Convert the raw bytes data to a PNG image
            png_image = Image.open(BytesIO(image_data))

            # Data will be saved under a directory corresponding to their UUID and named according to the time the image data was added to the queue.
            directory_path = RECEIVED_IMAGES_REL_PATH_PREFIX + uuid
            file_path = directory_path + '/' + str(time_added) + '.png'
            print(" >> [Image data manager] Saving image to path: {0}".format(file_path))
            # Create the directory if it doesn't exist
            os.makedirs(directory_path, exist_ok=True)
            png_image.save(file_path)

            # the Queue class needs to be marked as done for the next item to be retrieved.
            IMAGE_DATA_QUEUE.task_done() 
        except queue.Empty:
            print(' >> [Image data manager] Queue is empty!')
            time.sleep(3)

def save_image_worker(queue):
    while True:
        image_data, filename = queue.get()
        if image_data is None:  # Sentinel to stop the process
            break
        file_path = f"images/{filename}"
        with open(file_path, "wb") as f:
            f.write(image_data)


# Register the cleanup function
atexit.register(cleanup)

print(' >> [Image data manager] Starting thread...')
worker_thread = threading.Thread(target=save_images_worker, daemon=True)
worker_thread.start()
