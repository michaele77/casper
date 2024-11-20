from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit, join_room, leave_room
from io import BytesIO
from PIL import Image
from multiprocessing import Process, Queue
import image_data_manager
from collections import defaultdict
import time

app = Flask(__name__)
# socketio = SocketIO(app)
socketio = SocketIO(app, cors_allowed_origins="*", max_http_buffer_size=100 * 1024 * 1024)  # Allow all origins (for testing only)

# TODO: Let's organize all this data into a user-data manager class...likely, we'll just hide all details under there.
#       All entry-points to the data use a session ID, so that gives us a clue

# A set of all active, connected sessions.
# When a client disconnects for any reason (user moves away from app and iOS closes the socket), the session will be removed from the set.
CLIENT_SESSIONS = set()

# A dictionary mapping session ID --> device UUID.
# When a client disconnects for any reason (user moves away from app and iOS closes the socket), the session will be removed from the set.
SESSION_TO_UUID_MAP = {}

# A set of all UUIDs seen.
# This set will persist throughout the server's lifetime; UUIDs are not removed from here when a session is disconnected.
PERSISTED_UUIDS = set()

# A dictionary mapping UUID --> alias
# An alias is a human-readable identifier (like a name!) that others would recognize a user by
# Persisted through the server's lifetime; entries are not removed when a session is diconnected (uses last registered alias).
UUID_TO_ALIAS_MAP = {}

# A dictionary mapping UUID --> a dictionary of active sessions
# The dictionary of active sessions is just a sharee ID --> session expiration time in UNIX micros
# This map is persisted through the server's lifetime
# TODO: Once I figure out how to actually get the phone to detect when a session is over, start removing sessions
#       Or, perhaps this server will do the detection, and will notify the client when it is removed...
#       Or, the server will figure it out lazily; once the phone sends an image OUTSIDE of the session time, it will tell the phone to stop
UUID_TO_ACTIVE_SESSIONS = defaultdict(dict)

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
def handle_all_uuids():
    print('>> Retreiving all device UUIDs that have connected.')
    print('>> Full list is: {0}'.format(PERSISTED_UUIDS))
    # Convert set to list before emitting.
    # Emitting a set of strings of UUIDs.
    # If an alias exists, replace the device ID with it!
    all_uuids_or_aliases = [UUID_TO_ALIAS_MAP[uuid] if uuid in UUID_TO_ALIAS_MAP.keys() else uuid for uuid in PERSISTED_UUIDS]
    emit('response_all_uuids', all_uuids_or_aliases)

@socketio.on('update_alias')
def handle_update_alias(new_alias):
    uuid = SESSION_TO_UUID_MAP[request.sid]
    print('>> updating alias for UUID {0} to {1}'.format(uuid, new_alias))
    UUID_TO_ALIAS_MAP[uuid] = new_alias
    emit('update_alias_ack', {'status': 'ok'}, to=request.sid)

@socketio.on('request_active_sessions')
def handle_active_sessions():
    uuid = SESSION_TO_UUID_MAP[request.sid]

    # This is a dictionary by default; need to flatten it
    active_sessions = UUID_TO_ACTIVE_SESSIONS[uuid]
    active_sessions_as_list = [[sharee_id,expiration_time_micros] for (sharee_id, expiration_time_micros) in active_sessions.items()]
    print('>> active sessions for UUID {0}: {1}'.format(uuid, active_sessions_as_list))
    emit('response_active_sessions', active_sessions_as_list)

@socketio.on('create_session')
def handle_create_session(sharee, duration_hours):
    # The sharee can be EITHER an alias or a UUID
    # The duration is given in hours
   
    uuid = SESSION_TO_UUID_MAP[request.sid]

    sharee_uuid = sharee
    for (id, alias) in UUID_TO_ALIAS_MAP.items():
        if alias == sharee:
            sharee_uuid = id
            break
    
    # Get endtime from now() in UNIX micros
    session_end_time_micros = time.time_ns() * 1_000 + duration_hours * 3_600_000_000
    
    # Overwrite any existing session with this user.
    UUID_TO_ACTIVE_SESSIONS[uuid][sharee_uuid] = session_end_time_micros
    print('>> active sessions so far: {0}'.format(UUID_TO_ACTIVE_SESSIONS))
    emit('create_session_ack', {'status': 'ok'}, to=request.sid)

if __name__ == "__main__":
    print('Starting program...')
    socketio.run(app, host="0.0.0.0", port=12345, debug=True, use_reloader=False) 

