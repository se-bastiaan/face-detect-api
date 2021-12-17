import face_recognition
import json
from urllib.request import urlopen
import numpy as np
from PIL import Image
import logging

logging.basicConfig(level=logging.DEBUG)

class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return json.JSONEncoder.default(self, obj)

def lambda_handler(event, _):
    img = Image.open(urlopen(event["url"]))
    img = img.convert("RGB")
    img.thumbnail((500, 500))
    encodings = face_recognition.face_encodings(np.array(img))
    return {"id": event["id"], "url": event["url"], "encodings": np.array(encodings).tolist()}
