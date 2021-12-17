import face_recognition
from urllib.request import urlopen
import numpy as np
from PIL import Image
from boto3.dynamodb.types import TypeSerializer
import base64


def lambda_handler(event, _):
    img = Image.open(urlopen(event["url"]))
    img = img.convert("RGB")
    img.thumbnail((500, 500))
    encodings = [
        base64.b64encode(encoding.tostring())
        for encoding in face_recognition.face_encodings(np.array(img))
    ]
    serializer = TypeSerializer()
    return {
        "id": serializer.serialize(event["id"]),
        "url": serializer.serialize(event["url"]),
        "encodings": serializer.serialize(encodings),
    }
