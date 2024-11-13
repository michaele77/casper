
# from flask import Flask
# from flask_socketio import SocketIO

# app = Flask(__name__)
# socketio = SocketIO(app, cors_allowed_origins="*")  # Allow all origins for development

# @app.route('/')
# def index():
#     return 'Hello, WebSocket!'

# @socketio.on('connect')
# def handle_connect():
#     print("Client connected.")

# @socketio.on('message')
# def handle_message(message):
#     print("Received message:", message)
#     socketio.emit('response', {'data': 'Hello from server!'})

# if __name__ == '__main__':
#     socketio.run(app, host='0.0.0.0', port=17463, debug=True)  # Ensure correct port

from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit, join_room, leave_room
from io import BytesIO
from PIL import Image
import ssl

app = Flask(__name__)
# socketio = SocketIO(app)
socketio = SocketIO(app, cors_allowed_origins="*", max_http_buffer_size=100 * 1024 * 1024)  # Allow all origins (for testing only)

# Configurations.
RECEIVED_IMAGES_REL_PATH_PREFIX = 'data/received_images/'

# A dictionary to track which client is associated with each session
CLIENT_SESSIONS = {}

@socketio.on('/')
def index():
    return 'Hello, WebSocket!'

@socketio.on('connect')
def handle_connect():
    # When a client connects, we assign them a unique room based on their session ID
    client_id = request.sid  # Unique identifier for the client session
    print('<<CONNECT>> for client ID: {0}'.format(client_id))
    CLIENT_SESSIONS[client_id] = client_id  # Register the client
    join_room(client_id)  # Join a room unique to this client
    print(f"Client connected: {client_id}")

@socketio.on('disconnect')
def handle_disconnect():
    client_id = request.sid
    CLIENT_SESSIONS.pop(client_id, None)
    leave_room(client_id)
    print(f"Client disconnected: {client_id}")

@socketio.on('message')
def print_message(message):
    print('Got messgae: ' + message)

@socketio.on('upload_image')
def handle_image(data):
    print('>>> UPLOAD IMAGE HERE!!!')
    try:
        print('IN THE UPLOAD_IMAGE socket!')
        # `data` is the raw binary image sent by the client
        image_data = data  # In this case, `data` is a byte string (image)
        
        # Convert the byte data into an image
        image = Image.open(BytesIO(image_data))
        
        # Save the image temporarily (you can remove this step if not necessary)
        image.save(RECEIVED_IMAGES_REL_PATH_PREFIX + 'most_recent_image.png')

        # Emit the image back to the client
        emit('image_echoed', image_data)
        
    except Exception as e:
        print(f"Error processing image: {e}")
        emit('error', {'message': 'Failed to process image'})


@app.route('/upload-image', methods=['POST'])
def upload_image():
    print('<<>> Got a hit!')

    file = request.files['uploaded_image']

    if file.filename == '':
        return "No selected file", 400
    
    # client_id = request.form['client_id']
    # print('GIVEN client ID is: {0}'.format(client_id))

    print(file)
    file.save(RECEIVED_IMAGES_REL_PATH_PREFIX + 'most_recent_image.png')

    # Now, we echo the image back to the connected client 
    # socketio.emit('image_data', {'filename': file.filename, 'data': file}, room=client_id)

    return 'SUCCESS! Wrote to directory!', 200

if __name__ == "__main__":
    print('Starting program...')

    # # Set up SSL certificates (use your own valid certificates)
    # context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    # context.load_cert_chain(certfile='ssl/cert.pem', keyfile='ssl/private.key')

    socketio.run(app, host="0.0.0.0", port=17463, debug=True, use_reloader=False)
    # app.run(host="0.0.0.0", port=17463, debug=True, ssl_context=context)
    # app.run(debug=True)
