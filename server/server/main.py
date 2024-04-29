from flask import Flask, request, jsonify
import base64

app = Flask(__name__)

# Configurations.
RECEIVED_IMAGES_REL_PATH_PREFIX = '/data/received_images/'

@app.route('/upload-image', methods=['POST'])
def upload_image():
    print('<<>> Got a hit!')

    request_data = request.get_json()
    print('<<>> What are the request keys: {0}'.format(request_data.keys()))
    if 'name' not in request_data.keys() or 'image_data' not in request_data.keys():
        print('<<>> Not a real request')
        return jsonify({'message': 'SUCCESS! Nothing happened, yet...'}), 200

    image_name = request_data['name']
    image_data = request_data['image_data']

    # Decode the base64 string
    image_bytes = base64.b64decode(image_data)

    # Write the decoded bytes back to a new image file
    with open(RECEIVED_IMAGES_REL_PATH_PREFIX + 'most_recent_image.jpg', 'wb') as image_file:
        image_file.write(image_bytes)


    return jsonify({'message': 'SUCCESS! Wrote to directory!'}), 200

if __name__ == "__main__":
    print('Starting program...')
    app.run(debug=True)
