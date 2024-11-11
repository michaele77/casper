from flask import Flask, request, jsonify
import base64

app = Flask(__name__)

# Configurations.
RECEIVED_IMAGES_REL_PATH_PREFIX = 'data/received_images/'

@app.route('/upload-image', methods=['POST'])
def upload_image():
    print('<<>> Got a hit!')

    file = request.files['uploaded_image']

    if file.filename == '':
        return "No selected file", 400

    print(file)
    file.save(RECEIVED_IMAGES_REL_PATH_PREFIX + 'most_recent_image.png')

    return jsonify({'message': 'SUCCESS! Wrote to directory!'}), 200

if __name__ == "__main__":
    print('Starting program...')
    app.run(host="0.0.0.0", port=17463, debug=True)
    # app.run(debug=True)
