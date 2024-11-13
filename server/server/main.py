from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit, join_room, leave_room

app = Flask(__name__)
socketio = SocketIO(app)

# Configurations.
RECEIVED_IMAGES_REL_PATH_PREFIX = 'data/received_images/'

# A dictionary to track which client is associated with each session
CLIENT_SESSIONS = {}

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

@app.route('/upload-image', methods=['POST'])
def upload_image():
    print('<<>> Got a hit!')

    file = request.files['uploaded_image']
    client_id = request.form['client_id']

    if file.filename == '':
        return "No selected file", 400
    
    print('GIVEN client ID is: {0}'.format(client_id))

    print(file)
    file.save(RECEIVED_IMAGES_REL_PATH_PREFIX + 'most_recent_image.png')

    # Now, we echo the image back to the connected client 
    socketio.emit('image_data', {'filename': file.filename, 'data': file}, room=client_id)

    return 'SUCCESS! Wrote to directory!', 200

if __name__ == "__main__":
    print('Starting program...')
    app.run(host="0.0.0.0", port=17463, debug=True)
    # app.run(debug=True)
