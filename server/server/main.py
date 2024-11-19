from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit, join_room, leave_room
from io import BytesIO
from PIL import Image
from multiprocessing import Process, Queue
import image_data_manager

app = Flask(__name__)
# socketio = SocketIO(app)
socketio = SocketIO(app, cors_allowed_origins="*", max_http_buffer_size=100 * 1024 * 1024)  # Allow all origins (for testing only)

# A set of all active, connected sessions.
# When a client disconnects for any reason (user moves away from app and iOS closes the socket), the session will be removed from the set.
CLIENT_SESSIONS = set()

# A dictionary mapping session ID --> device UUID.
# When a client disconnects for any reason (user moves away from app and iOS closes the socket), the session will be removed from the set.
SESSION_TO_UUID_MAP = {}

# A set of all UUIDs seen.
# This set will persist throughout the server's lifetime; UUIDs are not removed from here when a session is disconnected.
PERSISTED_UUIDS = set()

@socketio.on('/')
def index():
    return 'Hello, WebSocket!'

@socketio.on('connect', namespace='/')
def handle_connect():
    # When a client connects, we assign them a unique room based on their session ID
    client_id = request.sid  # Unique identifier for the client session

    # CDDBE9D8-0325-44D9-BC46-99C25D8BE956 if michael
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
def handle_register_device(uuid):
    print('Got UUID: ' + uuid)
    if request.sid not in SESSION_TO_UUID_MAP.keys():
        SESSION_TO_UUID_MAP[request.sid] = uuid
        print('So far, have the session to UUID map: {0}'.format(SESSION_TO_UUID_MAP))
    PERSISTED_UUIDS.add(uuid)

@socketio.on('message')
def handle_message(message):
    print('Got message: ' + message)

@socketio.on('upload_image')
def handle_image(data):
    print('>>> UPLOAD IMAGE HERE!!!')
    try: 
        image_data_manager.add_image_data(SESSION_TO_UUID_MAP[request.sid], data)
        # Send acknowledgment to the client
        emit('image_received_ack', {'status': 'ok'}, to=request.sid)
        
    except Exception as e:
        print(f"Error processing image: {e}")
        emit('image_received_ack', {'status': 'error', 'message': str(e)}, to=request.sid)

@socketio.on('request_all_uuids')
def handle_reqest_all_uuids():
    print('>> Retreiving all device UUIDs that have connected.')
    print('>> Full list is: {0}'.format(PERSISTED_UUIDS))
    # Convert set to list before emitting.
    # Emitting a set of strings of UUIDs.
    emit('all_uuids', list(PERSISTED_UUIDS))

if __name__ == "__main__":
    print('Starting program...')
    socketio.run(app, host="0.0.0.0", port=12345, debug=True, use_reloader=False) 

