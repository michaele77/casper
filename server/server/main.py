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

# A set of all active, connected sessions
CLIENT_SESSIONS = set()

# A dictionary mapping session ID --> device UUID
SESSION_TO_UUID_MAP = {}

@socketio.on('/')
def index():
    return 'Hello, WebSocket!'

@socketio.on('connect', namespace='/')
def handle_connect():
    # When a client connects, we assign them a unique room based on their session ID
    client_id = request.sid  # Unique identifier for the client session

    # CDDBE9D8-0325-44D9-BC46-99C25D8BE956 if michael
    print('whole request: {0}'.format(request))
    print('just handshake request: {0}'.format(request.authorization))
    uuid = request.args.get('UUID')  # Get the device UUID from the query params
    print(f"Client connected with UUID: {uuid}")

    print('<<CONNECT>> for client ID: {0}'.format(client_id))
    CLIENT_SESSIONS.add(client_id)  # Register the client
    join_room(client_id)  # Join a room unique to this client
    print(f"Client connected: {client_id}")

    emit('connected', {'status': 'ok'})

@socketio.on('disconnect')
def handle_disconnect():
    client_id = request.sid
    CLIENT_SESSIONS.remove(client_id)
    del SESSION_TO_UUID_MAP[client_id]
    leave_room(client_id)
    print(f"Client disconnected: {client_id}")

@socketio.on('register_device')
def register_device(uuid):
    print('Got UUID: ' + uuid)
    if request.sid not in SESSION_TO_UUID_MAP.keys():
        SESSION_TO_UUID_MAP[request.sid] = uuid
        print('So far, have the session to UUID map: {0}'.format(SESSION_TO_UUID_MAP))

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

        # Send acknowledgment to the client
        emit('image_received_ack', {'status': 'ok'}, to=request.sid)
        
    except Exception as e:
        print(f"Error processing image: {e}")
        emit('image_received_ack', {'status': 'error', 'message': str(e)}, to=request.sid)


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
    


    print('About to launch!')
    socketio.run(app, host="0.0.0.0", port=12345, debug=True, use_reloader=False) 
    # context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    # context.load_cert_chain(certfile='ssl/cert.pem', keyfile='ssl/private.key')
    # socketio.run(app, host="0.0.0.0", port=12345, debug=True, use_reloader=False, ssl_context=context)


    # socketio.run(app, host="0.0.0.0", port=17463, debug=True, use_reloader=False)

    # socketio.run(app, host="0.0.0.0", port=17463, debug=True, use_reloader=False, ssl_context=context)
    # app.run(host="0.0.0.0", port=12345, debug=True)
    # app.run(debug=True)
